"""Phase 3D review-only session reflection.

The reflector summarizes already-recorded local task outcomes and preference
candidates. It does not call an LLM, write memory, touch Qdrant, or modify
configuration.
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from datetime import UTC, datetime, timedelta
from uuid import uuid4

from pydantic import BaseModel, Field, field_validator

from merlin.outcome_observer import TaskOutcome
from merlin.preference_extractor import PreferenceCandidate, redact_sensitive_text


LOW_CONFIDENCE_THRESHOLD = 0.6
SESSION_TTL_DAYS = 90


class SessionReflection(BaseModel):
    """Review-only session summary candidate."""

    session_id: str = Field(min_length=1)
    summary_text: str = Field(min_length=1)
    tasks_attempted: int = Field(ge=0)
    tasks_succeeded: int = Field(ge=0)
    routes_used: list[str]
    low_confidence_routes: list[str]
    preferences_extracted: int = Field(ge=0)
    staff_modes_used: list[str]
    hardware_tier: str
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
    staff_modes_used = _unique(redact_sensitive_text(outcome.staff_mode) for outcome in sorted_outcomes)
    hardware_tier = _dominant_hardware_tier(sorted_outcomes)
    eligible_preferences = [preference for preference in preferences if preference.write_eligible]

    return SessionReflection(
        session_id=session_id or str(uuid4()),
        summary_text=_summary_text(
            tasks_attempted=tasks_attempted,
            tasks_succeeded=tasks_succeeded,
            routes_used=routes_used,
            low_confidence_routes=low_confidence_routes,
            preferences_extracted=len(eligible_preferences),
            staff_modes_used=staff_modes_used,
            hardware_tier=hardware_tier,
        ),
        tasks_attempted=tasks_attempted,
        tasks_succeeded=tasks_succeeded,
        routes_used=routes_used,
        low_confidence_routes=low_confidence_routes,
        preferences_extracted=len(eligible_preferences),
        staff_modes_used=staff_modes_used,
        hardware_tier=hardware_tier,
        session_duration_s=max(0, session_duration_s),
        created_at=now.isoformat(),
        expires_at=(now + timedelta(days=SESSION_TTL_DAYS)).isoformat(),
    )


def _summary_text(
    *,
    tasks_attempted: int,
    tasks_succeeded: int,
    routes_used: list[str],
    low_confidence_routes: list[str],
    preferences_extracted: int,
    staff_modes_used: list[str],
    hardware_tier: str,
) -> str:
    route_text = ", ".join(routes_used) if routes_used else "none"
    staff_text = ", ".join(staff_modes_used) if staff_modes_used else "none"
    summary = (
        f"Session attempted {tasks_attempted} task(s) and completed {tasks_succeeded} successfully. "
        f"Routes used: {route_text}; staff modes used: {staff_text}. "
        f"Hardware tier was {hardware_tier}; {preferences_extracted} approved preference candidate(s) were extracted."
    )
    if low_confidence_routes:
        summary += f" Low-confidence routes needing review: {', '.join(low_confidence_routes)}."
    else:
        summary += " No low-confidence routes were flagged."
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


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
