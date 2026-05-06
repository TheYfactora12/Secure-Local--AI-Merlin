"""FastAPI task endpoint for Merlin Phase 2E."""

from __future__ import annotations

import hashlib
import logging
import uuid
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from merlin.memory_manager import MemoryManager
from merlin.persona_injector import build_system_prompt
from merlin.policy_engine import ApprovalRequiredError, requires_approval
from merlin.router import RouteDecision, route_task


logger = logging.getLogger(__name__)

LITELLM_CHAT_COMPLETIONS_URL = "http://localhost:4000/v1/chat/completions"
LITELLM_TIMEOUT_SECONDS = 90

app = FastAPI(title="Merlin Task Endpoint")


class TaskRequest(BaseModel):
    input: str
    session_id: str | None = None


class TaskResponse(BaseModel):
    response: str
    route: dict[str, Any]
    approved: bool
    session_id: str
    memory_written: bool
    degraded: bool = False


def _input_hash(user_input: str) -> str:
    return hashlib.sha256(user_input.encode("utf-8")).hexdigest()


def _validate_user_input(user_input: str) -> str:
    stripped = user_input.strip()
    if not stripped:
        raise HTTPException(status_code=400, detail="input must not be empty")
    if len(stripped) > 4000:
        raise HTTPException(status_code=400, detail="input must be 4000 characters or fewer")
    return stripped


def _route_or_block(user_input: str) -> RouteDecision:
    decision = route_task(user_input)
    if decision.requires_approval:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Approval required before Merlin can continue this route.",
                "route_id": decision.route_id,
                "approval_gates": decision.approval_gates,
            },
        )
    return decision


def _call_litellm(system_prompt: str, user_input: str, model: str) -> str:
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input},
        ],
        "stream": False,
    }
    response = httpx.post(LITELLM_CHAT_COMPLETIONS_URL, json=payload, timeout=LITELLM_TIMEOUT_SECONDS)
    response.raise_for_status()
    data = response.json()
    return str(data["choices"][0]["message"]["content"])


def _memory_write_allowed() -> bool:
    @requires_approval("memory_write")
    def allowed() -> bool:
        return True

    return allowed()


def _write_session_memory(session_id: str, user_input: str, merlin_response: str, route: RouteDecision) -> bool:
    try:
        _memory_write_allowed()
    except ApprovalRequiredError:
        logger.info("Memory write skipped: approval_required route_id=%s session_id=%s", route.route_id, session_id)
        return False

    try:
        manager = MemoryManager()
        point_id = manager.write(
            "merlin-session",
            f"User: {user_input}\nMerlin: {merlin_response}",
            {"session_id": session_id, "route_id": route.route_id, "staff_mode": route.staff_mode},
        )
    except Exception as exc:
        logger.warning("Memory write failed: route_id=%s session_id=%s error=%s", route.route_id, session_id, exc)
        return False
    return point_id is not None


@app.post("/task", response_model=TaskResponse)
def task(request: TaskRequest) -> TaskResponse:
    user_input = _validate_user_input(request.input)
    session_id = request.session_id or str(uuid.uuid4())
    logger.info("Task request received: input_hash=%s session_id=%s", _input_hash(user_input), session_id)

    route = _route_or_block(user_input)
    system_prompt = build_system_prompt(route)

    try:
        response_text = _call_litellm(system_prompt, user_input, route.selected_model_alias)
    except (httpx.ConnectError, httpx.TimeoutException, httpx.HTTPError, OSError):
        logger.warning("LiteLLM unavailable: input_hash=%s route_id=%s", _input_hash(user_input), route.route_id)
        return TaskResponse(
            response="Merlin is starting up. Try again in 30 seconds.",
            route={},
            approved=False,
            session_id=session_id,
            memory_written=False,
            degraded=True,
        )

    memory_written = False
    if request.session_id:
        memory_written = _write_session_memory(session_id, user_input, response_text, route)

    return TaskResponse(
        response=response_text,
        route=route.model_dump(),
        approved=True,
        session_id=session_id,
        memory_written=memory_written,
    )
