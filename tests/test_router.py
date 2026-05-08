from __future__ import annotations

import logging
import os
import subprocess
import sys
from dataclasses import FrozenInstanceError
from datetime import UTC, datetime, timedelta
import json
from pathlib import Path
from typing import Any

from merlin.router import (
    KEYWORD_WEIGHT,
    NO_RETRAINING_CONSTRAINT,
    OUTCOME_DECAY_DAYS,
    RETRIEVAL_WEIGHT,
    classify_task,
    route_task,
)
from merlin.swarm_coordinator import build_swarm_context


def test_code_routes_to_software_engineer_openhands() -> None:
    decision = route_task("write a python function to parse JSON")
    assert decision.staff_mode == "software_engineer"
    assert decision.agent_target == "openhands"
    assert decision.confidence > 0.5


def test_architecture_routes_to_architect() -> None:
    decision = route_task("design the system architecture for a new microservice")
    assert decision.staff_mode == "architect"
    assert decision.agent_target in {"litellm", "merlin-core"}
    assert decision.confidence > 0.5


def test_security_routes_to_security_reviewer() -> None:
    decision = route_task("scan this code for SQL injection vulnerabilities")
    assert decision.staff_mode == "security_reviewer"
    assert decision.confidence > 0.5


def test_automation_routes_to_operator_n8n() -> None:
    decision = route_task("set up an n8n automation for daily reports")
    assert decision.staff_mode == "operator"
    assert decision.agent_target == "n8n"
    assert decision.confidence > 0.5


def test_model_training_routes_to_ai_engineer() -> None:
    decision = route_task("train a fine-tuned model on this dataset")
    assert decision.staff_mode == "ai_engineer"
    assert decision.confidence > 0.5


def test_onboarding_routes_to_product_designer() -> None:
    decision = route_task("design the user onboarding flow")
    assert decision.staff_mode == "product_designer"
    assert decision.confidence > 0.5


def test_unknown_input_routes_to_default() -> None:
    decision = route_task("what is the weather")
    assert decision.route_id == "general"
    assert decision.staff_mode == "operator"
    assert decision.agent_target == "litellm"
    assert decision.confidence == 0.0
    assert decision.matched_keywords == []


def test_all_six_staff_modes_are_represented() -> None:
    cases = [
        "design the system architecture for a new microservice",
        "train a fine-tuned model on this dataset",
        "write a python function to parse JSON",
        "scan this code for SQL injection vulnerabilities",
        "design the user onboarding flow",
        "set up an n8n automation for daily reports",
    ]
    staff_modes = {classify_task(case).staff_mode for case in cases}
    assert staff_modes == {
        "architect",
        "ai_engineer",
        "software_engineer",
        "security_reviewer",
        "product_designer",
        "operator",
    }


def test_route_logging_hashes_input_without_raw_text(caplog) -> None:
    caplog.set_level(logging.INFO, logger="merlin.router")
    raw_input = "write a python function to parse JSON"
    route_task(raw_input)

    messages = "\n".join(record.getMessage() for record in caplog.records)
    assert "input_hash=" in messages
    assert raw_input not in messages


def test_all_config_route_ids_classify_correctly() -> None:
    cases = [
        ("write a python function", "code"),
        ("search for recent FFIEC guidance", "search"),
        ("set up an n8n webhook", "automation"),
        ("remember that I prefer qwen7b", "memory"),
        ("explain how RAG works", "general"),
    ]

    for text, expected in cases:
        assert route_task(text).route_id == expected


def test_code_route_carries_all_approval_gates() -> None:
    decision = classify_task("write a python function")
    assert decision.approval_gates == [
        "service_start",
        "file_read",
        "file_write",
        "shell_command",
        "git_operation",
        "openhands_task",
    ]


def test_trace_fields_are_present_on_every_decision() -> None:
    decision = route_task("explain how Qdrant works")
    for field_name in [
        "route_id",
        "task_type",
        "selected_agent",
        "required_profile",
        "preferred_model_alias",
        "selected_model_alias",
        "approval_gates",
        "decision_reason",
    ]:
        assert getattr(decision, field_name) is not None


