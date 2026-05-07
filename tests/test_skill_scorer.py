from __future__ import annotations

from datetime import UTC, datetime, timedelta

from merlin.skill_scorer import (
    MIN_OUTCOMES_FOR_SCORE,
    SkillReport,
    SkillScore,
    _recency_weight,
    _trend,
    compute_skill_report,
)


class FakeMemory:
    def __init__(self, records):
        self.records = records

    def scroll_collection(self, collection: str, limit: int = 1000):
        assert collection == "skill_outcomes"
        assert limit == 1000
        return self.records


class FailingMemory:
    def scroll_collection(self, collection: str, limit: int = 1000):
        raise OSError("qdrant down")


def _record(agent: str, domain: str, rating: str, created_at: str | None = None) -> dict:
    return {
        "payload": {
            "agent_target": agent,
            "skill_domain": domain,
            "outcome_rating": rating,
            "route_id": "general",
            "confidence_at_routing": 0.7,
            "hardware_tier": "low",
            "created_at": created_at or datetime.now(UTC).isoformat(),
        }
    }


def _score(records, **kwargs):
    report = compute_skill_report(memory=FakeMemory(records), **kwargs)
    assert len(report.scores) == 1
    return report.scores[0]


def test_compute_skill_report_returns_empty_when_qdrant_down() -> None:
    report = compute_skill_report(memory=FailingMemory())

    assert report.scores == []
    assert report.total_outcomes_read == 0
    assert report.generated_at


def test_score_none_when_sample_size_below_minimum() -> None:
    score = _score([_record("litellm", "research", "approved")] * (MIN_OUTCOMES_FOR_SCORE - 1))

    assert score.score is None
    assert score.confidence == 0.0
    assert score.sample_size == MIN_OUTCOMES_FOR_SCORE - 1
    assert score.route_bias is False


def test_all_approved_outcomes_score_close_to_one() -> None:
    score = _score([_record("litellm", "research", "approved")] * 5)

    assert score.score is not None
    assert score.score > 0.99


def test_all_rejected_outcomes_score_close_to_zero() -> None:
    score = _score([_record("litellm", "research", "rejected")] * 5)

    assert score.score == 0.0


def test_mixed_outcomes_score_between_zero_and_one() -> None:
    score = _score(
        [
            _record("litellm", "research", "approved"),
            _record("litellm", "research", "approved"),
            _record("litellm", "research", "rejected"),
            _record("litellm", "research", "rejected"),
        ]
    )

    assert score.score is not None
    assert 0.0 < score.score < 1.0


def test_recency_weight_recent_timestamp_beats_old_timestamp() -> None:
    recent = datetime.now(UTC).isoformat()
    old = (datetime.now(UTC) - timedelta(days=90)).isoformat()

    assert _recency_weight(recent) > _recency_weight(old)


def test_trend_returns_up_when_late_outcomes_score_higher() -> None:
    outcomes = [
        (0.0, "2026-05-01T00:00:00+00:00"),
        (0.0, "2026-05-02T00:00:00+00:00"),
        (0.0, "2026-05-03T00:00:00+00:00"),
        (1.0, "2026-05-04T00:00:00+00:00"),
        (1.0, "2026-05-05T00:00:00+00:00"),
        (1.0, "2026-05-06T00:00:00+00:00"),
    ]

    assert _trend(outcomes) == "up"


def test_trend_unknown_when_fewer_than_six_outcomes() -> None:
    assert _trend([(1.0, "2026-05-01T00:00:00+00:00")] * 5) == "unknown"


def test_best_agent_for_returns_none_without_qualifying_agents() -> None:
    report = SkillReport(
        scores=[
            SkillScore(
                agent="litellm",
                domain="research",
                score=0.9,
                confidence=0.9,
                sample_size=10,
                last_seen=None,
                trending="stable",
                route_bias=False,
            )
        ]
    )

    assert report.best_agent_for("research") is None


def test_best_agent_for_returns_competing_qualifying_agent() -> None:
    report = SkillReport(
        scores=[
            SkillScore("agent-a", "security", 0.7, 0.5, 8, None, "stable", True),
            SkillScore("agent-b", "security", 0.8, 0.8, 12, None, "up", True),
            SkillScore("agent-c", "code", 1.0, 1.0, 12, None, "up", True),
        ]
    )

    assert report.best_agent_for("security") == "agent-b"


def test_as_table_returns_header_and_rows() -> None:
    report = SkillReport(scores=[SkillScore("agent", "general", 0.5, 0.4, 4, None, "stable", True)])

    table = report.as_table()

    assert "AGENT" in table
    assert "DOMAIN" in table
    assert "agent" in table
