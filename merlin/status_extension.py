"""Status API extension for the Merlin task endpoint app."""

from __future__ import annotations

import io
import json
from contextlib import redirect_stdout
from typing import Any
from urllib import error, request

from fastapi import APIRouter

from merlin.config_loader import load_all_configs
from merlin.provider_registry import build_provider_registry
from merlin.router import STAFF_ROUTE_RULES
from merlin.task_endpoint import TASK_TRACE_BUFFER, app


QDRANT_URL = "http://localhost:6333"
OLLAMA_TAGS_URL = "http://localhost:11434/api/tags"
router = APIRouter(prefix="/status")

SETTINGS_ACTIONS: list[dict[str, Any]] = [
    {
        "action_id": "provider_connectors",
        "category": "Provider Connectors",
        "state": "locked",
        "summary": "External provider setup is unavailable until safe secret storage and explicit allow/not-allow enablement exist.",
        "approval_gates": ["api_key_use", "secret_access", "cloud_model_call", "external_network"],
        "tracked_issue": "#117",
        "allowed_from_dashboard": False,
        "secrets_displayed": False,
        "cloud_default": False,
        "manual_guidance": "Use local models by default. External providers remain not allowed until a future policy-gated setup flow.",
    },
    {
        "action_id": "model_library",
        "category": "Model Library",
        "state": "guidance_only",
        "summary": "Model additions are manual-only and must include low-memory warnings.",
        "approval_gates": ["model_download"],
        "tracked_issue": "#115",
        "allowed_from_dashboard": False,
        "secrets_displayed": False,
        "cloud_default": False,
        "manual_guidance": "bash scripts/add-model.sh qwen2.5:7b",
    },
    {
        "action_id": "memory_controls",
        "category": "Memory Controls",
        "state": "blocked_by_issue",
        "summary": "Memory review and deletion stay locked until explicit approval and audit flows are complete.",
        "approval_gates": ["memory_write", "file_delete"],
        "tracked_issue": "#31 / #32",
        "allowed_from_dashboard": False,
        "secrets_displayed": False,
        "cloud_default": False,
        "manual_guidance": "Use existing CLI memory flows only after explicit approval.",
    },
    {
        "action_id": "privacy_sovereignty",
        "category": "Privacy & Sovereignty",
        "state": "read_only",
        "summary": "Local-only, cloud-disabled, and telemetry-off defaults are visible but not browser-toggleable.",
        "approval_gates": ["cloud_model_call", "external_network"],
        "tracked_issue": "#95",
        "allowed_from_dashboard": False,
        "secrets_displayed": False,
        "cloud_default": False,
        "manual_guidance": "Cloud remains off unless future explicit approval and provider setup are implemented.",
    },
    {
        "action_id": "startup_apis",
        "category": "Startup & APIs",
        "state": "guidance_only",
        "summary": "Startup and API persistence are managed by CLI/launchd, not browser execution.",
        "approval_gates": ["service_start", "service_stop"],
        "tracked_issue": "#116",
        "allowed_from_dashboard": False,
        "secrets_displayed": False,
        "cloud_default": False,
        "manual_guidance": "bash launchd/install-launchd.sh",
    },
    {
        "action_id": "backup_recovery",
        "category": "Backup & Recovery",
        "state": "guidance_only",
        "summary": "Backup, upgrade, uninstall, and restore stay CLI-led until policy-gated browser workflows exist.",
        "approval_gates": ["file_read", "file_write", "file_delete", "service_stop"],
        "tracked_issue": "#37",
        "allowed_from_dashboard": False,
        "secrets_displayed": False,
        "cloud_default": False,
        "manual_guidance": "Use documented CLI backup, upgrade, and uninstall commands.",
    },
]


def _load_config_quietly():
    with redirect_stdout(io.StringIO()):
        return load_all_configs()


def _staff_mode_for_route(route_id: str) -> str:
    for rule in STAFF_ROUTE_RULES:
        if rule.route_id == route_id:
            return rule.staff_mode
    return "operator"