def test_staff_modes_select_configured_model_aliases_on_non_low_memory(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    cases = [
        ("design the system architecture for a new microservice", "architect", "deepseek"),
        ("train a fine-tuned model on this dataset", "ai_engineer", "qwen-coder"),
        ("write a python function to parse JSON", "software_engineer", "qwen-coder"),
        ("scan this code for SQL injection vulnerabilities", "security_reviewer", "deepseek"),
        ("design the user onboarding flow", "product_designer", "qwen7b"),
        ("set up an n8n automation for daily reports", "operator", "mistral"),
    ]

    for text, staff_mode, model_alias in cases:
        decision = classify_task(text)
        assert decision.staff_mode == staff_mode
        assert decision.preferred_model_alias == model_alias
        assert decision.selected_model_alias == model_alias
        assert decision.model_fallback_applied is False


def test_low_memory_tier_falls_back_to_safe_local_alias(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 8)

    decision = classify_task("design the system architecture for a new microservice")

    assert decision.staff_mode == "architect"
    assert decision.preferred_model_alias == "deepseek"
    assert decision.selected_model_alias == "mistral"
    assert decision.model_fallback_applied is True
    assert decision.model_fallback_reason is not None


def test_route_task_writes_audit_event_without_raw_input(monkeypatch) -> None:
    writes: list[tuple[str, dict[str, Any]]] = []

    class FakeMemoryManager:
        def __init__(self, timeout: int = 1) -> None:
            self.timeout = timeout

        def write_audit_event(self, event_type: str, metadata: dict[str, Any]) -> str:
            writes.append((event_type, metadata))
            return "audit-point-1"

    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)

    raw_input = "explain how Qdrant works"
    decision = route_task(raw_input)

    assert decision.audit_point_id == "audit-point-1"
    assert decision.audit_written is True
    assert writes[0][0] == "route_decision"
    metadata = writes[0][1]
    assert metadata["route_id"] == decision.route_id
    assert metadata["staff_mode"] == decision.staff_mode
    assert metadata["selected_model_alias"] == decision.selected_model_alias
    assert metadata["outcome_status"] == "routed"
    assert "task_hash" in metadata
    assert raw_input not in str(metadata)


def test_route_task_continues_when_audit_write_fails(monkeypatch, caplog) -> None:
    class FailingMemoryManager:
        def __init__(self, timeout: int = 1) -> None:
            self.timeout = timeout

        def write_audit_event(self, event_type: str, metadata: dict[str, Any]) -> str:
            raise OSError("qdrant unavailable")

    monkeypatch.setattr("merlin.router.MemoryManager", FailingMemoryManager)
    caplog.set_level(logging.WARNING, logger="merlin.router")

    decision = route_task("explain how Qdrant works")

    assert decision.audit_point_id is None
    assert decision.audit_written is False
    assert "route_audit_skipped" in "\n".join(record.getMessage() for record in caplog.records)


