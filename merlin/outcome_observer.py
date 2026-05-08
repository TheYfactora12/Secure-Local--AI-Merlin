"""Phase 3A outcome observer for Merlin's local learning loop."""

from __future__ import annotations

import hashlib
import json
import logging
import os
import platform
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field

from merlin.memory_manager import MemoryManager
from merlin.router import RouteDecision


logger = logging.getLogger(__name__)

OutcomeStatus = Literal["success", "failure", "timeout", "rejected", "degraded"]
UserFeedback = Literal["positive", "negative", "none"]
OutcomeRating = Literal["approved", "corrected", "rejected", "none"]

DEFAULT_OUTCOME_LOG = "merlin-outcomes.jsonl"
DEFAULT_ROUTING_GAP_LOG = "merlin-routing-gaps.jsonl"
LOW_CONFIDENCE_THRESHOLD = 0.6

SKILL_DOMAIN_MAP: dict[str, str] = {
    "security": "security",
    "audit": "security",
    "compliance": "security",
    "vulnerability": "security",
    "risk": "security",
    "threat": "security",
    "glba": "security",
    "ffiec": "security",
    "ncua": "security",
    "research": "research",
    "search": "research",
    "find": "research",
    "summarize": "research",
    "explain": "research",
    "what": "research",
    "code": "code",
    "write": "code",
    "fix": "code",
    "debug": "code",
    "implement": "code",
    "function": "code",
    "script": "code",
    "analyze": "analysis",
    "compare": "analysis",
    "evaluate": "analysis",
    "assess": "analysis",
    "review": "analysis",
    "install": "ops",
    "configure": "ops",
    "deploy": "ops",
    "upgrade": "ops",
    "backup": "ops",
    "restore": "ops",
    "automate": "automation",
    "workflow": "automation",
    "schedule": "automation",
}


class TaskOutcome(BaseModel):
    event_type: Literal["task_outcome"] = "task_outcome"
    task_hash: str
    route_id: str
    staff_mode: str
    agent_target: str
    confidence_at_routing: float = Field(ge=0.0, le=1.0)
    outcome_status: OutcomeStatus
    latency_ms: int = Field(ge=0)
    keyword_matches: list[str]
    hardware_tier: str
    user_feedback: UserFeedback = "none"
    created_at: str
    approval_id: str | None = None
    audit_point_id: str | None = None
    audit_written: bool = False
    skill_domain: str = "general"
    outcome_rating: OutcomeRating = "none"
    task_signature_point_id: str | None = None
    task_signature_written: bool = False
    skill_outcome_point_id: str | None = None
    skill_outcome_written: bool = False


class RoutingGapReviewItem(BaseModel):
    task_hash: str
    routed_to: str
    confidence: float
    outcome: OutcomeStatus
    matched_keywords: list[str]
    candidate_keywords: list[str] = Field(default_factory=list)
    suggested_route: str | None = None
    flagged_at: str


def observe_task_outcome(
    *,
    user_input: str,
    route_decision: RouteDecision,
    outcome_status: OutcomeStatus,
    latency_ms: int,
    user_feedback: UserFeedback = "none",
    approval_id: str | None = None,
    logs_dir: str | Path = "logs",
    write_audit: bool = True,
) -> TaskOutcome:
    """Record a task outcome without storing raw user input.

    Local JSONL logging is always allowed because it stores hashes and route
    metadata only. Persistent Qdrant audit writes require an explicit approval id
    argument or MERLIN_OUTCOME_APPROVAL_ID in the environment.
    """

    created_at = datetime.now(UTC).isoformat()
    effective_approval_id = approval_id or os.environ.get("MERLIN_OUTCOME_APPROVAL_ID") or None
    outcome = TaskOutcome(
        task_hash=_task_hash(user_input),
        route_id=route_decision.route_id,
        staff_mode=route_decision.staff_mode,
        agent_target=route_decision.agent_target,
        confidence_at_routing=route_decision.confidence,
        outcome_status=outcome_status,
        latency_ms=max(0, latency_ms),
        keyword_matches=list(route_decision.matched_keywords),
        hardware_tier=_hardware_tier(_detect_ram_gb()),
        user_feedback=user_feedback,
        created_at=created_at,
        approval_id=effective_approval_id,
        skill_domain=_skill_domain(route_decision.matched_keywords),
        outcome_rating=_outcome_rating(user_feedback, outcome_status),
    )

    log_path = _logs_dir(logs_dir) / DEFAULT_OUTCOME_LOG
    _append_jsonl(log_path, outcome.model_dump())

    if outcome_status == "success" and route_decision.confidence < LOW_CONFIDENCE_THRESHOLD:
        gap = RoutingGapReviewItem(
            task_hash=outcome.task_hash,
            routed_to=route_decision.route_id,
            confidence=route_decision.confidence,
            outcome=outcome_status,
            matched_keywords=list(route_decision.matched_keywords),
            flagged_at=created_at,
        )
        _append_jsonl(_logs_dir(logs_dir) / DEFAULT_ROUTING_GAP_LOG, gap.model_dump())

    if write_audit and effective_approval_id:
        try:
            memory = MemoryManager(timeout=1)
            point_id = memory.write_audit_event("task_outcome", outcome.model_dump())
            outcome.audit_point_id = point_id
            outcome.audit_written = point_id is not None
            signature_point_id = memory.write_task_outcome_signature(
                outcome.model_dump(),
                _task_signature(user_input),
            )
            outcome.task_signature_point_id = signature_point_id
            outcome.task_signature_written = signature_point_id is not None
            skill_point_id = memory.write_skill_outcome(outcome.model_dump())
            outcome.skill_outcome_point_id = skill_point_id
            outcome.skill_outcome_written = skill_point_id is not None
        except Exception as exc:
            logger.warning("outcome_audit_write_skipped route_id=%s error=%s", route_decision.route_id, exc)

    return outcome


def _task_hash(user_input: str) -> str:
    return hashlib.sha256(user_input.encode("utf-8")).hexdigest()


def _task_signature(user_input: str) -> str:
    return " ".join(user_input.split())[:1000]


def _skill_domain(keyword_matches: list[str]) -> str:
    for keyword in keyword_matches:
        normalized = keyword.casefold()
        if normalized in SKILL_DOMAIN_MAP:
            return SKILL_DOMAIN_MAP[normalized]
    return "general"


def _outcome_rating(user_feedback: UserFeedback, outcome_status: OutcomeStatus) -> OutcomeRating:
    if user_feedback == "positive":
        return "approved"
    if user_feedback == "negative":
        return "rejected"
    if outcome_status == "success":
        return "approved"
    return "none"


def _logs_dir(path: str | Path) -> Path:
    logs = Path(path)
    logs.mkdir(parents=True, exist_ok=True)
    return logs


def _append_jsonl(path: Path, record: dict) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")


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
