"""Read-only Merlin Rooms manifest helpers.

Rooms are local chat/project context containers. This first #135 runtime slice
does not write transcripts, indexes, or memory. It only discovers a configured
Rooms root and any existing Room folders with a `room.md` metadata file so
Wizard HQ can show honest state before save-to-Room support exists.
"""

from __future__ import annotations

import os
import re
import uuid
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from pydantic import BaseModel


DEFAULT_BRAIN_ROOT = Path.home() / "Merlin" / "brain"
ROOM_SLUG_PATTERN = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$")


class RoomRecord(BaseModel):
    room_id: str
    name: str
    path: str
    metadata_file: str
    transcript_count: int = 0
    summary_count: int = 0
    reference_policy: str = "no_room_context"
    memory_extraction: str = "requires_approval"


class RoomTranscriptSaveResult(BaseModel):
    room_id: str
    room_name: str
    transcript_id: str
    transcript_path: str
    metadata_file: str
    created_at: str
    approval_id: str
    bytes_written: int
    memory_extraction: str = "not_performed_requires_separate_approval"
    approved_memory_written: bool = False


def brain_root_path() -> Path:
    override = os.environ.get("MERLIN_BRAIN_ROOT")
    return Path(override).expanduser() if override else DEFAULT_BRAIN_ROOT


def rooms_root_path() -> Path:
    override = os.environ.get("MERLIN_ROOMS_ROOT")
    return Path(override).expanduser() if override else brain_root_path() / "rooms"


def _safe_room_id(value: str) -> bool:
    return bool(ROOM_SLUG_PATTERN.fullmatch(value))


def _utc_now() -> str:
    return datetime.now(UTC).isoformat()


def _timestamp_slug(ts_iso: str) -> str:
    return (
        ts_iso.replace("+00:00", "Z")
        .replace(":", "")
        .replace(".", "-")
        .replace("T", "-")
        .replace("Z", "z")
    )


def _count_markdown_files(path: Path) -> int:
    try:
        return sum(1 for item in path.iterdir() if item.is_file() and item.suffix.lower() == ".md")
    except OSError:
        return 0


def _room_name_from_metadata(metadata_file: Path, fallback: str) -> str:
    try:
        for line in metadata_file.read_text(encoding="utf-8").splitlines()[:20]:
            if line.lower().startswith("name:"):
                value = line.split(":", 1)[1].strip()
                return value or fallback
    except OSError:
        return fallback
    return fallback


def list_rooms(root: Path | None = None) -> list[RoomRecord]:
    rooms_root = root or rooms_root_path()
    if not rooms_root.exists() or not rooms_root.is_dir():
        return []

    rooms: list[RoomRecord] = []
    try:
        children = sorted(rooms_root.iterdir(), key=lambda item: item.name.lower())
    except OSError:
        return []

    for child in children:
        if not child.is_dir() or not _safe_room_id(child.name):
            continue
        metadata_file = child / "room.md"
        if not metadata_file.exists() or not metadata_file.is_file():
            continue
        rooms.append(
            RoomRecord(
                room_id=child.name,
                name=_room_name_from_metadata(metadata_file, child.name.replace("-", " ").title()),
                path=str(child),
                metadata_file=str(metadata_file),
                transcript_count=_count_markdown_files(child / "transcripts"),
                summary_count=_count_markdown_files(child / "summaries"),
            )
        )
    return rooms


def _validate_room_id(room_id: str) -> str:
    normalized = room_id.strip()
    if not _safe_room_id(normalized):
        raise ValueError("room_id must be a safe slug: letters, numbers, dot, underscore, or dash")
    return normalized


def _validate_text_field(value: str, field_name: str, max_length: int) -> str:
    stripped = value.strip()
    if not stripped:
        raise ValueError(f"{field_name} must not be empty")
    if len(stripped) > max_length:
        raise ValueError(f"{field_name} must be {max_length} characters or fewer")
    return stripped


