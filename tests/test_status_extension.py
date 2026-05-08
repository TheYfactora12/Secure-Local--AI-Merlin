from __future__ import annotations

import json

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


class _FakeUrlOpenResponse:
    def __init__(self, payload: dict):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        return None

    def read(self) -> bytes:
        return json.dumps(self.payload).encode("utf-8")


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


def test_status_models_reports_embedding_only_as_missing_chat_model(monkeypatch) -> None:
    def fake_urlopen(*args, **kwargs):
        return _FakeUrlOpenResponse({"models": [{"name": "nomic-embed-text:latest"}]})

    monkeypatch.setattr("merlin.status_extension.request.urlopen", fake_urlopen)
    response = client.get("/status/models")
    body = response.json()

    assert response.status_code == 200
    assert body["state"] == "missing_chat_model"
    assert body["chat_ready"] is False
    assert body["embedding_ready"] is True
    assert body["embedding_only_installed"] is True
    assert "memory" in body["message"]
    assert body["safe_install_guidance"] == "bash scripts/add-model.sh qwen2.5:7b"
    assert body["downloads"] == "manual_only"


def test_status_models_reports_default_chat_model_ready(monkeypatch) -> None:
    def fake_urlopen(*args, **kwargs):
        return _FakeUrlOpenResponse({"models": [{"name": "qwen2.5:7b"}, {"name": "nomic-embed-text:latest"}]})

    monkeypatch.setattr("merlin.status_extension.request.urlopen", fake_urlopen)
    response = client.get("/status/models")
    body = response.json()

    assert response.status_code == 200
    assert body["state"] == "ready"
    assert body["chat_ready"] is True
    assert body["default_chat_ready"] is True
    assert any(model["alias"] == "qwen7b" and model["installed"] for model in body["chat_models"])


def test_status_models_degrades_without_ollama_tags(monkeypatch) -> None:
    def raise_unreachable(*args, **kwargs):
        raise OSError("ollama unavailable")

    monkeypatch.setattr("merlin.status_extension.request.urlopen", raise_unreachable)
    response = client.get("/status/models")
    body = response.json()

    assert response.status_code == 200
    assert body["state"] == "degraded"
    assert body["degraded"] is True
    assert body["chat_ready"] is False


def test_status_providers_returns_local_first_registry() -> None:
    response = client.get("/status/providers")
    assert response.status_code == 200
    body = response.json()
    assert body["mode"] == "local_only"
    assert body["local_first"] is True
    assert body["cloud_enabled"] is False
    assert body["external_providers_enabled"] is False
    assert body["allow_policy"] == "explicit_user_allow_required_for_external"
    assert body["allowed_count"] == 2
    assert body["blocked_count"] >= 6
    assert body["total"] >= 8


def test_status_providers_reports_local_ollama_and_litellm() -> None:
    response = client.get("/status/providers")
    providers = {provider["provider_id"]: provider for provider in response.json()["providers"]}
    assert providers["ollama"]["enabled"] is True
    assert providers["ollama"]["local"] is True
    assert providers["ollama"]["user_allowed"] is True
    assert providers["ollama"]["connection_state"] == "allowed_local"
    assert providers["ollama"]["api_family"] == "ollama_native"
    assert providers["ollama"]["setup_state"] == "allowed"
    assert providers["ollama"]["api_key_required"] is False
    assert "qwen7b" in providers["ollama"]["model_aliases"]
    assert providers["litellm"]["enabled"] is True
    assert providers["litellm"]["local"] is True
    assert providers["litellm"]["user_allowed"] is True
    assert providers["litellm"]["api_family"] == "openai_compatible_gateway"


def test_status_providers_includes_known_external_connector_catalog() -> None:
    response = client.get("/status/providers")
    providers = {provider["provider_id"]: provider for provider in response.json()["providers"]}

    for provider_id in ["openai", "anthropic", "perplexity", "google", "mistral", "openrouter"]:
        assert provider_id in providers
        provider = providers[provider_id]
        assert provider["enabled"] is False
        assert provider["user_allow_required"] is True
        assert provider["user_allowed"] is False
        assert provider["connection_state"] == "not_allowed"
        assert provider["setup_state"] == "locked_until_policy_flow"
        assert provider["known_model_examples"]
        assert provider["capabilities"]

    assert providers["openai"]["display_name"] == "ChatGPT / OpenAI"
    assert providers["openai"]["api_family"] == "openai_responses"
    assert "gpt-4o" in providers["openai"]["known_model_examples"]
    assert providers["anthropic"]["api_family"] == "anthropic_messages"
    assert providers["perplexity"]["api_family"] == "perplexity_sonar"
    assert providers["google"]["api_family"] == "gemini_generate_content"
    assert "gemini-2.5-pro" in providers["google"]["known_model_examples"]


