"""Local approval request store for policy-gated Merlin actions."""

from __future__ import annotations

import hashlib
import json
import os
import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_APPROVAL_LOG = REPO_ROOT / "logs" / "merlin-approvals.jsonl"
APPROVABLE_STATUSES = {"required_pending", "approved"}


class ApprovalRecord(BaseModel):
    approval_request_id: str
    timestamp: str
    status: str
    action: str
    approval_gates: list[str] = Field(default_factory=list)
    payload_hash: str
    payload_summary: dict[str, Any] = Field(default_factory=dict)
    execution_allowed: bool = False
    decision_recorded: bool = False
    decision_source: str = "task_api"
    decision_record_type: str = "approval_request"
    redaction_applied: bool = True
    side_effects: str = "none"
    model_calls: str = "none"
    memory_writes: str = "none"
    service_starts: str = "none"
    tool_execution: str = "none"


def approval_log_path() -> Path:
    return Path(os.environ.get("MERLIN_APPROVAL_LOG", DEFAULT_APPROVAL_LOG)).expanduser()


def now_iso() -> str:
    return datetime.now(UTC).isoformat()


def stable_hash(payload: dict[str, Any]) -> str:
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return "sha256:" + hashlib.sha256(encoded).hexdigest()


def room_transcript_payload_hash(
    *,
    room_id: str,
    room_name: str | None,
    user_input: str,
    merlin_response: str,
    session_id: str,
) -> str:
    return stable_hash(
        {
            "action": "room_transcript_save",
            "version": 1,
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "session_id": session_id.strip(),
            "user_input_hash": stable_hash({"user_input": user_input.strip()}),
            "merlin_response_hash": stable_hash({"merlin_response": merlin_response.strip()}),
        }
    )


def room_master_prompt_payload_hash(
    *,
    room_id: str,
    room_name: str | None,
    source_transcript_count: int,
) -> str:
    return stable_hash(
        {
            "action": "room_master_prompt_draft",
            "version": 1,
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "source_transcript_count": int(source_transcript_count),
            "memory_write": False,
            "context_reuse": "disabled_until_user_approved",
        }
    )


def room_transcript_read_payload_hash(
    *,
    room_id: str,
    room_name: str | None,
    transcript_id: str,
) -> str:
    return stable_hash(
        {
            "action": "room_transcript_read",
            "version": 1,
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "transcript_id": transcript_id.strip(),
            "memory_write": False,
            "context_reuse": "disabled_until_user_approved",
        }
    )


def room_transcript_delete_payload_hash(
    *,
    room_id: str,
    room_name: str | None,
    transcript_id: str,
) -> str:
    return stable_hash(
        {
            "action": "room_transcript_delete",
            "version": 1,
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "transcript_id": transcript_id.strip(),
            "memory_write": False,
            "context_reuse": "disabled_until_user_approved",
        }
    )


def _append_record(record: ApprovalRecord, path: Path | None = None) -> None:
    approval_log = path or approval_log_path()
    approval_log.parent.mkdir(parents=True, exist_ok=True)
    with approval_log.open("a", encoding="utf-8") as handle:
        handle.write(record.model_dump_json(exclude_none=True) + "\n")


def _read_records(path: Path | None = None) -> list[ApprovalRecord]:
    approval_log = path or approval_log_path()
    if not approval_log.exists():
        return []
    records: list[ApprovalRecord] = []
    for line in approval_log.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            records.append(ApprovalRecord.model_validate_json(line))
        except Exception:
            continue
    return records


def latest_approval(approval_id: str, path: Path | None = None) -> ApprovalRecord | None:
    latest: ApprovalRecord | None = None
    for record in _read_records(path):
        if record.approval_request_id == approval_id:
            latest = record
    return latest


