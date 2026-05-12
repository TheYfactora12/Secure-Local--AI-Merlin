"""Phase 3D review-only session reflection.

The reflector summarizes already-recorded local task outcomes and preference
candidates. It does not call an LLM, write memory, touch Qdrant, or modify
configuration.
"""

from __future__ import annotations

import json
from collections.abc import Iterable, Sequence
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Literal
from uuid import uuid4

from pydantic import BaseModel, Field, field_validator

from merlin.outcome_observer import TaskOutcome
from merlin.preference_extractor import PreferenceCandidate, redact_sensitive_text


UTC = timezone.utc
LOW_CONFIDENCE_THRESHOLD = 0.6
SESSION_TTL_DAYS = 90
DEFAULT_REFLECTION_LOG = "merlin-session-reflections.jsonl"

OutcomeMix = dict[str, int]
ReflectionQuality = Literal["empty", "weak", "useful", "high_signal"]


class SessionReflection(BaseModel):
    """Review-only session summary candidate."""

    session_id: str = Field(min_length=1)
    summary_text: str = Field(min_length=1)
    tasks_attempted: int = Field(ge=0)
    tasks_succeeded: int = Field(ge=0)
    routes_used: list[str]
    low_confidence_routes: list[str]
    outcome_mix: OutcomeMix
    preferences_extracted: int = Field(ge=0)
    staff_modes_used: list[str]
    hardware_tier: str
    reflection_quality: ReflectionQuality
    review_recommended: bool
    session_duration_s: int = Field(ge=0)
    created_at: str
    expires_at: str

    @field_validator("summary_text")
    @classmethod
    def _summary_is_redacted(cls, value: str) -> str:
        return redact_sensitive_text(value)


def reflect_session(
    *,
    outcomes: Sequence[TaskOutcome],
    preferences: Sequence[PreferenceCandidate] = (),
    session_id: str | None = None,
    session_duration_s: int = 0,
    created_at: datetime | None = None,
) -> SessionReflection:
    """Build a review-only reflection from local outcome records.

    This function performs no persistence. Callers must route any future memory
    write through the normal approval-gated memory path.
    """

    now = _as_utc(created_at or datetime.now(UTC))
    sorted_outcomes = sorted(outcomes, key=lambda item: item.created_at)
    tasks_attempted = len(sorted_outcomes)
    tasks_succeeded = sum(1 for outcome in sorted_outcomes if outcome.outcome_status == "success")
    routes_used = _unique(redact_sensitive_text(outcome.route_id) for outcome in sorted_outcomes)
    low_confidence_routes = _unique(
        redact_sensitive_text(outcome.route_id)
        for outcome in sorted_outcomes
        if outcome.confidence_at_routing < LOW_CONFIDENCE_THRESHOLD
    )
    outcome_mix = _outcome_mix(sorted_outcomes)
    staff_modes_used = _unique(redact_sensitive_text(outcome.staff_mode) for outcome in sorted_outcomes)
    hardware_tier = _dominant_hardware_tier(sorted_outcomes)
    eligible_preferences = [preference for preference in preferences if preference.write_eligible]
    review_recommended = _review_recommended(
        outcome_mix=outcome_mix,
        low_confidence_routes=low_confidence_routes,
        preferences_extracted=len(eligible_preferences),
    )
    reflection_quality = _reflection_quality(
        tasks_attempted=tasks_attempted,
        tasks_succeeded=tasks_succeeded,
        low_confidence_routes=low_confidence_routes,
        preferences_extracted=len(eligible_preferences),
        review_recommended=review_recommended,
    )

    return SessionReflection(
        session_id=session_id or str(uuid4()),
        summary_text=_summary_text(
            tasks_attempted=tasks_attempted,
            tasks_succeeded=tasks_succeeded,
            routes_used=routes_used,
            low_confidence_routes=low_confidence_routes,
            outcome_mix=outcome_mix,
            preferences_extracted=len(eligible_preferences),
            staff_modes_used=staff_modes_used,
            hardware_tier=hardware_tier,
            reflection_quality=reflection_quality,
            review_recommended=review_recommended,
        ),
        tasks_attempted=tasks_attempted,
        tasks_succeeded=tasks_succeeded,
        routes_used=routes_used,
        low_confidence_routes=low_confidence_routes,
        outcome_mix=outcome_mix,
        preferences_extracted=len(eligible_preferences),
        staff_modes_used=staff_modes_used,
        hardware_tier=hardware_tier,
        reflection_quality=reflection_quality,
        review_recommended=review_recommended,
        session_duration_s=max(0, session_duration_s),
        created_at=now.isoformat(),
        expires_at=(now + timedelta(days=SESSION_TTL_DAYS)).isoformat(),
    )


