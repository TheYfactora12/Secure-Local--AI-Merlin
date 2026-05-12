"""FastAPI task endpoint for Merlin Phase 2E."""

from __future__ import annotations

import hashlib
import logging
import os
import time
import uuid
from collections import deque
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from merlin.approval_store import (
    ApprovalRecord,
    create_room_archive_approval,
    create_room_delete_approval,
    create_room_master_prompt_approval,
    create_room_restore_approval,
    create_room_transcript_delete_approval,
    create_room_transcript_read_approval,
    create_room_transcript_approval,
    create_task_route_approval,
    decide_approval,
    mark_approval_used,
    require_room_archive_approval,
    require_room_delete_approval,
    require_room_master_prompt_approval,
    require_room_restore_approval,
    require_room_transcript_delete_approval,
    require_room_transcript_read_approval,
    require_room_transcript_approval,
    require_task_route_approval,
)
from merlin.memory_manager import MemoryManager
from merlin.outcome_observer import observe_task_outcome
from merlin.persona_injector import build_system_prompt
from merlin.policy_engine import ApprovalRequiredError, requires_approval
from merlin.room_store import (
    RoomArchiveResult,
    RoomCreateResult,
    RoomDeleteResult,
    RoomMasterPromptDraftResult,
    RoomRestoreResult,
    RoomTranscriptDeleteResult,
    RoomTranscriptReadResult,
    RoomTranscriptSaveResult,
    archive_room,
    count_room_transcripts,
    create_room,
    delete_room_transcript,
    delete_room,
    generate_room_master_prompt_draft,
    list_archived_rooms,
    read_room_transcript,
    room_archive_preview,
    restore_archived_room,
    save_room_transcript,
)
from merlin.router import RouteDecision, route_task


logger = logging.getLogger(__name__)

UTC = timezone.utc

LITELLM_CHAT_COMPLETIONS_URL = "http://localhost:4000/v1/chat/completions"
LITELLM_TIMEOUT_SECONDS = 90
MAX_CONTEXT_MESSAGES = 8
MAX_CONTEXT_MESSAGE_CHARS = 1200
STACK_DIR = Path(__file__).resolve().parents[1]

app = FastAPI(title="Merlin Task Endpoint")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8888", "http://127.0.0.1:8888"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)
TASK_TRACE_BUFFER: deque[dict[str, Any]] = deque(maxlen=50)


class ChatContextMessage(BaseModel):
    role: str
    content: str


class TaskRequest(BaseModel):
    input: str
    session_id: str | None = None
    approval_id: str | None = None
    model_only: bool = False
    context_messages: list[ChatContextMessage] = Field(default_factory=list)


class TaskResponse(BaseModel):
    response: str
    route: dict[str, Any]
    approved: bool
    session_id: str
    memory_written: bool
    degraded: bool = False


class RoomTranscriptSaveRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    user_input: str
    merlin_response: str
    session_id: str
    approval_id: str | None = None


class RoomCreateRequest(BaseModel):
    room_name: str


class RoomCreateResponse(BaseModel):
    status: str
    room_id: str
    room_name: str
    room_path: str
    metadata_file: str
    created_at: str
    audit_id: str | None
    memory_written: bool
    context_reuse: str


class RoomTranscriptSaveResponse(BaseModel):
    status: str
    room_id: str
    transcript_id: str
    transcript_title: str
    transcript_path: str
    audit_id: str | None
    memory_written: bool
    memory_extraction: str


class RoomTranscriptApprovalRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    user_input: str
    merlin_response: str
    session_id: str


class RoomTranscriptReadApprovalRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    transcript_id: str


class RoomTranscriptDeleteApprovalRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    transcript_id: str


class RoomArchiveApprovalRequest(BaseModel):
    room_id: str
    room_name: str | None = None


class RoomDeleteApprovalRequest(BaseModel):
    room_id: str
    room_name: str | None = None


class RoomRestoreApprovalRequest(BaseModel):
    archive_id: str


class RoomTranscriptApprovalResponse(BaseModel):
    approval_request_id: str
    status: str
    action: str
    approval_gates: list[str]
    execution_allowed: bool
    payload_hash: str
    payload_summary: dict[str, Any]


class TaskRouteApprovalRequest(BaseModel):
    input: str
    session_id: str | None = None


class TaskRouteApprovalResponse(BaseModel):
    approval_request_id: str
    status: str
    action: str
    approval_gates: list[str]
    execution_allowed: bool
    payload_hash: str
    payload_summary: dict[str, Any]
    route: dict[str, Any]


class RoomMasterPromptApprovalRequest(BaseModel):
    room_id: str
    room_name: str | None = None


class RoomMasterPromptDraftRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    source_transcript_count: int
    approval_id: str | None = None


