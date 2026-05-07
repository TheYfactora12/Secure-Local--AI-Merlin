"""Native Merlin task router.

The current routes.yaml defines route classes rather than explicit keyword
rules. This module keeps that config intact and adds a small compatibility
layer that maps known task phrases to Merlin's six staff modes.
"""

from __future__ import annotations

import hashlib
import io
import json
import logging
import math
import os
import platform
import subprocess
from contextlib import redirect_stdout
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field

from merlin.config_loader import MerlinConfig, RouteSpec, load_all_configs
from merlin.memory_manager import MemoryManager
from merlin.skill_scorer import compute_skill_report


logger = logging.getLogger(__name__)
OUTCOME_LOG_PATH = Path("logs/merlin-outcomes.jsonl")
OUTCOME_DECAY_DAYS = 30
OUTCOME_SAMPLE_LIMIT = 50

AgentTarget = Literal["openhands", "n8n", "litellm", "merlin-core"]
ALLOWED_AGENT_TARGETS = {"openhands", "n8n", "litellm", "merlin-core"}
SKILL_BIAS_SAFE_TARGETS = {"litellm", "merlin-core"}
SKILL_DOMAIN_HINTS: dict[str, str] = {
    "security": "security",
    "vulnerability": "security",
    "sql injection": "security",
    "threat": "security",
    "secret": "security",
    "credential": "security",
    "search": "research",
    "research": "research",
    "summarize": "research",
    "explain": "research",
    "code": "code",
    "python": "code",
    "function": "code",
    "debug": "code",
    "refactor": "code",
    "test": "code",
    "n8n": "automation",
    "automation": "automation",
    "workflow": "automation",
    "schedule": "automation",
}

# Mapping from RouteDecision task_type to PreferenceCategory domain
_TASK_TYPE_TO_PREF_CATEGORY: dict[str, str] = {
    "code": "coding_style",
    "architecture": "architecture_decision",
    "security": "domain_expertise",
    "automation": "workflow_pattern",
    "ai_engineering": "tool_preference",
    "product_design": "communication_style",
    "search": "workflow_pattern",
    "memory_write": "workflow_pattern",
    "general": "workflow_pattern",
}


class RouteDecision(BaseModel):
    route_id: str
    task_type: str
    staff_mode: str
    agent_target: AgentTarget
    model_hint: str
    requires_approval: bool
    confidence: float = Field(ge=0.0, le=1.0)
    keyword_score: float = Field(default=0.0, ge=0.0, le=1.0)
    retrieval_score: float = Field(default=0.0, ge=0.0, le=1.0)
    retrieval_sample_count: int = 0
    matched_keywords: list[str]
    selected_agent: str
    required_profile: str
    selected_model_alias: str
    preferred_model_alias: str
    model_fallback_applied: bool = False
    model_fallback_reason: str | None = None
    audit_point_id: str | None = None
    audit_written: bool = False
    approval_gates: list[str]
    decision_reason: str
    skill_bias_applied: bool = False
    skill_bias_agent: str | None = None
    # Phase 3C: preference injection audit fields
    preference_context_injected: bool = False
    preference_count_injected: int = 0


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


def _outcome_log_path() -> Path:
    return Path(os.environ.get("MERLIN_OUTCOME_LOG", str(OUTCOME_LOG_PATH)))


def _parse_created_at(value: object) -> datetime | None:
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=UTC)
    return parsed.astimezone(UTC)


def _approved_outcomes(route_id: str, now: datetime | None = None) -> list[dict]:
    path = _outcome_log_path()
    if not path.exists():
        return []

    matched: list[dict] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return []

    for line in reversed(lines):
        if len(matched) >= OUTCOME_SAMPLE_LIMIT:
            break
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        if record.get("event_type") != "task_outcome":
            continue
        if record.get("route_id") != route_id:
            continue
        if not record.get("approval_id"):
            continue
        created_at = _parse_created_at(record.get("created_at"))
        if created_at is None:
            continue
        matched.append(record)
    return list(reversed(matched))


def _retrieval_score(route_id: str, now: datetime | None = None) -> tuple[float, int]:
    now = now or datetime.now(UTC)
    outcomes = _approved_outcomes(route_id, now)
    if not outcomes:
        return 0.0, 0

    weighted_success = 0.0
    total_weight = 0.0
    for outcome in outcomes:
        created_at = _parse_created_at(outcome.get("created_at"))
        if created_at is None:
            continue
        age = max(timedelta(0), now - created_at)
        days_since_outcome = age.total_seconds() / 86400
        weight = math.exp(-days_since_outcome / OUTCOME_DECAY_DAYS)
        success = 1.0 if outcome.get("outcome_status") == "success" else 0.0
        weighted_success += success * weight
        total_weight += weight

    if total_weight == 0:
        return 0.0, 0
    return max(0.0, min(1.0, weighted_success / total_weight)), len(outcomes)