def test_status_providers_external_cloud_disabled_even_when_key_present(monkeypatch) -> None:
    fake_key = "test-openai-key-value-that-must-never-be-returned"
    monkeypatch.setenv("OPENAI_API_KEY", fake_key)

    response = client.get("/status/providers")
    body_text = response.text
    providers = {provider["provider_id"]: provider for provider in response.json()["providers"]}

    assert providers["openai"]["enabled"] is False
    assert providers["openai"]["local"] is False
    assert providers["openai"]["user_allowed"] is False
    assert providers["openai"]["connection_state"] == "not_allowed"
    assert providers["openai"]["api_key_present"] is True
    assert providers["openai"]["credential_present"] is True
    assert providers["openai"]["requires_approval"] is True
    assert fake_key not in body_text


def test_status_providers_never_exposes_known_cloud_key_values(monkeypatch) -> None:
    secret_values = {
        "OPENAI_API_KEY": "openai-secret-value",
        "ANTHROPIC_API_KEY": "anthropic-secret-value",
        "PERPLEXITY_API_KEY": "perplexity-secret-value",
        "GOOGLE_API_KEY": "google-secret-value",
        "GEMINI_API_KEY": "gemini-secret-value",
        "MISTRAL_API_KEY": "mistral-secret-value",
        "OPENROUTER_API_KEY": "openrouter-secret-value",
    }
    for key, value in secret_values.items():
        monkeypatch.setenv(key, value)

    response_text = client.get("/status/providers").text

    for value in secret_values.values():
        assert value not in response_text


def test_status_settings_returns_policy_gated_manifest() -> None:
    response = client.get("/status/settings")
    body = response.json()

    assert response.status_code == 200
    assert body["mode"] == "policy_manifest"
    assert body["settings_writes_enabled"] is False
    assert body["browser_actions_enabled"] is False
    assert body["cloud_default"] is False
    assert body["secrets_displayed"] is False
    assert body["model_downloads"] == "manual_only"
    assert body["total"] == 6
    assert {action["action_id"] for action in body["actions"]} == {
        "provider_connectors",
        "model_library",
        "memory_controls",
        "privacy_sovereignty",
        "startup_apis",
        "backup_recovery",
    }


def test_status_settings_provider_connectors_are_locked_and_gate_secrets() -> None:
    response = client.get("/status/settings")
    actions = {action["action_id"]: action for action in response.json()["actions"]}
    provider = actions["provider_connectors"]

    assert provider["state"] == "locked"
    assert provider["allowed_from_dashboard"] is False
    assert provider["secrets_displayed"] is False
    assert provider["cloud_default"] is False
    assert {"api_key_use", "secret_access", "cloud_model_call", "external_network"} <= set(
        provider["approval_gates"]
    )
    assert all(gate["requires_approval"] for gate in provider["gates"])


def test_status_settings_never_exposes_secret_values(monkeypatch) -> None:
    monkeypatch.setenv("OPENAI_API_KEY", "openai-secret-value")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "anthropic-secret-value")

    response_text = client.get("/status/settings").text

    assert "openai-secret-value" not in response_text
    assert "anthropic-secret-value" not in response_text


def test_task_endpoint_allows_wizard_hq_cors_origin() -> None:
    response = client.options(
        "/task",
        headers={
            "Origin": "http://localhost:8888",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:8888"
    assert "POST" in response.headers["access-control-allow-methods"]


def test_task_endpoint_rejects_untrusted_cors_origin() -> None:
    response = client.options(
        "/task",
        headers={
            "Origin": "http://untrusted.example",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type",
        },
    )

    assert "access-control-allow-origin" not in response.headers


def test_task_endpoint_main_uses_8766_not_legacy_8765() -> None:
    source = task_endpoint.__loader__.get_source(task_endpoint.__name__)
    assert 'port=8766' in source
    assert 'port=8765' not in source