class RoomMasterPromptDraftResponse(BaseModel):
    status: str
    room_id: str
    room_name: str
    master_prompt_path: str
    audit_id: str | None
    source_transcript_count: int
    memory_written: bool
    approved_for_context: bool
    context_reuse: str


class RoomTranscriptReadRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    transcript_id: str
    approval_id: str | None = None


class RoomTranscriptReadResponse(BaseModel):
    status: str
    room_id: str
    room_name: str
    transcript_id: str
    user_input: str
    merlin_response: str
    memory_written: bool
    context_reuse: str
    raw_content_loaded: bool
    audit_id: str | None


class RoomTranscriptDeleteRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    transcript_id: str
    approval_id: str | None = None


class RoomTranscriptDeleteResponse(BaseModel):
    status: str
    room_id: str
    room_name: str
    transcript_id: str
    deleted_at: str
    memory_written: bool
    context_reuse: str
    audit_id: str | None


class RoomArchiveRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    transcript_count: int
    summary_count: int
    master_prompt_status: str
    approval_id: str | None = None


class RoomArchiveResponse(BaseModel):
    status: str
    room_id: str
    room_name: str
    archived_room_path: str
    archived_at: str
    transcript_count: int
    summary_count: int
    master_prompt_status: str
    linked_memory_review: str
    memory_written: bool
    approved_memory_deleted: bool
    context_reuse: str
    audit_id: str | None


class RoomDeleteRequest(BaseModel):
    room_id: str
    room_name: str | None = None
    transcript_count: int
    summary_count: int
    master_prompt_status: str
    approval_id: str | None = None


class RoomDeleteResponse(BaseModel):
    status: str
    room_id: str
    room_name: str
    deleted_room_path: str
    deleted_at: str
    transcript_count: int
    summary_count: int
    master_prompt_status: str
    linked_memory_review: str
    memory_written: bool
    approved_memory_deleted: bool
    context_reuse: str
    audit_id: str | None


class RoomRestoreRequest(BaseModel):
    archive_id: str
    room_id: str
    room_name: str | None = None
    transcript_count: int
    summary_count: int
    master_prompt_status: str
    approval_id: str | None = None


class RoomRestoreResponse(BaseModel):
    status: str
    archive_id: str
    room_id: str
    room_name: str
    restored_room_path: str
    restored_at: str
    transcript_count: int
    summary_count: int
    master_prompt_status: str
    memory_written: bool
    approved_memory_restored: bool
    context_reuse: str
    audit_id: str | None


class ApprovalDecisionResponse(BaseModel):
    approval_request_id: str
    status: str
    action: str
    execution_allowed: bool
    decision_recorded: bool


def _approval_response(record: ApprovalRecord) -> RoomTranscriptApprovalResponse:
    return RoomTranscriptApprovalResponse(
        approval_request_id=record.approval_request_id,
        status=record.status,
        action=record.action,
        approval_gates=record.approval_gates,
        execution_allowed=record.execution_allowed,
        payload_hash=record.payload_hash,
        payload_summary=record.payload_summary,
    )


def _task_route_approval_response(record: ApprovalRecord, route: RouteDecision) -> TaskRouteApprovalResponse:
    return TaskRouteApprovalResponse(
        approval_request_id=record.approval_request_id,
        status=record.status,
        action=record.action,
        approval_gates=record.approval_gates,
        execution_allowed=record.execution_allowed,
        payload_hash=record.payload_hash,
        payload_summary=record.payload_summary,
        route=route.model_dump(),
    )


def _decision_response(record: ApprovalRecord) -> ApprovalDecisionResponse:
    return ApprovalDecisionResponse(
        approval_request_id=record.approval_request_id,
        status=record.status,
        action=record.action,
        execution_allowed=record.execution_allowed,
        decision_recorded=record.decision_recorded,
    )


def _room_create_response(result: RoomCreateResult, audit_id: str | None) -> RoomCreateResponse:
    return RoomCreateResponse(
        status="created_local_room_only",
        room_id=result.room_id,
        room_name=result.room_name,
        room_path=result.room_path,
        metadata_file=result.metadata_file,
        created_at=result.created_at,
        audit_id=audit_id,
        memory_written=False,
        context_reuse="disabled_until_user_approved",
    )


def _input_hash(user_input: str) -> str:
    return hashlib.sha256(user_input.encode("utf-8")).hexdigest()


def record_task_trace(
    *,
    input_hash: str,
    session_id: str,
    route: RouteDecision,
    approved: bool,
    memory_written: bool,
    degraded: bool,
    latency_ms: int,
) -> None:
    TASK_TRACE_BUFFER.append(
        {
            "timestamp": datetime.now(UTC).isoformat(),
            "input_hash": input_hash,
            "session_id": session_id,
            "route_id": route.route_id,
            "staff_mode": route.staff_mode,
            "approved": approved,
            "memory_written": memory_written,
            "degraded": degraded,
            "latency_ms": max(1, latency_ms),
        }
    )


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