def _final_confidence(keyword_score: float, retrieval_score: float, retrieval_sample_count: int) -> float:
    if retrieval_sample_count == 0:
        return keyword_score
    return max(0.0, min(1.0, (0.6 * keyword_score) + (0.4 * retrieval_score)))


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


def _detect_ram_gb() -> int:
    if platform.system() == "Darwin":
        try:
            output = subprocess.check_output(
                ["sysctl", "-n", "hw.memsize"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=2,
            ).strip()
            return int(round(int(output) / 1024 / 1024 / 1024))
        except (OSError, subprocess.SubprocessError, ValueError):
            return 0

    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("MemTotal:"):
                    kb = int(line.split()[1])
                    return int(round(kb / 1024 / 1024))
    except (OSError, ValueError):
        return 0
    return 0


def _hardware_tier(ram_gb: int) -> str:
    if ram_gb >= 48:
        return "high"
    if ram_gb >= 24:
        return "mid"
    if ram_gb >= 16:
        return "base"
    if ram_gb > 0:
        return "low"
    return "unknown"


def _staff_model_alias(config: MerlinConfig, staff_mode: str, route: RouteSpec) -> str:
    return config.routes.staff_model_aliases.get(staff_mode, route.preferred_model_alias)


def _select_model_alias(
    config: MerlinConfig,
    staff_mode: str,
    route: RouteSpec,
) -> tuple[str, str, bool, str | None]:
    preferred = _staff_model_alias(config, staff_mode, route)
    preferred_model = config.models.models[preferred]
    tier = _hardware_tier(_detect_ram_gb())
    fallback = config.routes.low_memory_fallback_model_alias
    if tier == "low" and preferred != fallback and not preferred_model.enabled_by_default:
        return (
            preferred,
            fallback,
            True,
            f"Low-memory hardware tier selected {fallback} instead of {preferred}.",
        )
    return preferred, preferred, False, None


def _decision_from_rule(
    config: MerlinConfig,
    rule: _RouteRule,
    matches: list[str],
    confidence: float,
    keyword_score: float,
    retrieval_score: float,
    retrieval_sample_count: int,
    reason: str,
) -> RouteDecision:
    route = _route_spec(config, rule.route_id)
    preferred_model, selected_model, fallback_applied, fallback_reason = _select_model_alias(
        config, rule.staff_mode, route
    )
    approval_gates = list(route.approval_gates)
    if rule.staff_mode == "security_reviewer" and not approval_gates:
        approval_gates = ["file_read", "secret_access"]
    return RouteDecision(
        route_id=rule.route_id,
        task_type=rule.task_type,
        staff_mode=rule.staff_mode,
        agent_target=rule.agent_target,
        model_hint=preferred_model,
        requires_approval=bool(approval_gates),
        confidence=confidence,
        keyword_score=keyword_score,
        retrieval_score=retrieval_score,
        retrieval_sample_count=retrieval_sample_count,
        matched_keywords=matches,
        selected_agent=route.agent,
        required_profile=route.required_profile,
        selected_model_alias=selected_model,
        preferred_model_alias=preferred_model,
        model_fallback_applied=fallback_applied,
        model_fallback_reason=fallback_reason,
        approval_gates=approval_gates,
        decision_reason=reason,
    )


def _default_decision(config: MerlinConfig) -> RouteDecision:
    route = _route_spec(config, "general")
    preferred_model, selected_model, fallback_applied, fallback_reason = _select_model_alias(config, "operator", route)
    return RouteDecision(
        route_id="general",
        task_type="general",
        staff_mode="operator",
        agent_target="litellm",
        model_hint=preferred_model,
        requires_approval=_requires_approval(route),
        confidence=0.0,
        keyword_score=0.0,
        retrieval_score=0.0,
        retrieval_sample_count=0,
        matched_keywords=[],
        selected_agent=route.agent,
        required_profile=route.required_profile,
        selected_model_alias=selected_model,
        preferred_model_alias=preferred_model,
        model_fallback_applied=fallback_applied,
        model_fallback_reason=fallback_reason,
        approval_gates=list(route.approval_gates),
        decision_reason="No route keywords matched; using general fallback.",
    )


def _skill_domain_from_decision(decision: RouteDecision) -> str:
    for keyword in decision.matched_keywords:
        domain = SKILL_DOMAIN_HINTS.get(keyword.casefold())
        if domain:
            return domain
    if decision.task_type in {"code", "security", "automation"}:
        return decision.task_type
    if decision.task_type in {"ai_engineering", "architecture", "product_design"}:
        return "analysis"
    return "general"


def _apply_skill_bias(decision: RouteDecision) -> RouteDecision:
    domain = _skill_domain_from_decision(decision)
    try:
        report = compute_skill_report(memory=MemoryManager(timeout=1))
        preferred = report.best_agent_for(domain)
    except Exception as exc:
        logger.warning("skill_scorer_unavailable error=%s route_id=%s", exc, decision.route_id)
        return decision

    if preferred and preferred not in ALLOWED_AGENT_TARGETS:
        logger.info(
            "skill_bias_ignored invalid_agent=%s domain=%s route_id=%s",
            preferred,
            domain,
            decision.route_id,
        )
        return decision

    if preferred and preferred not in SKILL_BIAS_SAFE_TARGETS and preferred != decision.agent_target:
        logger.info(
            "skill_bias_ignored risky_agent=%s domain=%s route_id=%s",
            preferred,
            domain,
            decision.route_id,
        )
        return decision

    if preferred and preferred != decision.agent_target:
        logger.info(
            "skill_bias_applied original=%s preferred=%s domain=%s route_id=%s",
            decision.agent_target,
            preferred,
            domain,
            decision.route_id,
        )
        decision.agent_target = preferred  # type: ignore[assignment]
        decision.skill_bias_applied = True
        decision.skill_bias_agent = preferred
        decision.decision_reason = f"{decision.decision_reason} Skill score bias selected {preferred} for {domain}."
    return decision


def _preference_context_for_domain(
    domain_category: str,
    memory: MemoryManager | None = None,
) -> list[str]:
    """Retrieve approved preferences for a domain category.

    Returns list of preference_text strings for system prompt injection.
    Returns empty list if memory unavailable — never raises.
    Non-blocking: called before routing, not in the routing critical path.
    """
    if memory is None:
        try:
            memory = MemoryManager(timeout=1)
        except Exception:
            return []
    prefs = memory.get_preferences_by_category(domain_category)
    return [p.get("preference_text", "") for p in prefs if p.get("preference_text")]


def _inject_preferences(system_prompt: str, preferences: list[str]) -> str:
    """Prepend active user preferences to system prompt.

    Format:
        ACTIVE USER PREFERENCES (apply to this task):
        - User prefers 3 commits not 1
        - User always wants tests included with code changes
        [original system prompt continues]
    """
    if not preferences:
        return system_prompt
    pref_block = "ACTIVE USER PREFERENCES (apply to this task):\n"
    pref_block += "\n".join(f"- {p}" for p in preferences[:5])  # max 5 to avoid prompt bloat
    pref_block += "\n\n"
    return pref_block + system_prompt


def classify_task(user_input: str) -> RouteDecision:
    """Classify input into a Merlin staff mode and execution target."""

    config = _load_config_quietly()
    best_rule: _RouteRule | None = None
    best_matches: list[str] = []
    best_keyword_score = 0.0
    best_retrieval_score = 0.0
    best_retrieval_sample_count = 0
    best_final_score = 0.0

    for rule in STAFF_ROUTE_RULES:
        matches = _matched_keywords(user_input, rule.keywords)
        if not matches:
            continue
        keyword_score = _confidence(len(matches), len(rule.keywords))
        retrieval_score, retrieval_sample_count = _retrieval_score(rule.route_id)
        final_score = _final_confidence(keyword_score, retrieval_score, retrieval_sample_count)
        if best_rule is None:
            best_rule = rule
            best_matches = matches
            best_keyword_score = keyword_score
            best_retrieval_score = retrieval_score
            best_retrieval_sample_count = retrieval_sample_count
            best_final_score = final_score
            continue
        if final_score > best_final_score:
            best_rule = rule
            best_matches = matches
            best_keyword_score = keyword_score
            best_retrieval_score = retrieval_score
            best_retrieval_sample_count = retrieval_sample_count
            best_final_score = final_score
            continue
        if final_score == best_final_score and len(matches) > len(best_matches):
            best_rule = rule
            best_matches = matches
            best_keyword_score = keyword_score
            best_retrieval_score = retrieval_score
            best_retrieval_sample_count = retrieval_sample_count
            best_final_score = final_score
            continue
        if (
            final_score == best_final_score
            and len(matches) == len(best_matches)
            and len(rule.keywords) > len(best_rule.keywords)
        ):
            best_rule = rule
            best_matches = matches
            best_keyword_score = keyword_score
            best_retrieval_score = retrieval_score
            best_retrieval_sample_count = retrieval_sample_count
            best_final_score = final_score

    if best_rule is None:
        return _default_decision(config)

    reason = f"Matched route keywords: {', '.join(best_matches)}."
    if best_retrieval_sample_count:
        reason = (
            f"{reason} Retrieval score {best_retrieval_score:.2f} from "
            f"{best_retrieval_sample_count} approved outcome(s)."
        )
    return _decision_from_rule(
        config=config,
        rule=best_rule,
        matches=best_matches,
        confidence=best_final_score,
        keyword_score=best_keyword_score,
        retrieval_score=best_retrieval_score,
        retrieval_sample_count=best_retrieval_sample_count,
        reason=reason,
    )


def _write_route_audit(decision: RouteDecision, input_hash: str, timestamp: str) -> str | None:
    payload = {
        "actor": "merlin.router",
        "created_at": timestamp,
        "route_id": decision.route_id,
        "task_type": decision.task_type,
        "staff_mode": decision.staff_mode,
        "agent_target": decision.agent_target,
        "confidence_at_routing": decision.confidence,
        "keyword_score": decision.keyword_score,
        "retrieval_score": decision.retrieval_score,
        "retrieval_sample_count": decision.retrieval_sample_count,
        "keyword_matches": list(decision.matched_keywords),
        "approval_gates": list(decision.approval_gates),
        "requires_approval": decision.requires_approval,
        "preferred_model_alias": decision.preferred_model_alias,
        "selected_model_alias": decision.selected_model_alias,
        "model_fallback_applied": decision.model_fallback_applied,
        "model_fallback_reason": decision.model_fallback_reason,
        "skill_bias_applied": decision.skill_bias_applied,
        "skill_bias_agent": decision.skill_bias_agent,
        "preference_context_injected": decision.preference_context_injected,
        "preference_count_injected": decision.preference_count_injected,
        "outcome_status": "routed",
        "task_hash": input_hash,
    }

    try:
        return MemoryManager(timeout=1).write_audit_event("route_decision", payload)
    except Exception as exc:
        logger.warning(
            "route_audit_skipped input_hash=%s route_id=%s error=%s",
            input_hash,
            decision.route_id,
            exc,
        )
        return None


def route_task(user_input: str, system_prompt: str = "") -> tuple[RouteDecision, str]:
    """Route a task and log the decision without storing raw input.

    Returns (RouteDecision, system_prompt) where system_prompt may be
    prepended with active user preferences when available.
    Preference injection is non-blocking — Qdrant failure never breaks routing.
    """

    decision = _apply_skill_bias(classify_task(user_input))

    # Load active preferences for this domain (non-blocking, graceful on failure)
    pref_category = _TASK_TYPE_TO_PREF_CATEGORY.get(decision.task_type, "workflow_pattern")
    try:
        active_prefs = _preference_context_for_domain(pref_category)
        if active_prefs:
            system_prompt = _inject_preferences(system_prompt, active_prefs)
            decision.preference_context_injected = True
            decision.preference_count_injected = min(len(active_prefs), 5)
            logger.info(
                "preference_context_injected count=%d domain=%s",
                decision.preference_count_injected,
                pref_category,
            )
    except Exception as exc:
        logger.warning("preference_injection_skipped error=%s", exc)
        # Routing continues normally — preferences are additive, not load-bearing

    timestamp = datetime.now(UTC).isoformat()
    input_hash = _input_hash(user_input)
    audit_point_id = _write_route_audit(decision, input_hash, timestamp)
    decision.audit_point_id = audit_point_id
    decision.audit_written = audit_point_id is not None
    logger.info(
        "route_decision timestamp=%s input_hash=%s route_id=%s staff_mode=%s agent_target=%s "
        "preferred_model=%s selected_model=%s fallback=%s audit_written=%s confidence=%.2f "
        "pref_injected=%s pref_count=%d",
        timestamp,
        input_hash,
        decision.route_id,
        decision.staff_mode,
        decision.agent_target,
        decision.preferred_model_alias,
        decision.selected_model_alias,
        decision.model_fallback_applied,
        decision.audit_written,
        decision.confidence,
        decision.preference_context_injected,
        decision.preference_count_injected,
    )
    return decision, system_prompt
