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