def _bounded_context_messages(context_messages: list[ChatContextMessage]) -> list[dict[str, str]]:
    bounded: list[dict[str, str]] = []
    for message in context_messages[-MAX_CONTEXT_MESSAGES:]:
        role = message.role.strip().lower()
        if role not in {"user", "assistant"}:
            continue
        content = message.content.strip()
        if not content:
            continue
        bounded.append(
            {
                "role": role,
                "content": content[:MAX_CONTEXT_MESSAGE_CHARS],
            }
        )
    return bounded


def _call_litellm(
    system_prompt: str,
    user_input: str,
    model: str,
    context_messages: list[ChatContextMessage] | None = None,
) -> str:
    messages = [
        {"role": "system", "content": system_prompt},
        *_bounded_context_messages(context_messages or []),
        {"role": "user", "content": user_input},
    ]
    payload = {
        "model": model,
        "messages": messages,
        "stream": False,
    }
    response = httpx.post(
        LITELLM_CHAT_COMPLETIONS_URL,
        json=payload,
        headers=_litellm_headers(),
        timeout=LITELLM_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    data = response.json()
    return str(data["choices"][0]["message"]["content"])


def _litellm_headers() -> dict[str, str]:
    key = os.environ.get("LITELLM_MASTER_KEY") or _env_file_value("LITELLM_MASTER_KEY")
    if not key:
        return {}
    return {"Authorization": f"Bearer {key}"}


def _env_file_value(key: str) -> str | None:
    env_file = STACK_DIR / ".env"
    try:
        with env_file.open("r", encoding="utf-8") as handle:
            for line in handle:
                stripped = line.strip()
                if not stripped or stripped.startswith("#") or "=" not in stripped:
                    continue
                name, value = stripped.split("=", 1)
                if name == key:
                    return value.strip().strip('"').strip("'") or None
    except OSError:
        return None
    return None


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


def _write_room_transcript_audit(result: RoomTranscriptSaveResult, request: RoomTranscriptSaveRequest) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "transcript_id": result.transcript_id,
        "transcript_path": result.transcript_path,
        "metadata_file": result.metadata_file,
        "session_id": request.session_id,
        "approval_id": result.approval_id,
        "created_at": result.created_at,
        "bytes_written": result.bytes_written,
        "user_input_hash": _input_hash(request.user_input),
        "merlin_response_hash": _input_hash(request.merlin_response),
        "memory_extraction": result.memory_extraction,
        "approved_memory_written": result.approved_memory_written,
        "cloud_sync_default": False,
        "raw_transcript_in_audit": False,
    }
    try:
        return MemoryManager().write_audit_event("room_transcript_save", metadata)
    except Exception:
        return None


def _write_room_create_audit(result: RoomCreateResult) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "room_path": result.room_path,
        "metadata_file": result.metadata_file,
        "created_at": result.created_at,
        "memory_written": False,
        "context_reuse": "disabled_until_user_approved",
        "cloud_sync_default": False,
        "raw_transcript_in_audit": False,
    }
    try:
        return MemoryManager().write_audit_event("room_create", metadata)
    except Exception:
        return None


def _write_room_master_prompt_audit(
    result: RoomMasterPromptDraftResult,
    request: RoomMasterPromptDraftRequest,
) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "master_prompt_path": result.master_prompt_path,
        "approval_id": result.approval_id,
        "generated_at": result.generated_at,
        "source_transcript_count": result.source_transcript_count,
        "requested_source_transcript_count": request.source_transcript_count,
        "bytes_written": result.bytes_written,
        "approved_for_context": result.approved_for_context,
        "memory_written": result.memory_written,
        "context_reuse": "disabled_until_user_approved",
        "raw_prompt_in_audit": False,
        "raw_transcript_in_audit": False,
        "cloud_sync_default": False,
    }
    try:
        return MemoryManager().write_audit_event("room_master_prompt_draft", metadata)
    except Exception:
        return None


def _write_room_transcript_read_audit(
    result: RoomTranscriptReadResult,
    request: RoomTranscriptReadRequest,
) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "transcript_id": result.transcript_id,
        "transcript_path": result.transcript_path,
        "approval_id": request.approval_id,
        "size_bytes": result.size_bytes,
        "modified_at": result.modified_at,
        "memory_written": False,
        "context_reuse": result.context_reuse,
        "raw_transcript_in_audit": False,
        "cloud_sync_default": False,
    }
    try:
        return MemoryManager().write_audit_event("room_transcript_read", metadata)
    except Exception:
        return None