def save_room_transcript(
    *,
    room_id: str,
    room_name: str | None,
    user_input: str,
    merlin_response: str,
    session_id: str,
    approval_id: str,
    root: Path | None = None,
    created_at: str | None = None,
) -> RoomTranscriptSaveResult:
    """Save a local Room transcript.

    This writes local markdown history only. It does not index Room context and
    does not write approved memory. Callers must require explicit approval
    before invoking this function.
    """

    safe_room_id = _validate_room_id(room_id)
    safe_room_name = _validate_text_field(room_name or safe_room_id.replace("-", " ").title(), "room_name", 120)
    safe_user_input = _validate_text_field(user_input, "user_input", 4000)
    safe_merlin_response = _validate_text_field(merlin_response, "merlin_response", 20000)
    safe_session_id = _validate_text_field(session_id, "session_id", 120)
    safe_approval_id = _validate_text_field(approval_id, "approval_id", 120)
    ts = created_at or _utc_now()

    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    transcripts_path = room_path / "transcripts"
    metadata_file = room_path / "room.md"
    transcript_id = f"{_timestamp_slug(ts)}-{uuid.uuid4().hex[:8]}"
    transcript_file = transcripts_path / f"{transcript_id}.md"
    tmp_file = transcripts_path / f".{transcript_id}.tmp"

    content = "\n".join(
        [
            "---",
            f"room_id: {safe_room_id}",
            f"name: {safe_room_name}",
            f"session_id: {safe_session_id}",
            f"approval_id: {safe_approval_id}",
            f"created_at: {ts}",
            "reference_policy: no_room_context",
            "memory_extraction: not_performed_requires_separate_approval",
            "---",
            "",
            "# Merlin Chat Transcript",
            "",
            "## User",
            "",
            safe_user_input,
            "",
            "## Merlin",
            "",
            safe_merlin_response,
            "",
        ]
    )

    metadata = "\n".join(
        [
            f"name: {safe_room_name}",
            f"room_id: {safe_room_id}",
            f"created_at: {ts}",
            "reference_policy: no_room_context",
            "memory_extraction: requires_approval",
            "",
        ]
    )

    try:
        transcripts_path.mkdir(parents=True, exist_ok=True)
        if not metadata_file.exists():
            metadata_file.write_text(metadata, encoding="utf-8")
        tmp_file.write_text(content, encoding="utf-8")
        tmp_file.replace(transcript_file)
    except OSError:
        try:
            tmp_file.unlink(missing_ok=True)
        except OSError:
            pass
        raise

    return RoomTranscriptSaveResult(
        room_id=safe_room_id,
        room_name=safe_room_name,
        transcript_id=transcript_id,
        transcript_path=str(transcript_file),
        metadata_file=str(metadata_file),
        created_at=ts,
        approval_id=safe_approval_id,
        bytes_written=len(content.encode("utf-8")),
    )


def room_manifest() -> dict[str, Any]:
    brain_root = brain_root_path()
    rooms_root = rooms_root_path()
    rooms = list_rooms(rooms_root)
    return {
        "mode": "read_only_rooms_manifest",
        "brain_root": str(brain_root),
        "rooms_root": str(rooms_root),
        "rooms_root_exists": rooms_root.exists(),
        "rooms_root_source": "MERLIN_ROOMS_ROOT" if os.environ.get("MERLIN_ROOMS_ROOT") else "default_brain_rooms",
        "active_room": None,
        "reference_policy": "no_room_context",
        "reference_policy_options": [
            "no_room_context",
            "active_room_only",
            "selected_rooms",
            "all_rooms_explicit",
        ],
        "save_to_room_enabled": False,
        "save_to_room_api_enabled": True,
        "memory_extraction_enabled": False,
        "cloud_sync_default": False,
        "browser_file_controls_enabled": False,
        "browser_save_controls_enabled": False,
        "save_to_room_policy": "backend_approval_required",
        "tracked_issue": "#135",
        "rooms": [room.model_dump() for room in rooms],
        "total": len(rooms),
    }
