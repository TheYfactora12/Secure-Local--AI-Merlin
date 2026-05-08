from __future__ import annotations

import httpx
from fastapi.testclient import TestClient

from merlin.persona_injector import PI_WARMTH_BLOCK, build_system_prompt
from merlin.router import route_task
from merlin.task_endpoint import app


client = TestClient(app)


class _FakeLiteLLMResponse:
    def raise_for_status(self) -> None:
        return None

    def json(self) -> dict:
        return {"choices": [{"message": {"content": "Merlin response"}}]}


def _noop_outcome_observer(**kwargs):
    return None


def test_task_endpoint_tests_do_not_write_outcome_logs_by_default(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())

    response = client.post("/task", json={"input": "explain how RAG works"})

    assert response.status_code == 200


def test_post_task_with_valid_input_routes_correctly(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())

    response = client.post("/task", json={"input": "explain how RAG works"})

    assert response.status_code == 200
    body = response.json()
    assert body["response"] == "Merlin response"
    assert body["route"]["route_id"] == "general"
    assert body["approved"] is True
    assert body["memory_written"] is False


def test_litellm_call_includes_authorization_header(monkeypatch) -> None:
    captured = {}

    def fake_post(*args, **kwargs):
        captured.update(kwargs)
        return _FakeLiteLLMResponse()

    monkeypatch.setenv("LITELLM_MASTER_KEY", "test-local-key")
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", fake_post)

    response = client.post("/task", json={"input": "explain routing"})

    assert response.status_code == 200
    assert captured["headers"] == {"Authorization": "Bearer test-local-key"}


def test_post_task_with_empty_string_returns_400() -> None:
    response = client.post("/task", json={"input": "   "})
    assert response.status_code == 400


def test_post_task_with_input_exceeding_4000_chars_returns_400() -> None:
    response = client.post("/task", json={"input": "x" * 4001})
    assert response.status_code == 400


def test_post_task_route_requiring_approval_returns_403_with_gates(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)

    response = client.post("/task", json={"input": "write a python function"})

    assert response.status_code == 403
    detail = response.json()["detail"]
    assert detail["route_id"] == "code"
    assert detail["route"]["route_id"] == "code"
    assert detail["route"]["staff_mode"] == "software_engineer"
    assert detail["route"]["selected_model_alias"]
    assert detail["approval_gates"] == [
        "service_start",
        "file_read",
        "file_write",
        "shell_command",
        "git_operation",
        "openhands_task",
    ]


def test_post_task_when_litellm_unreachable_returns_degraded_response(monkeypatch) -> None:
    def raise_connect_error(*args, **kwargs):
        raise httpx.ConnectError("unreachable")

    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", raise_connect_error)

    response = client.post("/task", json={"input": "explain how Qdrant works"})

    assert response.status_code == 200
    body = response.json()
    assert body["response"] == "Merlin is starting up. Try again in 30 seconds."
    assert body["route"] == {}
    assert body["approved"] is False
    assert body["degraded"] is True


def test_system_prompt_contains_persona_name_merlin() -> None:
    prompt = build_system_prompt(route_task("explain how RAG works"))
    assert "Name: Merlin" in prompt


def test_system_prompt_contains_guardian_ethos_commitment_text() -> None:
    prompt = build_system_prompt(route_task("explain how RAG works"))
    assert "Protect human agency; Merlin advises and assists but does not rule." in prompt


def test_pi_warmth_block_is_present_in_every_system_prompt() -> None:
    prompt = build_system_prompt(route_task("explain how RAG works"))
    assert PI_WARMTH_BLOCK in prompt