def _write_room_transcript_delete_audit(
    result: RoomTranscriptDeleteResult,
    request: RoomTranscriptDeleteRequest,
) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "transcript_id": result.transcript_id,
        "transcript_path": result.transcript_path,
        "approval_id": result.approval_id,
        "deleted_at": result.deleted_at,
        "memory_written": False,
        "context_reuse": result.context_reuse,
        "raw_transcript_in_audit": False,
        "cloud_sync_default": False,
    }
    try:
        return MemoryManager().write_audit_event("room_transcript_delete", metadata)
    except Exception:
        return None


def _write_room_archive_audit(
    result: RoomArchiveResult,
    request: RoomArchiveRequest,
) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "original_room_path": result.original_room_path,
        "archived_room_path": result.archived_room_path,
        "approval_id": result.approval_id,
        "archived_at": result.archived_at,
        "transcript_count": result.transcript_count,
        "summary_count": result.summary_count,
        "master_prompt_status": result.master_prompt_status,
        "requested_transcript_count": request.transcript_count,
        "requested_summary_count": request.summary_count,
        "requested_master_prompt_status": request.master_prompt_status,
        "linked_memory_review": result.linked_memory_review,
        "memory_written": False,
        "approved_memory_deleted": False,
        "context_reuse": result.context_reuse,
        "raw_transcript_in_audit": False,
        "raw_master_prompt_in_audit": False,
        "cloud_sync_default": False,
    }
    try:
        return MemoryManager().write_audit_event("room_archive", metadata)
    except Exception:
        return None


def _write_room_delete_audit(
    result: RoomDeleteResult,
    request: RoomDeleteRequest,
) -> str | None:
    metadata = {
        "room_id": result.room_id,
        "room_name": result.room_name,
        "deleted_room_path": result.deleted_room_path,
        "approval_id": result.approval_id,
        "deleted_at": result.deleted_at,
        "transcript_count": result.transcript_count,
        "summary_count": result.summary_count,
        "master_prompt_status": result.master_prompt_status,
        "requested_transcript_count": request.transcript_count,
        "requested_summary_count": request.summary_count,
        "requested_master_prompt_status": request.master_prompt_status,
        "memory_written": False,
        "approved_memory_deleted": False,
        "context_reuse": result.context_reuse,
        "linked_memory_review": result.linked_memory_review,
        "raw_transcript_in_audit": False,
        "raw_master_prompt_in_audit": False,
        "cloud_sync_default": False,
    }
    try:
        return MemoryManager().write_audit_event("room_delete", metadata)
    except Exception:
        return None


def _archived_room_by_id(archive_id: str):
    safe_archive_id = archive_id.strip()
    for record in list_archived_rooms():
        if record.archive_id == safe_archive_id:
            return record
    raise FileNotFoundError("Archived Room not found")


def _write_room_restore_audit(
    result: RoomRestoreResult,
    request: RoomRestoreRequest,
) -> str | None:
    metadata = {
        "archive_id": result.archive_id,
        "room_id": result.room_id,
        "room_name": result.room_name,
        "restored_room_path": result.restored_room_path,
        "approval_id": result.approval_id,
        "restored_at": result.restored_at,
        "transcript_count": result.transcript_count,
        "summary_count": result.summary_count,
        "master_prompt_status": result.master_prompt_status,
        "requested_transcript_count": request.transcript_count,
        "requested_summary_count": request.summary_count,
        "requested_master_prompt_status": request.master_prompt_status,
        "memory_written": False,
        "approved_memory_restored": False,
        "context_reuse": result.context_reuse,
        "raw_transcript_in_audit": False,
        "raw_master_prompt_in_audit": False,
        "cloud_sync_default": False,
    }
    try:
        return MemoryManager().write_audit_event("room_restore", metadata)
    except Exception:
        return None


