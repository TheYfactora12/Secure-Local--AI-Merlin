"""Status API extension for the Merlin task endpoint app."""

from __future__ import annotations

import io
import json
from contextlib import redirect_stdout
from typing import Any
from urllib import error, request

from fastapi import APIRouter

from merlin.config_loader import load_all_configs
from merlin.router import STAFF_ROUTE_RULES
from merlin.task_endpoint import TASK_TRACE_BUFFER, app


QDRANT_URL = "http://localhost:6333"
router = APIRouter(prefix="/status")


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


app.include_router(router)
