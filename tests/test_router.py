from __future__ import annotations

import logging

from merlin.router import classify_task, route_task


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