@app.post("/task", response_model=TaskResponse)
def task(request: TaskRequest) -> TaskResponse:
    started = time.perf_counter()
    user_input = _validate_user_input(request.input)
    session_id = request.session_id or str(uuid.uuid4())
    input_hash = _input_hash(user_input)
    logger.info("Task request received: input_hash=%s session_id=%s", input_hash, session_id)

    route = route_task(user_input)
    route_approved_by_id = False
    approval_id = (request.approval_id or "").strip()
    if route.requires_approval and not request.model_only:
        if approval_id:
            try:
                require_task_route_approval(
                    approval_id=approval_id,
                    user_input=user_input,
                    session_id=session_id,
                    route_id=route.route_id,
                    staff_mode=route.staff_mode,
                    selected_model_alias=route.selected_model_alias,
                )
            except PermissionError as exc:
                raise HTTPException(
                    status_code=403,
                    detail={
                        "message": str(exc),
                        "route_id": route.route_id,
                        "route": route.model_dump(),
                        "approval_gates": route.approval_gates,
                        "approval_supported": True,
                        "approval_scope": "one_time_local_model_call",
                        "session_id": session_id,
                    },
                ) from exc
            route_approved_by_id = True
        else:
            latency_ms = int((time.perf_counter() - started) * 1000)
            record_task_trace(
                input_hash=input_hash,
                session_id=session_id,
                route=route,
                approved=False,
                memory_written=False,
                degraded=False,
                latency_ms=latency_ms,
            )
            observe_task_outcome(
                user_input=user_input,
                route_decision=route,
                outcome_status="rejected",
                latency_ms=latency_ms,
            )
            raise HTTPException(
                status_code=403,
                detail={
                    "message": "Approval required before Merlin can continue this route.",
                    "route_id": route.route_id,
                    "route": route.model_dump(),
                    "approval_gates": route.approval_gates,
                    "approval_supported": True,
                    "approval_scope": "one_time_local_model_call",
                    "session_id": session_id,
                },
            )

    if route_approved_by_id:
        try:
            mark_approval_used(approval_id)
        except KeyError:
            pass

    system_prompt = build_system_prompt(route)

    try:
        response_text = _call_litellm(
            system_prompt,
            user_input,
            route.selected_model_alias,
            request.context_messages,
        )
    except (httpx.ConnectError, httpx.TimeoutException, httpx.HTTPError, OSError):
        logger.warning("LiteLLM unavailable: input_hash=%s route_id=%s", input_hash, route.route_id)
        latency_ms = int((time.perf_counter() - started) * 1000)
        record_task_trace(
            input_hash=input_hash,
            session_id=session_id,
            route=route,
            approved=False,
            memory_written=False,
            degraded=True,
            latency_ms=latency_ms,
        )
        observe_task_outcome(
            user_input=user_input,
            route_decision=route,
            outcome_status="degraded",
            latency_ms=latency_ms,
        )
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

    latency_ms = int((time.perf_counter() - started) * 1000)
    record_task_trace(
        input_hash=input_hash,
        session_id=session_id,
        route=route,
        approved=True,
        memory_written=memory_written,
        degraded=False,
        latency_ms=latency_ms,
    )
    observe_task_outcome(
        user_input=user_input,
        route_decision=route,
        outcome_status="success",
        latency_ms=latency_ms,
    )

    return TaskResponse(
        response=response_text,
        route=route.model_dump(),
        approved=True,
        session_id=session_id,
        memory_written=memory_written,
    )


@app.post("/approvals/task-route", response_model=TaskRouteApprovalResponse)
def create_task_route_approval_endpoint(request: TaskRouteApprovalRequest) -> TaskRouteApprovalResponse:
    user_input = _validate_user_input(request.input)
    session_id = request.session_id or str(uuid.uuid4())
    route = route_task(user_input)
    if not route.requires_approval:
        raise HTTPException(
            status_code=400,
            detail={
                "message": "This route does not require approval.",
                "route_id": route.route_id,
                "route": route.model_dump(),
            },
        )
    record = create_task_route_approval(
        user_input=user_input,
        session_id=session_id,
        route_id=route.route_id,
        staff_mode=route.staff_mode,
        selected_model_alias=route.selected_model_alias,
        approval_gates=route.approval_gates,
    )
    return _task_route_approval_response(record, route)


@app.post("/rooms", response_model=RoomCreateResponse)
def create_room_endpoint(request: RoomCreateRequest) -> RoomCreateResponse:
    try:
        result = create_room(room_name=request.room_name)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileExistsError as exc:
        raise HTTPException(status_code=409, detail="Room already exists") from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room could not be created locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    return _room_create_response(result, _write_room_create_audit(result))