def write_reflection_preview(
    reflection: SessionReflection,
    *,
    logs_dir: str | Path = "logs",
) -> Path:
    """Write a redacted JSONL preview record for local review.

    This is an explicit logging helper, not a memory write. It does not touch
    Qdrant or any external service.
    """

    path = Path(logs_dir)
    path.mkdir(parents=True, exist_ok=True)
    log_path = path / DEFAULT_REFLECTION_LOG
    record = reflection.model_dump()
    record["summary_text"] = redact_sensitive_text(record["summary_text"])
    record["routes_used"] = [redact_sensitive_text(value) for value in record["routes_used"]]
    record["low_confidence_routes"] = [
        redact_sensitive_text(value) for value in record["low_confidence_routes"]
    ]
    record["staff_modes_used"] = [redact_sensitive_text(value) for value in record["staff_modes_used"]]
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    return log_path


def _summary_text(
    *,
    tasks_attempted: int,
    tasks_succeeded: int,
    routes_used: list[str],
    low_confidence_routes: list[str],
    outcome_mix: OutcomeMix,
    preferences_extracted: int,
    staff_modes_used: list[str],
    hardware_tier: str,
    reflection_quality: ReflectionQuality,
    review_recommended: bool,
) -> str:
    route_text = ", ".join(routes_used) if routes_used else "none"
    staff_text = ", ".join(staff_modes_used) if staff_modes_used else "none"
    outcome_text = ", ".join(f"{key}={value}" for key, value in outcome_mix.items())
    summary = (
        f"Session attempted {tasks_attempted} task(s) and completed {tasks_succeeded} successfully. "
        f"Routes used: {route_text}; staff modes used: {staff_text}. "
        f"Outcome mix: {outcome_text}. Hardware tier was {hardware_tier}; "
        f"{preferences_extracted} approved preference candidate(s) were extracted."
    )
    if low_confidence_routes:
        summary += f" Low-confidence routes needing review: {', '.join(low_confidence_routes)}."
    else:
        summary += " No low-confidence routes were flagged."
    summary += f" Reflection quality is {reflection_quality}; review recommended: {review_recommended}."
    return redact_sensitive_text(summary)


def _unique(values: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if not value or value in seen:
            continue
        seen.add(value)
        result.append(value)
    return result


def _dominant_hardware_tier(outcomes: Sequence[TaskOutcome]) -> str:
    counts: dict[str, int] = {}
    for outcome in outcomes:
        counts[outcome.hardware_tier] = counts.get(outcome.hardware_tier, 0) + 1
    if not counts:
        return "unknown"
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[0][0]


def _outcome_mix(outcomes: Sequence[TaskOutcome]) -> OutcomeMix:
    mix = {"success": 0, "failure": 0, "timeout": 0, "rejected": 0, "degraded": 0}
    for outcome in outcomes:
        mix[outcome.outcome_status] = mix.get(outcome.outcome_status, 0) + 1
    return mix


def _review_recommended(
    *,
    outcome_mix: OutcomeMix,
    low_confidence_routes: list[str],
    preferences_extracted: int,
) -> bool:
    if low_confidence_routes or preferences_extracted > 0:
        return True
    return any(outcome_mix[key] > 0 for key in ("failure", "timeout", "rejected", "degraded"))


def _reflection_quality(
    *,
    tasks_attempted: int,
    tasks_succeeded: int,
    low_confidence_routes: list[str],
    preferences_extracted: int,
    review_recommended: bool,
) -> ReflectionQuality:
    if tasks_attempted == 0:
        return "empty"
    if tasks_attempted == 1 and not review_recommended:
        return "weak"
    if preferences_extracted > 0 or low_confidence_routes:
        return "high_signal"
    if tasks_succeeded > 0:
        return "useful"
    return "weak"


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