def _keywords_for_route(route_id: str) -> list[str]:
    keywords: list[str] = []
    for rule in STAFF_ROUTE_RULES:
        if rule.route_id == route_id:
            keywords.extend(rule.keywords)
    return sorted(set(keywords))


@router.get("/routes")
def status_routes() -> dict[str, Any]:
    config = _load_config_quietly()
    routes = []
    for route_id, route in config.routes.routes.items():
        routes.append(
            {
                "route_id": route_id,
                "staff_mode": _staff_mode_for_route(route_id),
                "keywords": _keywords_for_route(route_id),
                "requires_approval": bool(route.approval_gates),
                "approval_gates": list(route.approval_gates),
                "preferred_model_alias": route.preferred_model_alias,
            }
        )
    return {"routes": routes, "total": len(routes)}


@router.get("/approvals")
def status_approvals() -> dict[str, Any]:
    config = _load_config_quietly()
    gates = [
        {
            "gate_name": gate_name,
            "requires_approval": gate.requires_approval,
            "risk_tier": gate.risk,
        }
        for gate_name, gate in config.policy.approval_gates.items()
    ]
    closed_count = sum(1 for gate in gates if gate["requires_approval"])
    open_count = len(gates) - closed_count
    return {"gates": gates, "total": len(gates), "open_count": open_count, "closed_count": closed_count}


@router.get("/traces")
def status_traces() -> dict[str, Any]:
    traces = list(TASK_TRACE_BUFFER)
    return {"traces": traces, "total_recorded": len(traces)}


def _collection_manifest() -> dict[str, int]:
    config = _load_config_quietly()
    manifest: dict[str, int] = {}
    for name, collection in config.memory.canonical.items():
        manifest[name] = collection.vector_size
    for name, collection in config.memory.legacy.items():
        manifest[name] = collection.vector_size
    return manifest


def _qdrant_collection(name: str) -> dict[str, Any]:
    req = request.Request(f"{QDRANT_URL}/collections/{name}", method="GET")
    with request.urlopen(req, timeout=2) as response:
        return json.loads(response.read().decode("utf-8"))


def _ollama_tags() -> set[str]:
    req = request.Request(OLLAMA_TAGS_URL, method="GET")
    with request.urlopen(req, timeout=2) as response:
        data = json.loads(response.read().decode("utf-8"))
    models = data.get("models", [])
    installed: set[str] = set()
    for model in models if isinstance(models, list) else []:
        if not isinstance(model, dict):
            continue
        name = model.get("name")
        if not isinstance(name, str) or not name:
            continue
        installed.add(name)
        if ":" in name:
            installed.add(name.split(":", 1)[0])
    return installed


@router.get("/memory")
def status_memory() -> dict[str, Any]:
    manifest = _collection_manifest()
    collections = []
    degraded = False
    total_vectors = 0

    for name, dimensions in manifest.items():
        vector_count = 0
        status = "unknown"
        try:
            response = _qdrant_collection(name)
            result = response.get("result", {})
            vector_count = int(result.get("vectors_count") or result.get("points_count") or 0)
            status = str(result.get("status") or "ok")
        except (OSError, TimeoutError, error.URLError, json.JSONDecodeError):
            degraded = True
            status = "degraded"
        collections.append(
            {
                "name": name,
                "vector_count": vector_count,
                "dimensions": dimensions,
                "status": status,
            }
        )
        total_vectors += vector_count

    if degraded:
        total_vectors = 0
        for collection in collections:
            collection["vector_count"] = 0
            collection["status"] = "degraded"

    return {"collections": collections, "total_vectors": total_vectors, "degraded": degraded}