def create_room_transcript_approval(
    *,
    room_id: str,
    room_name: str | None,
    user_input: str,
    merlin_response: str,
    session_id: str,
    path: Path | None = None,
) -> ApprovalRecord:
    payload_hash = room_transcript_payload_hash(
        room_id=room_id,
        room_name=room_name,
        user_input=user_input,
        merlin_response=merlin_response,
        session_id=session_id,
    )
    record = ApprovalRecord(
        approval_request_id=f"approval_room_{uuid.uuid4().hex[:12]}",
        timestamp=now_iso(),
        status="required_pending",
        action="room_transcript_save",
        approval_gates=["file_write"],
        payload_hash=payload_hash,
        payload_summary={
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "session_id_hash": stable_hash({"session_id": session_id.strip()}),
            "user_input_hash": stable_hash({"user_input": user_input.strip()}),
            "merlin_response_hash": stable_hash({"merlin_response": merlin_response.strip()}),
            "memory_extraction": "not_performed_requires_separate_approval",
            "raw_content_in_approval": False,
        },
    )
    _append_record(record, path)
    return record


def create_room_master_prompt_approval(
    *,
    room_id: str,
    room_name: str | None,
    source_transcript_count: int,
    path: Path | None = None,
) -> ApprovalRecord:
    payload_hash = room_master_prompt_payload_hash(
        room_id=room_id,
        room_name=room_name,
        source_transcript_count=source_transcript_count,
    )
    record = ApprovalRecord(
        approval_request_id=f"approval_room_master_prompt_{uuid.uuid4().hex[:12]}",
        timestamp=now_iso(),
        status="required_pending",
        action="room_master_prompt_draft",
        approval_gates=["file_write"],
        payload_hash=payload_hash,
        payload_summary={
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "source_transcript_count": int(source_transcript_count),
            "raw_content_in_approval": False,
            "memory_write": False,
            "context_reuse": "disabled_until_user_approved",
        },
    )
    _append_record(record, path)
    return record


def create_room_transcript_read_approval(
    *,
    room_id: str,
    room_name: str | None,
    transcript_id: str,
    path: Path | None = None,
) -> ApprovalRecord:
    payload_hash = room_transcript_read_payload_hash(
        room_id=room_id,
        room_name=room_name,
        transcript_id=transcript_id,
    )
    record = ApprovalRecord(
        approval_request_id=f"approval_room_transcript_read_{uuid.uuid4().hex[:12]}",
        timestamp=now_iso(),
        status="required_pending",
        action="room_transcript_read",
        approval_gates=["file_read"],
        payload_hash=payload_hash,
        payload_summary={
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "transcript_id": transcript_id.strip(),
            "raw_content_in_approval": False,
            "memory_write": False,
            "context_reuse": "disabled_until_user_approved",
        },
        side_effects="none",
        tool_execution="local_file_read_after_approval",
    )
    _append_record(record, path)
    return record


def create_room_transcript_delete_approval(
    *,
    room_id: str,
    room_name: str | None,
    transcript_id: str,
    path: Path | None = None,
) -> ApprovalRecord:
    payload_hash = room_transcript_delete_payload_hash(
        room_id=room_id,
        room_name=room_name,
        transcript_id=transcript_id,
    )
    record = ApprovalRecord(
        approval_request_id=f"approval_room_transcript_delete_{uuid.uuid4().hex[:12]}",
        timestamp=now_iso(),
        status="required_pending",
        action="room_transcript_delete",
        approval_gates=["file_delete"],
        payload_hash=payload_hash,
        payload_summary={
            "room_id": room_id.strip(),
            "room_name": (room_name or "").strip(),
            "transcript_id": transcript_id.strip(),
            "raw_content_in_approval": False,
            "memory_write": False,
            "context_reuse": "disabled_until_user_approved",
        },
        side_effects="local_transcript_file_delete_after_approval",
        tool_execution="local_file_delete_after_approval",
    )
    _append_record(record, path)
    return record