@app.post("/rooms/transcripts", response_model=RoomTranscriptSaveResponse)
def save_room_transcript_endpoint(request: RoomTranscriptSaveRequest) -> RoomTranscriptSaveResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Saving a Room transcript requires explicit approval.",
                "approval_gates": ["file_write"],
                "memory_extraction": "not_performed_requires_separate_approval",
            },
        )

    try:
        require_room_transcript_approval(
            approval_id=approval_id,
            room_id=request.room_id,
            room_name=request.room_name,
            user_input=request.user_input,
            merlin_response=request.merlin_response,
            session_id=request.session_id,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_write"],
                "memory_extraction": "not_performed_requires_separate_approval",
            },
        ) from exc

    try:
        result = save_room_transcript(
            room_id=request.room_id,
            room_name=request.room_name,
            user_input=request.user_input,
            merlin_response=request.merlin_response,
            session_id=request.session_id,
            approval_id=approval_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room transcript could not be saved locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_transcript_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomTranscriptSaveResponse(
        status="saved_local_transcript_only",
        room_id=result.room_id,
        transcript_id=result.transcript_id,
        transcript_title=result.transcript_title,
        transcript_path=result.transcript_path,
        audit_id=audit_id,
        memory_written=False,
        memory_extraction=result.memory_extraction,
    )


@app.post("/approvals/room-transcript", response_model=RoomTranscriptApprovalResponse)
def create_room_transcript_approval_endpoint(
    request: RoomTranscriptApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        record = create_room_transcript_approval(
            room_id=request.room_id,
            room_name=request.room_name,
            user_input=request.user_input,
            merlin_response=request.merlin_response,
            session_id=request.session_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/approvals/room-transcript-read", response_model=RoomTranscriptApprovalResponse)
def create_room_transcript_read_approval_endpoint(
    request: RoomTranscriptReadApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        record = create_room_transcript_read_approval(
            room_id=request.room_id,
            room_name=request.room_name,
            transcript_id=request.transcript_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/rooms/transcripts/read", response_model=RoomTranscriptReadResponse)
def read_room_transcript_endpoint(request: RoomTranscriptReadRequest) -> RoomTranscriptReadResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Reading a saved Room transcript requires explicit approval.",
                "approval_gates": ["file_read"],
                "memory_written": False,
                "context_reuse": "disabled_until_user_approved",
            },
        )

    try:
        require_room_transcript_read_approval(
            approval_id=approval_id,
            room_id=request.room_id,
            room_name=request.room_name,
            transcript_id=request.transcript_id,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_read"],
                "memory_written": False,
                "context_reuse": "disabled_until_user_approved",
            },
        ) from exc

    try:
        result = read_room_transcript(
            room_id=request.room_id,
            transcript_id=request.transcript_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room transcript could not be read locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_transcript_read_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomTranscriptReadResponse(
        status="read_local_transcript_only",
        room_id=result.room_id,
        room_name=result.room_name,
        transcript_id=result.transcript_id,
        user_input=result.user_input,
        merlin_response=result.merlin_response,
        memory_written=False,
        context_reuse=result.context_reuse,
        raw_content_loaded=True,
        audit_id=audit_id,
    )


@app.post("/approvals/room-transcript-delete", response_model=RoomTranscriptApprovalResponse)
def create_room_transcript_delete_approval_endpoint(
    request: RoomTranscriptDeleteApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        record = create_room_transcript_delete_approval(
            room_id=request.room_id,
            room_name=request.room_name,
            transcript_id=request.transcript_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/rooms/transcripts/delete", response_model=RoomTranscriptDeleteResponse)
def delete_room_transcript_endpoint(request: RoomTranscriptDeleteRequest) -> RoomTranscriptDeleteResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Deleting a saved Room transcript requires explicit approval.",
                "approval_gates": ["file_delete"],
                "memory_written": False,
                "context_reuse": "disabled_until_user_approved",
            },
        )

    try:
        require_room_transcript_delete_approval(
            approval_id=approval_id,
            room_id=request.room_id,
            room_name=request.room_name,
            transcript_id=request.transcript_id,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_delete"],
                "memory_written": False,
                "context_reuse": "disabled_until_user_approved",
            },
        ) from exc

    try:
        result = delete_room_transcript(
            room_id=request.room_id,
            transcript_id=request.transcript_id,
            approval_id=approval_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room transcript could not be deleted locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_transcript_delete_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomTranscriptDeleteResponse(
        status="deleted_local_transcript_only",
        room_id=result.room_id,
        room_name=result.room_name,
        transcript_id=result.transcript_id,
        deleted_at=result.deleted_at,
        memory_written=False,
        context_reuse=result.context_reuse,
        audit_id=audit_id,
    )


@app.post("/approvals/room-archive", response_model=RoomTranscriptApprovalResponse)
def create_room_archive_approval_endpoint(
    request: RoomArchiveApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        preview = room_archive_preview(request.room_id)
        record = create_room_archive_approval(
            room_id=preview.room_id,
            room_name=request.room_name or preview.room_name,
            transcript_count=preview.transcript_count,
            summary_count=preview.summary_count,
            master_prompt_status=preview.master_prompt_status,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/rooms/archive", response_model=RoomArchiveResponse)
def archive_room_endpoint(request: RoomArchiveRequest) -> RoomArchiveResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Archiving a whole Room requires explicit approval.",
                "approval_gates": ["file_archive"],
                "memory_written": False,
                "approved_memory_deleted": False,
                "context_reuse": "disabled_until_user_approved",
                "linked_memory_review": "not_available_requires_manual_memory_review",
            },
        )

    try:
        preview = room_archive_preview(request.room_id)
        if preview.transcript_count != int(request.transcript_count):
            raise PermissionError("Room transcript count changed after archive approval was prepared")
        if preview.summary_count != int(request.summary_count):
            raise PermissionError("Room summary count changed after archive approval was prepared")
        if preview.master_prompt_status != request.master_prompt_status:
            raise PermissionError("Room Master Prompt status changed after archive approval was prepared")
        require_room_archive_approval(
            approval_id=approval_id,
            room_id=preview.room_id,
            room_name=request.room_name or preview.room_name,
            transcript_count=preview.transcript_count,
            summary_count=preview.summary_count,
            master_prompt_status=preview.master_prompt_status,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_archive"],
                "memory_written": False,
                "approved_memory_deleted": False,
                "context_reuse": "disabled_until_user_approved",
                "linked_memory_review": "not_available_requires_manual_memory_review",
            },
        ) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    try:
        result = archive_room(
            room_id=request.room_id,
            approval_id=approval_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room could not be archived locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_archive_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomArchiveResponse(
        status="archived_local_room_only",
        room_id=result.room_id,
        room_name=result.room_name,
        archived_room_path=result.archived_room_path,
        archived_at=result.archived_at,
        transcript_count=result.transcript_count,
        summary_count=result.summary_count,
        master_prompt_status=result.master_prompt_status,
        linked_memory_review=result.linked_memory_review,
        memory_written=False,
        approved_memory_deleted=False,
        context_reuse=result.context_reuse,
        audit_id=audit_id,
    )


@app.post("/approvals/room-delete", response_model=RoomTranscriptApprovalResponse)
def create_room_delete_approval_endpoint(
    request: RoomDeleteApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        preview = room_archive_preview(request.room_id)
        record = create_room_delete_approval(
            room_id=preview.room_id,
            room_name=request.room_name or preview.room_name,
            transcript_count=preview.transcript_count,
            summary_count=preview.summary_count,
            master_prompt_status=preview.master_prompt_status,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/rooms/delete", response_model=RoomDeleteResponse)
def delete_room_endpoint(request: RoomDeleteRequest) -> RoomDeleteResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Deleting a whole Room requires explicit approval.",
                "approval_gates": ["file_delete"],
                "memory_written": False,
                "approved_memory_deleted": False,
                "context_reuse": "disabled_until_user_approved",
                "linked_memory_review": "not_available_requires_manual_memory_review",
            },
        )

    try:
        preview = room_archive_preview(request.room_id)
        if preview.transcript_count != int(request.transcript_count):
            raise PermissionError("Room transcript count changed after delete approval was prepared")
        if preview.summary_count != int(request.summary_count):
            raise PermissionError("Room summary count changed after delete approval was prepared")
        if preview.master_prompt_status != request.master_prompt_status:
            raise PermissionError("Room Master Prompt status changed after delete approval was prepared")
        require_room_delete_approval(
            approval_id=approval_id,
            room_id=preview.room_id,
            room_name=request.room_name or preview.room_name,
            transcript_count=preview.transcript_count,
            summary_count=preview.summary_count,
            master_prompt_status=preview.master_prompt_status,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_delete"],
                "memory_written": False,
                "approved_memory_deleted": False,
                "context_reuse": "disabled_until_user_approved",
                "linked_memory_review": "not_available_requires_manual_memory_review",
            },
        ) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    try:
        result = delete_room(
            room_id=request.room_id,
            approval_id=approval_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room could not be deleted locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_delete_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomDeleteResponse(
        status="deleted_local_room_only",
        room_id=result.room_id,
        room_name=result.room_name,
        deleted_room_path=result.deleted_room_path,
        deleted_at=result.deleted_at,
        transcript_count=result.transcript_count,
        summary_count=result.summary_count,
        master_prompt_status=result.master_prompt_status,
        linked_memory_review=result.linked_memory_review,
        memory_written=False,
        approved_memory_deleted=False,
        context_reuse=result.context_reuse,
        audit_id=audit_id,
    )


@app.post("/approvals/room-restore", response_model=RoomTranscriptApprovalResponse)
def create_room_restore_approval_endpoint(
    request: RoomRestoreApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        archived = _archived_room_by_id(request.archive_id)
        record = create_room_restore_approval(
            archive_id=archived.archive_id,
            room_id=archived.room_id,
            room_name=archived.room_name,
            transcript_count=archived.transcript_count,
            summary_count=archived.summary_count,
            master_prompt_status=archived.master_prompt_status,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/rooms/restore", response_model=RoomRestoreResponse)
def restore_room_endpoint(request: RoomRestoreRequest) -> RoomRestoreResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Restoring an archived Room requires explicit approval.",
                "approval_gates": ["file_restore"],
                "memory_written": False,
                "approved_memory_restored": False,
                "context_reuse": "disabled_until_user_approved",
            },
        )

    try:
        archived = _archived_room_by_id(request.archive_id)
        if archived.room_id != request.room_id:
            raise PermissionError("Archived Room id changed after restore approval was prepared")
        if archived.transcript_count != int(request.transcript_count):
            raise PermissionError("Archived Room transcript count changed after restore approval was prepared")
        if archived.summary_count != int(request.summary_count):
            raise PermissionError("Archived Room summary count changed after restore approval was prepared")
        if archived.master_prompt_status != request.master_prompt_status:
            raise PermissionError("Archived Room Master Prompt status changed after restore approval was prepared")
        require_room_restore_approval(
            approval_id=approval_id,
            archive_id=archived.archive_id,
            room_id=archived.room_id,
            room_name=request.room_name or archived.room_name,
            transcript_count=archived.transcript_count,
            summary_count=archived.summary_count,
            master_prompt_status=archived.master_prompt_status,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_restore"],
                "memory_written": False,
                "approved_memory_restored": False,
                "context_reuse": "disabled_until_user_approved",
            },
        ) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    try:
        result = restore_archived_room(
            archive_id=request.archive_id,
            approval_id=approval_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except FileExistsError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room could not be restored locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_restore_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomRestoreResponse(
        status="restored_local_room_only",
        archive_id=result.archive_id,
        room_id=result.room_id,
        room_name=result.room_name,
        restored_room_path=result.restored_room_path,
        restored_at=result.restored_at,
        transcript_count=result.transcript_count,
        summary_count=result.summary_count,
        master_prompt_status=result.master_prompt_status,
        memory_written=False,
        approved_memory_restored=False,
        context_reuse=result.context_reuse,
        audit_id=audit_id,
    )


@app.post("/approvals/room-master-prompt", response_model=RoomTranscriptApprovalResponse)
def create_room_master_prompt_approval_endpoint(
    request: RoomMasterPromptApprovalRequest,
) -> RoomTranscriptApprovalResponse:
    try:
        source_transcript_count = count_room_transcripts(request.room_id)
        if source_transcript_count < 1:
            raise ValueError("Room Master Prompt requires at least one saved transcript")
        record = create_room_master_prompt_approval(
            room_id=request.room_id,
            room_name=request.room_name,
            source_transcript_count=source_transcript_count,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return _approval_response(record)


@app.post("/rooms/master-prompt-drafts", response_model=RoomMasterPromptDraftResponse)
def generate_room_master_prompt_draft_endpoint(
    request: RoomMasterPromptDraftRequest,
) -> RoomMasterPromptDraftResponse:
    approval_id = (request.approval_id or "").strip()
    if not approval_id:
        raise HTTPException(
            status_code=403,
            detail={
                "message": "Generating a Room Master Prompt draft requires explicit approval.",
                "approval_gates": ["file_write"],
                "context_reuse": "disabled_until_user_approved",
                "memory_written": False,
            },
        )

    try:
        current_count = count_room_transcripts(request.room_id)
        if current_count != int(request.source_transcript_count):
            raise PermissionError("source transcript count changed after approval was prepared")
        require_room_master_prompt_approval(
            approval_id=approval_id,
            room_id=request.room_id,
            room_name=request.room_name,
            source_transcript_count=request.source_transcript_count,
        )
    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail={
                "message": str(exc),
                "approval_gates": ["file_write"],
                "context_reuse": "disabled_until_user_approved",
                "memory_written": False,
            },
        ) from exc
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        result = generate_room_master_prompt_draft(
            room_id=request.room_id,
            room_name=request.room_name,
            approval_id=approval_id,
            transcript_limit=request.source_transcript_count,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Room Master Prompt draft could not be written locally.",
                "error": exc.__class__.__name__,
            },
        ) from exc

    audit_id = _write_room_master_prompt_audit(result, request)
    try:
        mark_approval_used(approval_id)
    except KeyError:
        pass
    return RoomMasterPromptDraftResponse(
        status="draft_saved_local_only",
        room_id=result.room_id,
        room_name=result.room_name,
        master_prompt_path=result.master_prompt_path,
        audit_id=audit_id,
        source_transcript_count=result.source_transcript_count,
        memory_written=False,
        approved_for_context=False,
        context_reuse="disabled_until_user_approved",
    )


@app.post("/approvals/{approval_id}/approve", response_model=ApprovalDecisionResponse)
def approve_room_transcript_approval_endpoint(approval_id: str) -> ApprovalDecisionResponse:
    try:
        record = decide_approval(approval_id, "approved")
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="approval id not found") from exc
    return _decision_response(record)


@app.post("/approvals/{approval_id}/deny", response_model=ApprovalDecisionResponse)
def deny_room_transcript_approval_endpoint(approval_id: str) -> ApprovalDecisionResponse:
    try:
        record = decide_approval(approval_id, "denied")
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="approval id not found") from exc
    return _decision_response(record)


from merlin import status_extension  # noqa: E402,F401  Register status routes after app setup.


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("merlin.task_endpoint:app", host="127.0.0.1", port=8766)
