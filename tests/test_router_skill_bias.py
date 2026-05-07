from __future__ import annotations

from merlin.router import route_task


class FakeReport:
    def __init__(self, preferred: str | None):
        self.preferred = preferred

    def best_agent_for(self, domain: str) -> str | None:
        return self.preferred


class FakeMemoryManager:
    def __init__(self, timeout: int = 1):
        self.timeout = timeout

    def write_audit_event(self, event_type: str, metadata: dict) -> None:
        return None


def test_router_uses_preferred_agent_when_skill_report_qualifies(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)
    monkeypatch.setattr("merlin.router.compute_skill_report", lambda memory=None: FakeReport("merlin-core"))

    decision = route_task("explain how Qdrant works")

    assert decision.agent_target == "merlin-core"
    assert decision.skill_bias_applied is True
    assert decision.skill_bias_agent == "merlin-core"


def test_router_keeps_original_agent_without_qualifying_score(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)
    monkeypatch.setattr("merlin.router.compute_skill_report", lambda memory=None: FakeReport(None))

    decision = route_task("explain how Qdrant works")

    assert decision.agent_target == "litellm"
    assert decision.skill_bias_applied is False
    assert decision.skill_bias_agent is None


def test_router_ignores_invalid_skill_bias_agent(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)
    monkeypatch.setattr("merlin.router.compute_skill_report", lambda memory=None: FakeReport("swarm-heavy"))

    decision = route_task("explain how Qdrant works")

    assert decision.agent_target == "litellm"
    assert decision.skill_bias_applied is False
    assert decision.skill_bias_agent is None


def test_router_does_not_bias_safe_route_to_openhands_without_gates(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)
    monkeypatch.setattr("merlin.router.compute_skill_report", lambda memory=None: FakeReport("openhands"))

    decision = route_task("explain how Qdrant works")

    assert decision.route_id == "general"
    assert decision.agent_target == "litellm"
    assert decision.requires_approval is False
    assert decision.skill_bias_applied is False
    assert decision.skill_bias_agent is None


def test_router_does_not_bias_safe_route_to_n8n_without_gates(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)
    monkeypatch.setattr("merlin.router.compute_skill_report", lambda memory=None: FakeReport("n8n"))

    decision = route_task("explain how Qdrant works")

    assert decision.route_id == "general"
    assert decision.agent_target == "litellm"
    assert decision.requires_approval is False
    assert decision.skill_bias_applied is False
    assert decision.skill_bias_agent is None


def test_router_does_not_crash_when_skill_scorer_raises(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)

    def fail(memory=None):
        raise OSError("qdrant unavailable")

    monkeypatch.setattr("merlin.router.compute_skill_report", fail)

    decision = route_task("explain how Qdrant works")

    assert decision.route_id == "general"
    assert decision.agent_target == "litellm"
    assert decision.skill_bias_applied is False