def decide_approval(approval_id: str, status: str, path: Path | None = None) -> ApprovalRecord:
    if status not in {"approved", "denied"}:
        raise ValueError("approval decision must be approved or denied")
    current = latest_approval(approval_id, path)
    if current is None:
        raise KeyError("approval id not found")
    if current.status != "required_pending":
        return current
    decided = current.model_copy(
        update={
            "timestamp": now_iso(),
            "status": status,
            "execution_allowed": status == "approved",
            "decision_recorded": True,
            "decision_record_type": "approval_decision",
            "side_effects": "none",
        }
    )
    _append_record(decided, path)
    return decided


def mark_approval_used(approval_id: str, path: Path | None = None) -> ApprovalRecord:
    current = latest_approval(approval_id, path)
    if current is None:
        raise KeyError("approval id not found")
    if current.status != "approved":
        return current
    used = current.model_copy(
        update={
            "timestamp": now_iso(),
            "status": "used",
            "execution_allowed": False,
            "decision_recorded": True,
            "decision_record_type": "approval_used",
            "side_effects": current.side_effects,
        }
    )
    _append_record(used, path)
    return used


def require_room_transcript_approval(
    *,
    approval_id: str,
    room_id: str,
    room_name: str | None,
    user_input: str,
    merlin_response: str,
    session_id: str,
    path: Path | None = None,
) -> ApprovalRecord:
    current = latest_approval(approval_id, path)
    if current is None:
        raise PermissionError("approval id not found")
    if current.status != "approved" or not current.execution_allowed:
        raise PermissionError("approval is not approved for execution")
    if current.action != "room_transcript_save":
        raise PermissionError("approval action does not match room transcript save")
    expected = room_transcript_payload_hash(
        room_id=room_id,
        room_name=room_name,
        user_input=user_input,
        merlin_response=merlin_response,
        session_id=session_id,
    )
    if current.payload_hash != expected:
        raise PermissionError("approval payload hash does not match transcript payload")
    return current


def require_room_transcript_read_approval(
    *,
    approval_id: str,
    room_id: str,
    room_name: str | None,
    transcript_id: str,
    path: Path | None = None,
) -> ApprovalRecord:
    current = latest_approval(approval_id, path)
    if current is None:
        raise PermissionError("approval id not found")
    if current.status != "approved" or not current.execution_allowed:
        raise PermissionError("approval is not approved for execution")
    if current.action != "room_transcript_read":
        raise PermissionError("approval action does not match room transcript read")
    expected = room_transcript_read_payload_hash(
        room_id=room_id,
        room_name=room_name,
        transcript_id=transcript_id,
    )
    if current.payload_hash != expected:
        raise PermissionError("approval payload hash does not match transcript read payload")
    return current


def require_room_transcript_delete_approval(
    *,
    approval_id: str,
    room_id: str,
    room_name: str | None,
    transcript_id: str,
    path: Path | None = None,
) -> ApprovalRecord:
    current = latest_approval(approval_id, path)
    if current is None:
        raise PermissionError("approval id not found")
    if current.status != "approved" or not current.execution_allowed:
        raise PermissionError("approval is not approved for execution")
    if current.action != "room_transcript_delete":
        raise PermissionError("approval action does not match room transcript delete")
    expected = room_transcript_delete_payload_hash(
        room_id=room_id,
        room_name=room_name,
        transcript_id=transcript_id,
    )
    if current.payload_hash != expected:
        raise PermissionError("approval payload hash does not match transcript delete payload")
    return current


def require_room_master_prompt_approval(
    *,
    approval_id: str,
    room_id: str,
    room_name: str | None,
    source_transcript_count: int,
    path: Path | None = None,
) -> ApprovalRecord:
    current = latest_approval(approval_id, path)
    if current is None:
        raise PermissionError("approval id not found")
    if current.status != "approved" or not current.execution_allowed:
        raise PermissionError("approval is not approved for execution")
    if current.action != "room_master_prompt_draft":
        raise PermissionError("approval action does not match Room Master Prompt draft")
    expected = room_master_prompt_payload_hash(
        room_id=room_id,
        room_name=room_name,
        source_transcript_count=source_transcript_count,
    )
    if current.payload_hash != expected:
        raise PermissionError("approval payload hash does not match Room Master Prompt payload")
    return current
