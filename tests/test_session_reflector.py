from __future__ import annotations

from datetime import UTC, datetime, timedelta

from merlin.outcome_observer import TaskOutcome
from merlin.preference_extractor import extract_preferences
from merlin.session_reflector import DEFAULT_REFLECTION_LOG, SESSION_TTL_DAYS, reflect_session, write_reflection_preview


def _outcome(
    *,
    route_id: str = "general",
    staff_mode: str = "operator",
    confidence: float = 0.8,
    status: str = "success",
    hardware_tier: str = "low",
    created_at: str = "2026-05-06T21:16:00+00:00",
) -> TaskOutcome:
    return TaskOutcome(
        task_hash=f"hash-{route_id}-{staff_mode}-{confidence}",
        route_id=route_id,
        staff_mode=staff_mode,
        agent_target="litellm",
        confidence_at_routing=confidence,
        outcome_status=status,
        latency_ms=12,
        keyword_matches=[],
        hardware_tier=hardware_tier,
        created_at=created_at,
    )


def test_reflection_counts_tasks_and_successes() -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(route_id="general", status="success"),
            _outcome(route_id="code", staff_mode="software_engineer", status="failure"),
            _outcome(route_id="memory", status="success"),
        ],
        session_id="session-1",
        session_duration_s=42,
    )

    assert reflection.session_id == "session-1"
    assert reflection.tasks_attempted == 3
    assert reflection.tasks_succeeded == 2
    assert reflection.session_duration_s == 42
    assert reflection.outcome_mix["success"] == 2
    assert reflection.outcome_mix["failure"] == 1


def test_routes_staff_modes_and_low_confidence_are_unique_in_order() -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(route_id="general", staff_mode="operator", confidence=0.4),
            _outcome(route_id="code", staff_mode="software_engineer", confidence=0.7),
            _outcome(route_id="general", staff_mode="operator", confidence=0.3),
        ]
    )

    assert reflection.routes_used == ["general", "code"]
    assert reflection.staff_modes_used == ["operator", "software_engineer"]
    assert reflection.low_confidence_routes == ["general"]
    assert reflection.review_recommended is True
    assert reflection.reflection_quality == "high_signal"


def test_counts_only_write_eligible_preferences() -> None:
    preferences = [
        *extract_preferences("I prefer Python for scripts."),
        *extract_preferences("Maybe use Qdrant for something."),
    ]

    reflection = reflect_session(outcomes=[_outcome()], preferences=preferences)

    assert len(preferences) == 2
    assert reflection.preferences_extracted == 1
    assert reflection.review_recommended is True
    assert reflection.reflection_quality == "high_signal"


def test_created_and_expires_at_are_utc_iso_with_90_day_ttl() -> None:
    created_at = datetime(2026, 5, 6, 21, 16, tzinfo=UTC)

    reflection = reflect_session(outcomes=[_outcome()], created_at=created_at)

    assert reflection.created_at == "2026-05-06T21:16:00+00:00"
    assert reflection.expires_at == (created_at + timedelta(days=SESSION_TTL_DAYS)).isoformat()


def test_dominant_hardware_tier_is_reported() -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(hardware_tier="low"),
            _outcome(hardware_tier="base"),
            _outcome(hardware_tier="base"),
        ]
    )

    assert reflection.hardware_tier == "base"


def test_empty_session_uses_safe_defaults() -> None:
    reflection = reflect_session(outcomes=[], session_duration_s=-10)

    assert reflection.tasks_attempted == 0
    assert reflection.tasks_succeeded == 0
    assert reflection.routes_used == []
    assert reflection.low_confidence_routes == []
    assert reflection.staff_modes_used == []
    assert reflection.hardware_tier == "unknown"
    assert reflection.session_duration_s == 0
    assert reflection.reflection_quality == "empty"
    assert reflection.review_recommended is False


def test_summary_contains_human_readable_session_context() -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(route_id="code", staff_mode="software_engineer", confidence=0.5),
            _outcome(route_id="memory", staff_mode="operator", confidence=0.9),
        ],
        preferences=extract_preferences("I prefer Python for scripts."),
    )

    assert "Session attempted 2 task(s)" in reflection.summary_text
    assert "Routes used: code, memory" in reflection.summary_text
    assert "Outcome mix:" in reflection.summary_text
    assert "Low-confidence routes needing review: code" in reflection.summary_text


def test_summary_redacts_secret_shapes() -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(route_id="password=supersecret123", staff_mode="operator"),
            _outcome(route_id="general", staff_mode="secret=mytoken"),
        ]
    )

    rendered = reflection.model_dump_json()
    assert "supersecret123" not in rendered
    assert "mytoken" not in rendered
    assert "[REDACTED]" in rendered


def test_failure_degraded_and_rejected_outcomes_recommend_review() -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(status="failure"),
            _outcome(status="degraded"),
            _outcome(status="rejected"),
        ]
    )

    assert reflection.outcome_mix == {
        "success": 0,
        "failure": 1,
        "timeout": 0,
        "rejected": 1,
        "degraded": 1,
    }
    assert reflection.review_recommended is True
    assert reflection.reflection_quality == "weak"


def test_single_clean_success_is_weak_without_review_signal() -> None:
    reflection = reflect_session(outcomes=[_outcome()])

    assert reflection.review_recommended is False
    assert reflection.reflection_quality == "weak"


def test_multiple_clean_successes_are_useful() -> None:
    reflection = reflect_session(outcomes=[_outcome(), _outcome(route_id="code")])

    assert reflection.review_recommended is False
    assert reflection.reflection_quality == "useful"


def test_write_reflection_preview_is_explicit_and_redacted(tmp_path) -> None:
    reflection = reflect_session(
        outcomes=[
            _outcome(route_id="password=supersecret123", staff_mode="secret=mytoken"),
        ],
        session_id="session-preview",
    )

    log_path = write_reflection_preview(reflection, logs_dir=tmp_path)

    assert log_path == tmp_path / DEFAULT_REFLECTION_LOG
    content = log_path.read_text(encoding="utf-8")
    assert "session-preview" in content
    assert "supersecret123" not in content
    assert "mytoken" not in content
    assert "[REDACTED]" in content
