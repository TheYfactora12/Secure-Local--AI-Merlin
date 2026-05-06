"""Native Merlin task router.

The current routes.yaml defines route classes rather than explicit keyword
rules. This module keeps that config intact and adds a small compatibility
layer that maps known task phrases to Merlin's six staff modes.
"""

from __future__ import annotations

import hashlib
import io
import logging
from contextlib import redirect_stdout
from datetime import UTC, datetime
from typing import Literal

from pydantic import BaseModel, Field

from merlin.config_loader import MerlinConfig, RouteSpec, load_all_configs


logger = logging.getLogger(__name__)

AgentTarget = Literal["openhands", "n8n", "litellm", "merlin-core"]


class RouteDecision(BaseModel):
    route_id: str
    task_type: str
    staff_mode: str
    agent_target: AgentTarget
    model_hint: str
    requires_approval: bool
    confidence: float = Field(ge=0.0, le=1.0)
    matched_keywords: list[str]
    selected_agent: str
    required_profile: str
    selected_model_alias: str
    approval_gates: list[str]
    decision_reason: str


class _RouteRule(BaseModel):
    route_id: str
    task_type: str
    keywords: list[str]
    staff_mode: str
    agent_target: AgentTarget


STAFF_ROUTE_RULES: tuple[_RouteRule, ...] = (
    _RouteRule(
        route_id="code",
        task_type="code",
        keywords=["python", "function", "parse", "json", "code", "debug", "refactor", "test"],
        staff_mode="software_engineer",
        agent_target="openhands",
    ),
    _RouteRule(
        route_id="general",
        task_type="architecture",
        keywords=["architecture", "architect", "system", "microservice", "service boundary", "scalable"],
        staff_mode="architect",
        agent_target="merlin-core",
    ),
    _RouteRule(
        route_id="general",
        task_type="security",
        keywords=["security", "vulnerability", "sql injection", "scan", "threat", "secret", "credential"],
        staff_mode="security_reviewer",
        agent_target="litellm",
    ),
    _RouteRule(
        route_id="automation",
        task_type="automation",
        keywords=["n8n", "automation", "workflow", "daily reports", "reports", "schedule", "webhook"],
        staff_mode="operator",
        agent_target="n8n",
    ),
    _RouteRule(
        route_id="general",
        task_type="ai_engineering",
        keywords=["train", "fine-tuned", "fine tune", "model", "dataset", "embedding", "rag"],
        staff_mode="ai_engineer",
        agent_target="litellm",
    ),
    _RouteRule(
        route_id="general",
        task_type="product_design",
        keywords=["user onboarding", "onboarding", "user flow", "ux", "dashboard", "screen", "design"],
        staff_mode="product_designer",
        agent_target="litellm",
    ),
    _RouteRule(
        route_id="search",
        task_type="search",
        keywords=["search", "recent", "guidance", "citation", "research", "current"],
        staff_mode="operator",
        agent_target="litellm",
    ),
    _RouteRule(
        route_id="memory",
        task_type="memory_write",
        keywords=["remember", "memory", "prefer", "preference", "forget", "recall"],
        staff_mode="operator",
        agent_target="merlin-core",
    ),
    _RouteRule(
        route_id="general",
        task_type="general",
        keywords=["explain", "summarize", "how", "plan"],
        staff_mode="operator",
        agent_target="litellm",
    ),
)


def _input_hash(user_input: str) -> str:
    return hashlib.sha256(user_input.encode("utf-8")).hexdigest()


def _matched_keywords(user_input: str, keywords: list[str]) -> list[str]:
    normalized = user_input.casefold()
    return [keyword for keyword in keywords if keyword.casefold() in normalized]


def _confidence(match_count: int, keyword_count: int) -> float:
    if match_count == 0:
        return 0.0
    return min(1.0, 0.5 + (match_count / max(keyword_count, 1)))


def _load_config_quietly() -> MerlinConfig:
    with redirect_stdout(io.StringIO()):
        config = load_all_configs()
    if not config.routes.routes:
        raise ValueError("routes.yaml does not define any routes")
    if not config.agents.agents:
        raise ValueError("agents.yaml does not define any agents")
    return config


def _route_spec(config: MerlinConfig, route_id: str) -> RouteSpec:
    try:
        return config.routes.routes[route_id]
    except KeyError as exc:
        raise ValueError(f"routes.yaml does not define route_id: {route_id}") from exc


def _requires_approval(route: RouteSpec) -> bool:
    return bool(route.approval_gates)


def _decision_from_rule(
    config: MerlinConfig,
    rule: _RouteRule,
    matches: list[str],
    confidence: float,
    reason: str,
) -> RouteDecision:
    route = _route_spec(config, rule.route_id)
    return RouteDecision(
        route_id=rule.route_id,
        task_type=rule.task_type,
        staff_mode=rule.staff_mode,
        agent_target=rule.agent_target,
        model_hint=route.preferred_model_alias,
        requires_approval=_requires_approval(route),
        confidence=confidence,
        matched_keywords=matches,
        selected_agent=route.agent,
        required_profile=route.required_profile,
        selected_model_alias=route.preferred_model_alias,
        approval_gates=list(route.approval_gates),
        decision_reason=reason,
    )


def _default_decision(config: MerlinConfig) -> RouteDecision:
    route = _route_spec(config, "general")
    return RouteDecision(
        route_id="general",
        task_type="general",
        staff_mode="operator",
        agent_target="litellm",
        model_hint=route.preferred_model_alias,
        requires_approval=_requires_approval(route),
        confidence=0.0,
        matched_keywords=[],
        selected_agent=route.agent,
        required_profile=route.required_profile,
        selected_model_alias=route.preferred_model_alias,
        approval_gates=list(route.approval_gates),
        decision_reason="No route keywords matched; using general fallback.",
    )


def classify_task(user_input: str) -> RouteDecision:
    """Classify input into a Merlin staff mode and execution target."""

    config = _load_config_quietly()
    best_rule: _RouteRule | None = None
    best_matches: list[str] = []

    for rule in STAFF_ROUTE_RULES:
        matches = _matched_keywords(user_input, rule.keywords)
        if not matches:
            continue
        if best_rule is None:
            best_rule = rule
            best_matches = matches
            continue
        if len(matches) > len(best_matches):
            best_rule = rule
            best_matches = matches
            continue
        if len(matches) == len(best_matches) and len(rule.keywords) > len(best_rule.keywords):
            best_rule = rule
            best_matches = matches

    if best_rule is None:
        return _default_decision(config)

    return _decision_from_rule(
        config=config,
        rule=best_rule,
        matches=best_matches,
        confidence=_confidence(len(best_matches), len(best_rule.keywords)),
        reason=f"Matched route keywords: {', '.join(best_matches)}.",
    )


def route_task(user_input: str) -> RouteDecision:
    """Route a task and log the decision without storing raw input."""

    decision = classify_task(user_input)
    logger.info(
        "route_decision timestamp=%s input_hash=%s route_id=%s staff_mode=%s agent_target=%s confidence=%.2f",
        datetime.now(UTC).isoformat(),
        _input_hash(user_input),
        decision.route_id,
        decision.staff_mode,
        decision.agent_target,
        decision.confidence,
    )
    return decision
