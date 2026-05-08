from __future__ import annotations

import httpx

from fastapi.testclient import TestClient

from merlin.config_loader import load_all_configs
from merlin import task_endpoint
from merlin.task_endpoint import TASK_TRACE_BUFFER, app


client = TestClient(app)


class _FakeLiteLLMResponse:
    def raise_for_status(self) -> None:
        return None

    def json(self) -> dict:
        return {"choices": [{"message": {"content": "Merlin response"}}]}


def setup_function() -> None:
    TASK_TRACE_BUFFER.clear()


def test_status_routes_returns_all_routes_with_correct_shape() -> None:
    response = client.get("/status/routes")
    assert response.status_code == 200
    body = response.json()
    assert body["routes"]
    first = body["routes"][0]
    assert {
        "route_id",
        "staff_mode",
        "keywords",
        "requires_approval",
        "approval_gates",
        "preferred_model_alias",
    } <= set(first)


def test_status_routes_total_matches_routes_yaml_count() -> None:
    response = client.get("/status/routes")
    assert response.status_code == 200
    assert response.json()["total"] == len(load_all_configs().routes.routes)


def test_status_approvals_returns_all_15_gates() -> None:
    response = client.get("/status/approvals")
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 15
    assert len(body["gates"]) == 15
    assert any(gate["gate_name"] == "webhook_execution" for gate in body["gates"])


def test_status_approvals_counts_add_to_total() -> None:
    response = client.get("/status/approvals")
    assert response.status_code == 200
    body = response.json()
    assert body["open_count"] + body["closed_count"] == body["total"]


def test_status_traces_returns_empty_list_on_fresh_start() -> None:
    response = client.get("/status/traces")
    assert response.status_code == 200
    body = response.json()
    assert body == {"traces": [], "total_recorded": 0}


def test_status_traces_returns_trace_after_post_task_succeeds(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", lambda **kwargs: None)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())
    task_response = client.post("/task", json={"input": "explain how RAG works", "session_id": "session-1"})
    assert task_response.status_code == 200

    response = client.get("/status/traces")
    body = response.json()
    assert body["total_recorded"] == 1
    assert body["traces"][0]["route_id"] == "general"


def test_status_traces_never_contains_raw_input_text(monkeypatch) -> None:
    raw_input = "explain how RAG works"
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", lambda **kwargs: None)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())
    client.post("/task", json={"input": raw_input, "session_id": "session-1"})

    response_text = response_body = client.get("/status/traces").text
    assert raw_input not in response_text
    assert "input_hash" in response_body


def test_status_traces_latency_ms_is_positive_integer(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", lambda **kwargs: None)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())
    client.post("/task", json={"input": "explain how RAG works", "session_id": "session-1"})

    trace = client.get("/status/traces").json()["traces"][0]
    assert isinstance(trace["latency_ms"], int)
    assert trace["latency_ms"] > 0


def test_status_memory_returns_degraded_when_qdrant_unreachable(monkeypatch) -> None:
    def raise_unreachable(*args, **kwargs):
        raise OSError("qdrant unreachable")

    monkeypatch.setattr("merlin.status_extension.request.urlopen", raise_unreachable)
    response = client.get("/status/memory")
    assert response.status_code == 200
    assert response.json()["degraded"] is True


def test_status_memory_returns_correct_collection_names_from_memory_yaml(monkeypatch) -> None:
    def raise_unreachable(*args, **kwargs):
        raise OSError("qdrant unreachable")

    monkeypatch.setattr("merlin.status_extension.request.urlopen", raise_unreachable)
    response = client.get("/status/memory")
    names = {collection["name"] for collection in response.json()["collections"]}
    config = load_all_configs()
    expected = set(config.memory.canonical) | set(config.memory.legacy)
    assert names == expected


def test_status_providers_returns_local_first_registry() -> None:
    response = client.get("/status/providers")
    assert response.status_code == 200
    body = response.json()
    assert body["mode"] == "local_only"
    assert body["local_first"] is True
    assert body["cloud_enabled"] is False
    assert body["external_providers_enabled"] is False
    assert body["total"] >= 5


def test_status_providers_reports_local_ollama_and_litellm() -> None:
    response = client.get("/status/providers")
    providers = {provider["provider_id"]: provider for provider in response.json()["providers"]}
    assert providers["ollama"]["enabled"] is True
    assert providers["ollama"]["local"] is True
    assert providers["ollama"]["api_key_required"] is False
    assert "qwen7b" in providers["ollama"]["model_aliases"]
    assert providers["litellm"]["enabled"] is True
    assert providers["litellm"]["local"] is True


def test_status_providers_external_cloud_disabled_even_when_key_present(monkeypatch) -> None:
    fake_key = "test-openai-key-value-that-must-never-be-returned"
    monkeypatch.setenv("OPENAI_API_KEY", fake_key)

    response = client.get("/status/providers")
    body_text = response.text
    providers = {provider["provider_id"]: provider for provider in response.json()["providers"]}

    assert providers["openai"]["enabled"] is False
    assert providers["openai"]["local"] is False
    assert providers["openai"]["api_key_present"] is True
    assert providers["openai"]["requires_approval"] is True
    assert fake_key not in body_text


def test_status_providers_never_exposes_known_cloud_key_values(monkeypatch) -> None:
    secret_values = {
        "OPENAI_API_KEY": "openai-secret-value",
        "ANTHROPIC_API_KEY": "anthropic-secret-value",
        "PERPLEXITY_API_KEY": "perplexity-secret-value",
    }
    for key, value in secret_values.items():
        monkeypatch.setenv(key, value)

    response_text = client.get("/status/providers").text

    for value in secret_values.values():
        assert value not in response_text


def test_task_endpoint_main_uses_8766_not_legacy_8765() -> None:
    source = task_endpoint.__loader__.get_source(task_endpoint.__name__)
    assert 'port=8766' in source
    assert 'port=8765' not in source