@router.get("/models")
def status_models() -> dict[str, Any]:
    config = _load_config_quietly()
    default_chat_alias = config.models.defaults.default_chat_model
    default_embedding_alias = config.models.defaults.default_embedding_model

    try:
        installed_models = _ollama_tags()
        degraded = False
    except (OSError, TimeoutError, error.URLError, json.JSONDecodeError):
        installed_models = set()
        degraded = True

    local_models = []
    chat_models = []
    embedding_models = []
    for alias, model in config.models.models.items():
        if model.provider != "ollama" or not model.local:
            continue
        installed = model.model in installed_models
        record = {
            "alias": alias,
            "model": model.model,
            "model_class": model.model_class,
            "installed": installed,
            "enabled_by_default": model.enabled_by_default,
            "default_chat": alias == default_chat_alias,
            "default_embedding": alias == default_embedding_alias,
            "install_command": f"bash scripts/add-model.sh {model.model}",
        }
        local_models.append(record)
        if model.model_class == "embedding":
            embedding_models.append(record)
        else:
            chat_models.append(record)

    chat_ready = any(model["installed"] for model in chat_models)
    default_chat_ready = any(model["default_chat"] and model["installed"] for model in chat_models)
    embedding_ready = any(model["installed"] for model in embedding_models)
    embedding_only_installed = embedding_ready and not chat_ready

    if degraded:
        state = "degraded"
        message = "Ollama model list is unavailable. Merlin cannot verify local chat model readiness yet."
    elif default_chat_ready:
        state = "ready"
        message = "Default local chat model is installed. Merlin Chat can use the local brain connector."
    elif chat_ready:
        state = "partial"
        message = "A local chat model is installed, but the configured default chat model is missing."
    elif embedding_only_installed:
        state = "missing_chat_model"
        message = "Only the embedding memory model is installed. nomic-embed-text supports memory, not chat."
    else:
        state = "missing_chat_model"
        message = "No local chat model is installed. Merlin needs an explicit user-installed chat model."

    return {
        "state": state,
        "message": message,
        "degraded": degraded,
        "chat_ready": chat_ready,
        "default_chat_ready": default_chat_ready,
        "embedding_ready": embedding_ready,
        "embedding_only_installed": embedding_only_installed,
        "default_chat_alias": default_chat_alias,
        "default_embedding_alias": default_embedding_alias,
        "installed_models": sorted(installed_models),
        "chat_models": chat_models,
        "embedding_models": embedding_models,
        "local_models": local_models,
        "safe_install_guidance": f"bash scripts/add-model.sh {config.models.models[default_chat_alias].model}",
        "downloads": "manual_only",
    }


@router.get("/providers")
def status_providers() -> dict[str, Any]:
    registry = build_provider_registry()
    providers = [provider.model_dump() for provider in registry.providers]
    for provider in providers:
        provider["credential_present"] = provider["api_key_present"]
    allowed_count = sum(1 for provider in providers if provider["user_allowed"])
    blocked_count = len(providers) - allowed_count
    return {
        "mode": registry.mode,
        "local_first": registry.local_first,
        "cloud_enabled": registry.cloud_enabled,
        "external_providers_enabled": registry.external_providers_enabled,
        "allow_policy": "explicit_user_allow_required_for_external",
        "allowed_count": allowed_count,
        "blocked_count": blocked_count,
        "providers": providers,
        "total": len(providers),
    }


@router.get("/settings")
def status_settings() -> dict[str, Any]:
    config = _load_config_quietly()
    gates_by_name = config.policy.approval_gates
    actions = []
    for action in SETTINGS_ACTIONS:
        gates = []
        for gate_name in action["approval_gates"]:
            gate = gates_by_name.get(gate_name)
            gates.append(
                {
                    "gate_name": gate_name,
                    "requires_approval": True if gate is None else gate.requires_approval,
                    "risk_tier": "unknown" if gate is None else gate.risk,
                    "reason": "Policy gate is not defined." if gate is None else gate.reason,
                }
            )
        actions.append({**action, "gates": gates})

    return {
        "mode": "policy_manifest",
        "settings_writes_enabled": False,
        "browser_actions_enabled": False,
        "cloud_default": False,
        "secrets_displayed": False,
        "model_downloads": "manual_only",
        "actions": actions,
        "total": len(actions),
    }


app.include_router(router)