def test_architect_mode(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    decision = classify_task("design scalable microservice architecture")

    assert decision.staff_mode == "architect"
    assert "deepseek" in decision.selected_model_alias


def test_ai_engineer_mode(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    decision = classify_task("create embedding pipeline for RAG dataset")

    assert decision.staff_mode == "ai_engineer"
    assert "qwen-coder" in decision.selected_model_alias


def test_software_engineer_mode(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    decision = classify_task("refactor this Python function and add tests")

    assert decision.staff_mode == "software_engineer"
    assert "qwen-coder" in decision.selected_model_alias


def test_security_reviewer_mode(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    decision = classify_task("scan for credential exposure and sql injection vulnerabilities")

    assert decision.staff_mode == "security_reviewer"
    assert decision.requires_approval is True
    assert "file_read" in decision.approval_gates
    assert "secret_access" in decision.approval_gates


def test_product_designer_mode(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    decision = classify_task("design user onboarding flow for the dashboard")

    assert decision.staff_mode == "product_designer"


def test_operator_mode(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 32)

    decision = classify_task("schedule daily reports n8n automation workflow")

    assert decision.staff_mode == "operator"


def test_low_memory_fallback(monkeypatch) -> None:
    monkeypatch.setattr("merlin.router._detect_ram_gb", lambda: 8)

    decision = classify_task("design scalable microservice architecture")

    assert decision.model_fallback_applied is True
    assert decision.selected_model_alias == "mistral"


def test_cloud_block_via_approval_gate() -> None:
    decision = classify_task("search for recent AI guidance with citation")

    assert "cloud_model_call" in decision.approval_gates
    assert decision.requires_approval is True


def test_audit_written_flag(monkeypatch) -> None:
    class FakeMemoryManager:
        def __init__(self, timeout: int = 1) -> None:
            self.timeout = timeout

        def write_audit_event(self, event_type: str, metadata: dict[str, Any]) -> str:
            return "audit-point-uuid"

    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)

    decision = route_task("explain routing")

    assert decision.audit_point_id == "audit-point-uuid"
    assert decision.audit_written is True


def test_swarm_context_immutable() -> None:
    decision = classify_task("explain routing")
    context = build_swarm_context(decision)

    try:
        context.staff_mode = "hacked"
    except FrozenInstanceError:
        pass
    else:
        raise AssertionError("SwarmContext should be immutable")


def test_swarm_context_fields_match_decision() -> None:
    decision = classify_task("refactor the Python router and add tests")
    context = build_swarm_context(decision)

    assert context.staff_mode == decision.staff_mode
    assert context.selected_model_alias == decision.selected_model_alias
    assert context.preferred_model_alias == decision.preferred_model_alias
    assert context.model_fallback_applied == decision.model_fallback_applied
    assert context.model_fallback_reason == decision.model_fallback_reason
    assert context.agent_target == decision.agent_target
    assert context.approval_gates == decision.approval_gates
    assert context.requires_approval == decision.requires_approval
    assert context.confidence == decision.confidence
    assert context.route_id == decision.route_id
    assert context.task_type == decision.task_type
    assert context.resolved_at.endswith("+00:00")


def test_default_fallback_route() -> None:
    decision = classify_task("xyzzy abc 123")

    assert decision.route_id == "general"
    assert decision.confidence == 0.0
    assert decision.keyword_score == 0.0
    assert decision.retrieval_score == 0.0


def test_cold_start_preserves_keyword_confidence(monkeypatch, tmp_path) -> None:
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(tmp_path / "missing-outcomes.jsonl"))

    decision = classify_task("explain Qdrant")

    assert decision.keyword_score == decision.confidence
    assert decision.retrieval_score == 0.0
    assert decision.retrieval_sample_count == 0


def test_router_exposes_no_retraining_and_weight_constants() -> None:
    assert NO_RETRAINING_CONSTRAINT is True
    assert KEYWORD_WEIGHT == 0.6
    assert RETRIEVAL_WEIGHT == 0.4
    assert KEYWORD_WEIGHT + RETRIEVAL_WEIGHT == 1.0
    assert OUTCOME_DECAY_DAYS == 30


def test_routes_yaml_exposes_local_no_telemetry_contract() -> None:
    routes_yaml = Path("configs/merlin/routes.yaml").read_text()

    assert "cloud_allowed: false" in routes_yaml
    assert "telemetry: disabled" in routes_yaml


def test_approved_success_outcomes_boost_retrieval_score(monkeypatch, tmp_path) -> None:
    outcome_log = tmp_path / "outcomes.jsonl"
    created_at = datetime.now(UTC).isoformat()
    outcome_log.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "event_type": "task_outcome",
                        "route_id": "general",
                        "outcome_status": "success",
                        "approval_id": "approval-1",
                        "created_at": created_at,
                    }
                ),
                json.dumps(
                    {
                        "event_type": "task_outcome",
                        "route_id": "general",
                        "outcome_status": "success",
                        "approval_id": "approval-2",
                        "created_at": created_at,
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(outcome_log))

    decision = classify_task("explain Qdrant")

    assert decision.retrieval_sample_count == 2
    assert decision.retrieval_score > 0.99
    assert decision.confidence > decision.keyword_score
    assert "Retrieval score" in decision.decision_reason


def test_qdrant_task_signature_retrieval_is_used_when_available(monkeypatch, tmp_path) -> None:
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(tmp_path / "missing-outcomes.jsonl"))
    created_at = datetime.now(UTC).isoformat()
    searches: list[tuple[str, str]] = []

    class FakeMemoryManager:
        def __init__(self, timeout: int = 1) -> None:
            self.timeout = timeout

        def search_task_outcomes_by_signature(self, task_signature: str, route_id: str, limit: int = 50):
            searches.append((task_signature, route_id))
            if route_id != "general":
                return []
            return [
                {
                    "id": "qdrant-hit-1",
                    "score": 0.94,
                    "payload": {
                        "event_type": "task_outcome",
                        "route_id": "general",
                        "outcome_status": "success",
                        "approval_id": "approval-qdrant",
                        "created_at": created_at,
                        "task_hash": "hash-only",
                    },
                }
            ]

    monkeypatch.setattr("merlin.router.MemoryManager", FakeMemoryManager)

    decision = classify_task("explain Qdrant")

    assert searches
    assert decision.retrieval_source == "qdrant"
    assert decision.retrieval_sample_count == 1
    assert decision.retrieval_score > 0.99
    assert decision.confidence > decision.keyword_score
    assert "approved qdrant outcome" in decision.decision_reason


def test_qdrant_unavailable_falls_back_to_jsonl(monkeypatch, tmp_path) -> None:
    outcome_log = tmp_path / "outcomes.jsonl"
    outcome_log.write_text(
        json.dumps(
            {
                "event_type": "task_outcome",
                "route_id": "general",
                "outcome_status": "success",
                "approval_id": "approval-jsonl",
                "created_at": datetime.now(UTC).isoformat(),
            }
        )
        + "\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(outcome_log))

    class FailingMemoryManager:
        def __init__(self, timeout: int = 1) -> None:
            self.timeout = timeout

        def search_task_outcomes_by_signature(self, task_signature: str, route_id: str, limit: int = 50):
            raise OSError("qdrant unavailable")

    monkeypatch.setattr("merlin.router.MemoryManager", FailingMemoryManager)

    decision = classify_task("explain Qdrant")

    assert decision.retrieval_source == "jsonl"
    assert decision.retrieval_sample_count == 1
    assert decision.retrieval_score > 0.99


def test_approved_failure_outcomes_penalize_final_score(monkeypatch, tmp_path) -> None:
    outcome_log = tmp_path / "outcomes.jsonl"
    outcome_log.write_text(
        json.dumps(
            {
                "event_type": "task_outcome",
                "route_id": "general",
                "outcome_status": "failure",
                "approval_id": "approval-1",
                "created_at": datetime.now(UTC).isoformat(),
            }
        )
        + "\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(outcome_log))

    decision = classify_task("explain Qdrant")

    assert decision.retrieval_sample_count == 1
    assert decision.retrieval_score == 0.0
    assert decision.confidence < decision.keyword_score


def test_unapproved_outcomes_do_not_affect_routing(monkeypatch, tmp_path) -> None:
    outcome_log = tmp_path / "outcomes.jsonl"
    outcome_log.write_text(
        json.dumps(
            {
                "event_type": "task_outcome",
                "route_id": "general",
                "outcome_status": "success",
                "approval_id": None,
                "created_at": datetime.now(UTC).isoformat(),
                "raw_input": "explain Qdrant",
            }
        )
        + "\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(outcome_log))

    decision = classify_task("explain Qdrant")

    assert decision.retrieval_sample_count == 0
    assert decision.retrieval_score == 0.0
    assert decision.confidence == decision.keyword_score


def test_retrieval_scoring_uses_recency_decay(monkeypatch, tmp_path) -> None:
    outcome_log = tmp_path / "outcomes.jsonl"
    now = datetime.now(UTC)
    outcome_log.write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "event_type": "task_outcome",
                        "route_id": "general",
                        "outcome_status": "success",
                        "approval_id": "approval-new",
                        "created_at": now.isoformat(),
                    }
                ),
                json.dumps(
                    {
                        "event_type": "task_outcome",
                        "route_id": "general",
                        "outcome_status": "failure",
                        "approval_id": "approval-old",
                        "created_at": (now - timedelta(days=90)).isoformat(),
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("MERLIN_OUTCOME_LOG", str(outcome_log))

    decision = classify_task("explain Qdrant")

    assert decision.retrieval_sample_count == 2
    assert decision.retrieval_score > 0.9


def test_wizard_mode_status_uses_swarm_context() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["MERLIN_PYTHON"] = sys.executable

    result = subprocess.run(
        ["bash", "cli/wizard", "mode", "status"],
        cwd=repo_root,
        env=env,
        check=True,
        capture_output=True,
        text=True,
        timeout=10,
    )

    assert "=== Merlin Mode Status ===" in result.stdout
    assert "Active Staff Mode :" in result.stdout
    assert "Selected Model    :" in result.stdout
    assert "Fallback Applied  :" in result.stdout
