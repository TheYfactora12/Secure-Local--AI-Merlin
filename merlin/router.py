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

from merlin.config_loader import load_all_configs


logger = logging.getLogger(__name__)

AgentTarget = Literal["openhands", "n8n", "litellm", "merlin-core"]


class RouteDecision(BaseModel):
    task_type: str
    staff_mode: str
    agent_target: AgentTarget
    model_hint: str
    requires_approval: bool
    confidence: float = Field(ge=0.0, le=1.0)
    matched_keywords: list[str]


class _RouteRule(BaseModel):
    task_type: str
    keywords: list[str]
    staff_mode: str
    agent_target: AgentTarget
    model_hint: str
    requires_approval: bool


STAFF_ROUTE_RULES: tuple[_RouteRule, ...] = (
    _RouteRule(
        task_type="code",
        keywords=["python", "function", "parse", "json", "code", "debug", "refactor", "test"],
        staff_mode="software_engineer",
        agent_target="openhands",
        model_hint="qwen-coder",
        requires_approval=True,
    ),
    _RouteRule(
        task_type="architecture",
        keywords=["architecture", "architect", "system", "microservice", "service boundary", "scalable"],
        staff_mode="architect",
        agent_target="merlin-core",
        model_hint="qwen7b",
        requires_approval=False,
    ),
    _RouteRule(
        task_type="security",
        keywords=["security", "vulnerability", "sql injection", "scan", "threat", "secret", "credential"],
        staff_mode="security_reviewer",
        agent_target="litellm",
        model_hint="qwen7b",
        requires_approval=False,
    ),
    _RouteRule(
        task_type="automation",
        keywords=["n8n", "automation", "workflow", "daily reports", "reports", "schedule", "webhook"],
        staff_mode="operator",
        agent_target="n8n",
        model_hint="qwen7b",
        requires_approval=True,
    ),
    _RouteRule(
        task_type="ai_engineering",
        keywords=["train", "fine-tuned", "fine tune", "model", "dataset", "embedding", "rag"],
        staff_mode="ai_engineer",
        agent_target="litellm",
        model_hint="qwen7b",
        requires_approval=False,
    ),
    _RouteRule(
        task_type="product_design",
        keywords=["user onboarding", "onboarding", "user flow", "ux", "dashboard", "screen", "design"],
        staff_mode="product_designer",
        agent_target="litellm",
        model_hint="qwen7b",
        requires_approval=False,
    ),
)

DEFAULT_DECISION = RouteDecision(
    task_type="general",
    staff_mode="operator",
    agent_target="litellm",
    model_hint="qwen7b",
    requires_approval=False,
    confidence=0.0,
    matched_keywords=[],
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


def _assert_config_loaded() -> None:
    with redirect_stdout(io.StringIO()):
        config = load_all_configs()
    if not config.routes.routes:
        raise ValueError("routes.yaml does not define any routes")
    if not config.agents.agents:
        raise ValueError("agents.yaml does not define any agents")


def classify_task(user_input: str) -> RouteDecision:
    """Classify input into a Merlin staff mode and execution target."""

    _assert_config_loaded()
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
        return DEFAULT_DECISION.model_copy(deep=True)

    return RouteDecision(
        task_type=best_rule.task_type,
        staff_mode=best_rule.staff_mode,
        agent_target=best_rule.agent_target,
        model_hint=best_rule.model_hint,
        requires_approval=best_rule.requires_approval,
        confidence=_confidence(len(best_matches), len(best_rule.keywords)),
        matched_keywords=best_matches,
    )


def route_task(user_input: str) -> RouteDecision:
    """Route a task and log the decision without storing raw input."""

    decision = classify_task(user_input)
    logger.info(
        "route_decision timestamp=%s input_hash=%s staff_mode=%s agent_target=%s confidence=%.2f",
        datetime.now(UTC).isoformat(),
        _input_hash(user_input),
        decision.staff_mode,
        decision.agent_target,
        decision.confidence,
    )
    return decision
