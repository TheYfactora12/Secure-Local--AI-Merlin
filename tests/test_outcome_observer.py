from __future__ import annotations

import json

from merlin.outcome_observer import observe_task_outcome
from merlin.router import classify_task


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def test_observe_task_outcome_writes_redacted_jsonl(tmp_path, monkeypatch) -> None:
    monkeypatch.delenv("MERLIN_OUTCOME_APPROVAL_ID", raising=False)
    decision = classify_task("explain how Qdrant works")

    outcome = observe_task_outcome(
        user_input="secret user input should not appear",
        route_decision=decision,
        outcome_status="success",
        latency_ms=12,
        logs_dir=tmp_path,
    )

    records = _read_jsonl(tmp_path / "merlin-outcomes.jsonl")
    assert records[0]["task_hash"] == outcome.task_hash
    assert records[0]["route_id"] == decision.route_id
    assert "secret user input" not in (tmp_path / "merlin-outcomes.jsonl").read_text(encoding="utf-8")
    assert records[0]["audit_written"] is False


def test_no_qdrant_audit_write_without_approval_id(tmp_path, monkeypatch) -> None:
    monkeypatch.delenv("MERLIN_OUTCOME_APPROVAL_ID", raising=False)

    class ExplodingMemoryManager:
        def __init__(self, *args, **kwargs):
            raise AssertionError("MemoryManager must not be used without approval")

    monkeypatch.setattr("merlin.outcome_observer.MemoryManager", ExplodingMemoryManager)

    outcome = observe_task_outcome(
        user_input="explain routing",
        route_decision=classify_task("explain routing"),
        outcome_status="success",
        latency_ms=1,
        logs_dir=tmp_path,
    )

    assert outcome.audit_written is False


def test_qdrant_audit_write_requires_approval_id(tmp_path, monkeypatch) -> None:
    class FakeMemoryManager:
        def __init__(self, *args, **kwargs):
            pass

        def write_audit_event(self, event_type, metadata):
            assert event_type == "task_outcome"
            assert metadata["approval_id"] == "approval-123"
            assert metadata["skill_domain"] == "research"
            assert metadata["outcome_rating"] == "approved"
            return "audit-point-123"

        def write_skill_outcome(self, outcome):
            assert outcome["approval_id"] == "approval-123"
            assert outcome["skill_domain"] == "research"
            assert outcome["outcome_rating"] == "approved"
            return "skill-point-123"

    monkeypatch.setattr("merlin.outcome_observer.MemoryManager", FakeMemoryManager)

    outcome = observe_task_outcome(
        user_input="explain routing",
        route_decision=classify_task("explain routing"),
        outcome_status="success",
        latency_ms=1,
        approval_id="approval-123",
        logs_dir=tmp_path,
    )

    assert outcome.audit_written is True
    assert outcome.audit_point_id == "audit-point-123"
    assert outcome.skill_outcome_written is True
    assert outcome.skill_outcome_point_id == "skill-point-123"


def test_negative_feedback_maps_to_rejected_rating(tmp_path, monkeypatch) -> None:
    monkeypatch.delenv("MERLIN_OUTCOME_APPROVAL_ID", raising=False)

    outcome = observe_task_outcome(
        user_input="write a python function",
        route_decision=classify_task("write a python function"),
        outcome_status="success",
        latency_ms=1,
        user_feedback="negative",
        logs_dir=tmp_path,
    )

    assert outcome.skill_domain == "code"
    assert outcome.outcome_rating == "rejected"


def test_failed_outcome_without_feedback_has_no_rating(tmp_path, monkeypatch) -> None:
    monkeypatch.delenv("MERLIN_OUTCOME_APPROVAL_ID", raising=False)

    outcome = observe_task_outcome(
        user_input="set up n8n workflow",
        route_decision=classify_task("set up n8n workflow"),
        outcome_status="failure",
        latency_ms=1,
        logs_dir=tmp_path,
    )

    assert outcome.skill_domain == "automation"
    assert outcome.outcome_rating == "none"


def test_low_confidence_success_creates_routing_gap(tmp_path, monkeypatch) -> None:
    monkeypatch.delenv("MERLIN_OUTCOME_APPROVAL_ID", raising=False)
    decision = classify_task("xyzzy abc 123")

    observe_task_outcome(
        user_input="xyzzy abc 123",
        route_decision=decision,
        outcome_status="success",
        latency_ms=1,
        logs_dir=tmp_path,
    )

    gaps = _read_jsonl(tmp_path / "merlin-routing-gaps.jsonl")
    assert gaps[0]["routed_to"] == "general"
    assert gaps[0]["confidence"] == 0.0
    assert "xyzzy abc 123" not in (tmp_path / "merlin-routing-gaps.jsonl").read_text(encoding="utf-8")
