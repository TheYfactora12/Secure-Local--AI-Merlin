"""Static validation for the Merlin n8n session memory bridge.

No live n8n, Qdrant, Ollama, or model download is required.
"""

from __future__ import annotations

import json
import pathlib
from typing import Any

import pytest


WORKFLOW_PATH = pathlib.Path("n8n-workflows/06-session-memory-bridge.json")


@pytest.fixture(scope="module")
def workflow() -> dict[str, Any]:
    assert WORKFLOW_PATH.exists(), f"Workflow file missing: {WORKFLOW_PATH}"
    with WORKFLOW_PATH.open(encoding="utf-8") as handle:
        return json.load(handle)


@pytest.fixture(scope="module")
def nodes(workflow: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {node["id"]: node for node in workflow["nodes"]}


@pytest.fixture(scope="module")
def node_names(workflow: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {node["name"]: node for node in workflow["nodes"]}


def _workflow_text(workflow: dict[str, Any]) -> str:
    return json.dumps(workflow)


def _http_nodes(workflow: dict[str, Any]) -> list[dict[str, Any]]:
    return [node for node in workflow["nodes"] if node["type"] == "n8n-nodes-base.httpRequest"]


def test_workflow_file_exists() -> None:
    assert WORKFLOW_PATH.exists()


def test_workflow_has_required_keys(workflow: dict[str, Any]) -> None:
    for key in ["name", "nodes", "connections", "active", "settings", "tags"]:
        assert key in workflow


def test_workflow_is_inactive_by_default(workflow: dict[str, Any]) -> None:
    assert workflow["active"] is False


def test_webhook_node_exists(workflow: dict[str, Any]) -> None:
    assert any(node["type"] == "n8n-nodes-base.webhook" for node in workflow["nodes"])


def test_webhook_path_is_session(node_names: dict[str, dict[str, Any]]) -> None:
    webhook = node_names["Session Memory Webhook"]
    assert "session/memory" in webhook["parameters"]["path"]


def test_collection_name_is_merlin_session(workflow: dict[str, Any]) -> None:
    qdrant_nodes = [node for node in _http_nodes(workflow) if "qdrant" in node["parameters"].get("url", "")]
    assert qdrant_nodes
    for node in qdrant_nodes:
        assert "/collections/merlin_session" in node["parameters"]["url"]


def test_no_swarm_memory_collection_refs(workflow: dict[str, Any]) -> None:
    assert "swarm_memory" not in _workflow_text(workflow)


def test_embedding_model_is_nomic(workflow: dict[str, Any]) -> None:
    assert "nomic-embed-text" in _workflow_text(workflow)


def test_vector_size_is_768(workflow: dict[str, Any]) -> None:
    ensure_nodes = [
        node
        for node in _http_nodes(workflow)
        if node["parameters"].get("method") == "PUT" and "merlin_session" in node["parameters"].get("url", "")
    ]
    assert ensure_nodes
    assert all('"size":768' in node["parameters"].get("jsonBody", "") for node in ensure_nodes)


def test_ollama_url_is_local(workflow: dict[str, Any]) -> None:
    ollama_urls = [
        node["parameters"].get("url", "")
        for node in _http_nodes(workflow)
        if "api/embeddings" in node["parameters"].get("url", "")
    ]
    assert ollama_urls
    assert all(url.startswith(("http://ollama:", "http://localhost:11434")) for url in ollama_urls)
    assert "api.openai.com" not in _workflow_text(workflow)


def test_qdrant_url_is_local(workflow: dict[str, Any]) -> None:
    qdrant_urls = [
        node["parameters"].get("url", "")
        for node in _http_nodes(workflow)
        if "collections" in node["parameters"].get("url", "")
    ]
    assert qdrant_urls
    assert all(url.startswith(("http://qdrant:", "http://localhost:6333")) for url in qdrant_urls)


def test_approval_gate_present_in_js(node_names: dict[str, dict[str, Any]]) -> None:
    code = node_names["Validate + Gate Check"]["parameters"]["jsCode"]
    assert "approved_by" in code
    assert "user_explicit" in code
    assert "memory_write gate" in code


def test_continue_on_fail_qdrant_nodes(workflow: dict[str, Any]) -> None:
    qdrant_nodes = [node for node in _http_nodes(workflow) if "qdrant" in node["parameters"].get("url", "")]
    assert qdrant_nodes
    assert all(node.get("continueOnFail") is True for node in qdrant_nodes)


def test_connections_are_complete(workflow: dict[str, Any]) -> None:
    connections = workflow["connections"]
    respond_sources = {"Upsert to merlin_session", "Query merlin_session"}
    source_nodes = set(connections)
    for node in workflow["nodes"]:
        if node["name"] == "Respond":
            continue
        if node["name"] in respond_sources:
            assert node["name"] in source_nodes
            continue
        assert node["name"] in source_nodes


def test_tags_include_msc4(workflow: dict[str, Any]) -> None:
    tags = {tag["name"] for tag in workflow["tags"]}
    assert {"msc-4", "phase-2e"} & tags


def test_no_raw_secrets_in_json(workflow: dict[str, Any]) -> None:
    serialized = _workflow_text(workflow).casefold()
    for forbidden in ["api_key", "token", "password", "secret"]:
        assert forbidden not in serialized
