"""Merlin Rooms manifest and local transcript helpers.

Rooms are local chat/project context containers. Transcript and Room Master
Prompt writes are explicit local file operations; neither path writes approved
memory or enables Room context retrieval.
"""

from __future__ import annotations

import os
import re
import shutil
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field


UTC = timezone.utc
DEFAULT_BRAIN_ROOT = Path.home() / "Merlin" / "brain"
ROOM_SLUG_PATTERN = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$")


class RoomRecord(BaseModel):
    room_id: str
    name: str
    path: str
    metadata_file: str
    transcript_count: int = 0
    transcripts: list["RoomTranscriptRecord"] = Field(default_factory=list)
    summary_count: int = 0
    master_prompt: "RoomMasterPromptRecord | None" = None
    reference_policy: str = "no_room_context"
    memory_extraction: str = "requires_approval"


class RoomTranscriptRecord(BaseModel):
    transcript_id: str
    title: str = "Saved chat"
    path: str
    size_bytes: int
    modified_at: str | None = None
    raw_content_loaded: bool = False


class RoomCreateResult(BaseModel):
    room_id: str
    room_name: str
    room_path: str
    metadata_file: str
    created_at: str


class RoomTranscriptSaveResult(BaseModel):
    room_id: str
    room_name: str
    transcript_id: str
    transcript_title: str
    transcript_path: str
    metadata_file: str
    created_at: str
    approval_id: str
    bytes_written: int
    memory_extraction: str = "not_performed_requires_separate_approval"
    approved_memory_written: bool = False


class RoomTranscriptReadResult(BaseModel):
    room_id: str
    room_name: str
    transcript_id: str
    transcript_path: str
    user_input: str
    merlin_response: str
    size_bytes: int
    modified_at: str | None = None
    raw_content_loaded: bool = True
    memory_written: bool = False
    context_reuse: str = "disabled_until_user_approved"


class RoomTranscriptDeleteResult(BaseModel):
    room_id: str
    room_name: str
    transcript_id: str
    transcript_path: str
    deleted_at: str
    approval_id: str
    memory_written: bool = False
    context_reuse: str = "disabled_until_user_approved"


class RoomArchivePreview(BaseModel):
    room_id: str
    room_name: str
    room_path: str
    transcript_count: int = 0
    summary_count: int = 0
    master_prompt_status: str = "missing"
    linked_memory_review: str = "not_available_requires_manual_memory_review"
    raw_content_loaded: bool = False


class RoomArchiveResult(BaseModel):
    room_id: str
    room_name: str
    original_room_path: str
    archived_room_path: str
    archived_at: str
    approval_id: str
    transcript_count: int = 0
    summary_count: int = 0
    master_prompt_status: str = "missing"
    memory_written: bool = False
    approved_memory_deleted: bool = False
    context_reuse: str = "disabled_until_user_approved"
    linked_memory_review: str = "not_available_requires_manual_memory_review"


class RoomDeleteResult(BaseModel):
    room_id: str
    room_name: str
    deleted_room_path: str
    deleted_at: str
    approval_id: str
    transcript_count: int = 0
    summary_count: int = 0
    master_prompt_status: str = "missing"
    memory_written: bool = False
    approved_memory_deleted: bool = False
    context_reuse: str = "disabled_until_user_approved"
    linked_memory_review: str = "not_available_requires_manual_memory_review"


class ArchivedRoomRecord(BaseModel):
    archive_id: str
    room_id: str
    room_name: str
    archived_room_path: str
    transcript_count: int = 0
    summary_count: int = 0
    master_prompt_status: str = "missing"
    linked_memory_review: str = "not_available_requires_manual_memory_review"
    raw_content_loaded: bool = False


class RoomRestoreResult(BaseModel):
    archive_id: str
    room_id: str
    room_name: str
    restored_room_path: str
    restored_at: str
    approval_id: str
    transcript_count: int = 0
    summary_count: int = 0
    master_prompt_status: str = "missing"
    memory_written: bool = False
    approved_memory_restored: bool = False
    context_reuse: str = "disabled_until_user_approved"


class RoomMasterPromptRecord(BaseModel):
    status: str = "missing"
    path: str | None = None
    size_bytes: int = 0
    modified_at: str | None = None
    source_transcript_count: int = 0
    approved_for_context: bool = False
    raw_content_loaded: bool = False


class RoomMasterPromptDraftResult(BaseModel):
    room_id: str
    room_name: str
    status: str
    master_prompt_path: str
    generated_at: str
    source_transcript_count: int
    approval_id: str
    bytes_written: int
    approved_for_context: bool = False
    memory_written: bool = False


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


def _slugify_room_name(value: str) -> str:
    compact = re.sub(r"[^a-zA-Z0-9._-]+", "-", value.strip().lower()).strip(".-_")
    compact = re.sub(r"-{2,}", "-", compact)
    if not compact or not compact[0].isalnum():
        compact = "room"
    return compact[:60]


def _unique_room_id(rooms_root: Path, base_id: str) -> str:
    candidate = base_id
    index = 2
    while (rooms_root / candidate).exists():
        suffix = f"-{index}"
        candidate = f"{base_id[: 80 - len(suffix)]}{suffix}"
        index += 1
    return candidate


def _markdown_value(value: str) -> str:
    return " ".join(value.replace("\n", " ").split())


def _transcript_title(user_input: str, max_chars: int = 72) -> str:
    compact = " ".join(user_input.split())
    compact = re.sub(r"^[#*\-_\s]+", "", compact).strip()
    if not compact:
        return "Saved chat"
    title = compact[:max_chars].rstrip()
    return title if len(compact) <= max_chars else f"{title}..."


def _frontmatter_value(path: Path, key: str) -> str | None:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    if not lines or lines[0] != "---":
        return None
    for line in lines[1:40]:
        if line == "---":
            break
        if line.lower().startswith(f"{key.lower()}:"):
            value = line.split(":", 1)[1].strip()
            return value or None
    return None


def _transcript_display_title(path: Path) -> str:
    modified = _file_modified_at(path)
    if modified:
        return f"Saved chat {modified[:10]}"
    return path.stem


def create_room(
    *,
    room_name: str,
    root: Path | None = None,
    created_at: str | None = None,
) -> RoomCreateResult:
    """Create an empty local Room metadata folder.

    Creating a Room stores local organization metadata only. It does not write
    chat memory, enable context retrieval, or call a model.
    """

    safe_room_name = _validate_text_field(room_name, "room_name", 120)
    rooms_root = root or rooms_root_path()
    ts = created_at or _utc_now()
    room_id = _unique_room_id(rooms_root, _slugify_room_name(safe_room_name))
    room_path = rooms_root / room_id
    metadata_file = room_path / "room.md"
    metadata = "\n".join(
        [
            f"name: {_markdown_value(safe_room_name)}",
            f"room_id: {room_id}",
            f"created_at: {ts}",
            "reference_policy: no_room_context",
            "memory_extraction: requires_approval",
            "",
        ]
    )

    try:
        (room_path / "transcripts").mkdir(parents=True, exist_ok=False)
        (room_path / "summaries").mkdir(exist_ok=True)
        (room_path / "master-prompts").mkdir(exist_ok=True)
        metadata_file.write_text(metadata, encoding="utf-8")
    except OSError:
        raise

    return RoomCreateResult(
        room_id=room_id,
        room_name=safe_room_name,
        room_path=str(room_path),
        metadata_file=str(metadata_file),
        created_at=ts,
    )


def _count_markdown_files(path: Path) -> int:
    try:
        return sum(1 for item in path.iterdir() if item.is_file() and item.suffix.lower() == ".md")
    except OSError:
        return 0


def _file_modified_at(path: Path) -> str | None:
    try:
        return datetime.fromtimestamp(path.stat().st_mtime, UTC).isoformat()
    except OSError:
        return None


def master_prompt_path(room_path: Path) -> Path:
    return room_path / "master-prompts" / "master-prompt.md"


def room_master_prompt_record(room_path: Path) -> RoomMasterPromptRecord:
    prompt_path = master_prompt_path(room_path)
    if not prompt_path.exists() or not prompt_path.is_file():
        return RoomMasterPromptRecord(status="missing")
    try:
        size_bytes = prompt_path.stat().st_size
    except OSError:
        size_bytes = 0
    return RoomMasterPromptRecord(
        status="draft",
        path=str(prompt_path),
        size_bytes=size_bytes,
        modified_at=_file_modified_at(prompt_path),
        source_transcript_count=_count_markdown_files(room_path / "transcripts"),
    )


def list_room_transcripts(room_path: Path, limit: int = 5) -> list[RoomTranscriptRecord]:
    transcripts_path = room_path / "transcripts"
    if not transcripts_path.exists() or not transcripts_path.is_dir():
        return []

    try:
        transcript_files = [
            item
            for item in transcripts_path.iterdir()
            if item.is_file() and item.suffix.lower() == ".md" and not item.name.startswith(".")
        ]
    except OSError:
        return []

    records: list[RoomTranscriptRecord] = []
    for item in sorted(transcript_files, key=lambda path: path.name, reverse=True)[:limit]:
        try:
            size_bytes = item.stat().st_size
        except OSError:
            size_bytes = 0
        records.append(
            RoomTranscriptRecord(
                transcript_id=item.stem,
                title=_transcript_display_title(item),
                path=str(item),
                size_bytes=size_bytes,
                modified_at=_file_modified_at(item),
            )
        )
    return records


def _room_name_from_metadata(metadata_file: Path, fallback: str) -> str:
    try:
        for line in metadata_file.read_text(encoding="utf-8").splitlines()[:20]:
            if line.lower().startswith("name:"):
                value = line.split(":", 1)[1].strip()
                return value or fallback
    except OSError:
        return fallback
    return fallback


def _archive_note_value(archive_path: Path, key: str, fallback: str = "") -> str:
    note = archive_path / "archive.md"
    try:
        lines = note.read_text(encoding="utf-8").splitlines()[:80]
    except OSError:
        return fallback
    prefix = f"{key}:"
    for line in lines:
        if line.lower().startswith(prefix.lower()):
            value = line.split(":", 1)[1].strip()
            return value or fallback
    return fallback


def _archived_room_record(archive_path: Path) -> ArchivedRoomRecord | None:
    if not archive_path.is_dir() or not _safe_room_id(archive_path.name):
        return None
    metadata_file = archive_path / "room.md"
    if not metadata_file.exists() or not metadata_file.is_file():
        return None
    room_id = _archive_note_value(archive_path, "room_id", archive_path.name)
    if not _safe_room_id(room_id):
        return None
    master_prompt = room_master_prompt_record(archive_path)
    return ArchivedRoomRecord(
        archive_id=archive_path.name,
        room_id=room_id,
        room_name=_room_name_from_metadata(metadata_file, room_id.replace("-", " ").title()),
        archived_room_path=str(archive_path),
        transcript_count=_count_markdown_files(archive_path / "transcripts"),
        summary_count=_count_markdown_files(archive_path / "summaries"),
        master_prompt_status=master_prompt.status,
    )


def list_archived_rooms(root: Path | None = None) -> list[ArchivedRoomRecord]:
    rooms_root = root or rooms_root_path()
    archive_root = rooms_root / ".archive"
    if not archive_root.exists() or not archive_root.is_dir():
        return []
    try:
        children = sorted(archive_root.iterdir(), key=lambda item: item.name.lower(), reverse=True)
    except OSError:
        return []
    records: list[ArchivedRoomRecord] = []
    for child in children:
        record = _archived_room_record(child)
        if record is not None:
            records.append(record)
    return records


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
                transcripts=list_room_transcripts(child),
                summary_count=_count_markdown_files(child / "summaries"),
                master_prompt=room_master_prompt_record(child),
            )
        )
    return rooms


def _validate_room_id(room_id: str) -> str:
    normalized = room_id.strip()
    if not _safe_room_id(normalized):
        raise ValueError("room_id must be a safe slug: letters, numbers, dot, underscore, or dash")
    return normalized


def count_room_transcripts(room_id: str, root: Path | None = None) -> int:
    safe_room_id = _validate_room_id(room_id)
    rooms_root = root or rooms_root_path()
    return _count_markdown_files(rooms_root / safe_room_id / "transcripts")


def room_archive_preview(room_id: str, root: Path | None = None) -> RoomArchivePreview:
    """Return metadata needed before approving whole-Room archive.

    This intentionally loads metadata only. It does not read raw transcripts,
    approved memory, or Room Master Prompt content.
    """

    safe_room_id = _validate_room_id(room_id)
    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    metadata_file = room_path / "room.md"
    if not room_path.exists() or not room_path.is_dir() or not metadata_file.exists():
        raise FileNotFoundError("Room not found")
    master_prompt = room_master_prompt_record(room_path)
    return RoomArchivePreview(
        room_id=safe_room_id,
        room_name=_room_name_from_metadata(metadata_file, safe_room_id.replace("-", " ").title()),
        room_path=str(room_path),
        transcript_count=_count_markdown_files(room_path / "transcripts"),
        summary_count=_count_markdown_files(room_path / "summaries"),
        master_prompt_status=master_prompt.status,
    )


def archive_room(
    *,
    room_id: str,
    approval_id: str,
    root: Path | None = None,
    archived_at: str | None = None,
) -> RoomArchiveResult:
    """Archive a whole Room after explicit approval.

    Archive is a reversible local move, not hard deletion. It does not delete
    approved memory and does not approve or reuse Room context.
    """

    safe_room_id = _validate_room_id(room_id)
    safe_approval_id = _validate_text_field(approval_id, "approval_id", 120)
    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    if not room_path.exists() or not room_path.is_dir():
        raise FileNotFoundError("Room not found")
    preview = room_archive_preview(safe_room_id, root=rooms_root)
    ts = archived_at or _utc_now()
    archive_root = rooms_root / ".archive"
    archive_root.mkdir(parents=True, exist_ok=True)
    archive_id = f"{safe_room_id}-{_timestamp_slug(ts)}"
    archive_path = archive_root / archive_id
    index = 2
    while archive_path.exists():
        archive_path = archive_root / f"{archive_id}-{index}"
        index += 1
    archive_note = "\n".join(
        [
            f"room_id: {safe_room_id}",
            f"name: {_markdown_value(preview.room_name)}",
            f"archived_at: {ts}",
            f"approval_id: {safe_approval_id}",
            f"original_room_path: {room_path}",
            "archive_type: local_reversible_archive",
            "memory_written: false",
            "approved_memory_deleted: false",
            "context_reuse: disabled_until_user_approved",
            "linked_memory_review: not_available_requires_manual_memory_review",
            "",
        ]
    )

    try:
        room_path.rename(archive_path)
        (archive_path / "archive.md").write_text(archive_note, encoding="utf-8")
    except OSError:
        raise

    return RoomArchiveResult(
        room_id=safe_room_id,
        room_name=preview.room_name,
        original_room_path=str(room_path),
        archived_room_path=str(archive_path),
        archived_at=ts,
        approval_id=safe_approval_id,
        transcript_count=preview.transcript_count,
        summary_count=preview.summary_count,
        master_prompt_status=preview.master_prompt_status,
    )


def delete_room(
    *,
    room_id: str,
    approval_id: str,
    root: Path | None = None,
    deleted_at: str | None = None,
) -> RoomDeleteResult:
    """Permanently delete one local Room folder after explicit approval.

    This removes local Room files only. It does not delete approved memory,
    reused context, external storage, or cloud copies.
    """

    safe_room_id = _validate_room_id(room_id)
    safe_approval_id = _validate_text_field(approval_id, "approval_id", 120)
    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    if not room_path.exists() or not room_path.is_dir():
        raise FileNotFoundError("Room not found")

    preview = room_archive_preview(safe_room_id, rooms_root)
    ts = deleted_at or _utc_now()
    try:
        shutil.rmtree(room_path)
    except OSError:
        raise

    return RoomDeleteResult(
        room_id=safe_room_id,
        room_name=preview.room_name,
        deleted_room_path=str(room_path),
        deleted_at=ts,
        approval_id=safe_approval_id,
        transcript_count=preview.transcript_count,
        summary_count=preview.summary_count,
        master_prompt_status=preview.master_prompt_status,
    )


def restore_archived_room(
    *,
    archive_id: str,
    approval_id: str,
    root: Path | None = None,
    restored_at: str | None = None,
) -> RoomRestoreResult:
    """Restore an archived Room with explicit approval.

    Restore is a local reversible move back into the Rooms root. It does not
    approve Room context reuse, write memory, or restore/delete approved memory.
    """
    safe_archive_id = _validate_room_id(archive_id)
    safe_approval_id = approval_id.strip()
    if not safe_approval_id:
        raise ValueError("approval_id is required to restore an archived Room")
    rooms_root = root or rooms_root_path()
    archive_path = rooms_root / ".archive" / safe_archive_id
    record = _archived_room_record(archive_path)
    if record is None:
        raise FileNotFoundError("Archived Room not found")
    restore_path = rooms_root / record.room_id
    if restore_path.exists():
        raise FileExistsError("A Room with this id already exists; archive restore would overwrite it")
    ts = restored_at or _utc_now()
    restore_note = "\n".join(
        [
            "---",
            f"archive_id: {safe_archive_id}",
            f"room_id: {record.room_id}",
            f"room_name: {record.room_name}",
            f"restored_at: {ts}",
            f"approval_id: {safe_approval_id}",
            "restore_type: local_reversible_restore",
            "memory_written: false",
            "approved_memory_restored: false",
            "context_reuse: disabled_until_user_approved",
            "---",
            "",
            "# Room Restore",
            "",
            "This Room was restored from the local archive. Context reuse still requires separate approval.",
            "",
        ]
    )
    try:
        archive_path.rename(restore_path)
        (restore_path / "restore.md").write_text(restore_note, encoding="utf-8")
    except OSError:
        raise
    return RoomRestoreResult(
        archive_id=safe_archive_id,
        room_id=record.room_id,
        room_name=record.room_name,
        restored_room_path=str(restore_path),
        restored_at=ts,
        approval_id=safe_approval_id,
        transcript_count=record.transcript_count,
        summary_count=record.summary_count,
        master_prompt_status=record.master_prompt_status,
    )


def read_room_transcript(
    *,
    room_id: str,
    transcript_id: str,
    root: Path | None = None,
    max_chars: int = 24000,
) -> RoomTranscriptReadResult:
    """Read one saved transcript after the caller has required approval.

    This is a local file read for chat reopening only. It does not approve the
    transcript as reusable context and does not write memory.
    """

    safe_room_id = _validate_room_id(room_id)
    safe_transcript_id = _validate_room_id(transcript_id)
    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    transcript_path = room_path / "transcripts" / f"{safe_transcript_id}.md"
    if not transcript_path.exists() or not transcript_path.is_file():
        raise FileNotFoundError("Room transcript not found")

    try:
        size_bytes = transcript_path.stat().st_size
    except OSError:
        size_bytes = 0
    raw_text = _read_text_limited(transcript_path, max_chars=max_chars)
    if not raw_text.strip():
        raise ValueError("Room transcript is empty or unreadable")
    transcript_text = _strip_frontmatter(raw_text)
    user_text = _extract_section(transcript_text, "User")
    merlin_text = _extract_section(transcript_text, "Merlin")
    if not user_text or not merlin_text:
        raise ValueError("Room transcript is missing User or Merlin sections")

    return RoomTranscriptReadResult(
        room_id=safe_room_id,
        room_name=_room_name_from_metadata(room_path / "room.md", safe_room_id.replace("-", " ").title()),
        transcript_id=safe_transcript_id,
        transcript_path=str(transcript_path),
        user_input=user_text,
        merlin_response=merlin_text,
        size_bytes=size_bytes,
        modified_at=_file_modified_at(transcript_path),
    )


def delete_room_transcript(
    *,
    room_id: str,
    transcript_id: str,
    approval_id: str,
    root: Path | None = None,
    deleted_at: str | None = None,
) -> RoomTranscriptDeleteResult:
    """Delete one saved local Room transcript after explicit approval."""

    safe_room_id = _validate_room_id(room_id)
    safe_transcript_id = _validate_room_id(transcript_id)
    safe_approval_id = _validate_text_field(approval_id, "approval_id", 120)
    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    transcript_path = room_path / "transcripts" / f"{safe_transcript_id}.md"
    if not transcript_path.exists() or not transcript_path.is_file():
        raise FileNotFoundError("Room transcript not found")

    room_name = _room_name_from_metadata(room_path / "room.md", safe_room_id.replace("-", " ").title())
    ts = deleted_at or _utc_now()
    try:
        transcript_path.unlink()
    except OSError:
        raise

    return RoomTranscriptDeleteResult(
        room_id=safe_room_id,
        room_name=room_name,
        transcript_id=safe_transcript_id,
        transcript_path=str(transcript_path),
        deleted_at=ts,
        approval_id=safe_approval_id,
    )


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
    transcript_title = _transcript_title(safe_user_input)
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
            f"title: {_markdown_value(transcript_title)}",
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
        transcript_title=transcript_title,
        transcript_path=str(transcript_file),
        metadata_file=str(metadata_file),
        created_at=ts,
        approval_id=safe_approval_id,
        bytes_written=len(content.encode("utf-8")),
    )


def _read_text_limited(path: Path, max_chars: int = 6000) -> str:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return ""
    return text[:max_chars]


def _strip_frontmatter(text: str) -> str:
    if not text.startswith("---"):
        return text.strip()
    parts = text.split("---", 2)
    if len(parts) == 3:
        return parts[2].strip()
    return text.strip()


def _extract_section(text: str, heading: str) -> str:
    marker = f"## {heading}"
    if marker not in text:
        return ""
    after = text.split(marker, 1)[1]
    for next_heading in ("\n## ", "\n# "):
        if next_heading in after:
            after = after.split(next_heading, 1)[0]
    return after.strip()


def _compact_line(text: str, max_chars: int = 420) -> str:
    compact = " ".join(text.split())
    if len(compact) <= max_chars:
        return compact
    return compact[: max_chars - 1].rstrip() + "..."


def generate_room_master_prompt_draft(
    *,
    room_id: str,
    room_name: str | None,
    approval_id: str,
    root: Path | None = None,
    generated_at: str | None = None,
    transcript_limit: int = 8,
) -> RoomMasterPromptDraftResult:
    """Generate a local Room Master Prompt draft from saved transcripts.

    This is deterministic local file synthesis. It does not call a model, does
    not approve context reuse, and does not write global approved memory.
    """

    safe_room_id = _validate_room_id(room_id)
    safe_room_name = _validate_text_field(room_name or safe_room_id.replace("-", " ").title(), "room_name", 120)
    safe_approval_id = _validate_text_field(approval_id, "approval_id", 120)
    ts = generated_at or _utc_now()

    rooms_root = root or rooms_root_path()
    room_path = rooms_root / safe_room_id
    transcripts = list_room_transcripts(room_path, limit=transcript_limit)
    if not transcripts:
        raise ValueError("Room Master Prompt requires at least one saved transcript")

    transcript_blocks: list[str] = []
    for record in reversed(transcripts):
        transcript_text = _strip_frontmatter(_read_text_limited(Path(record.path)))
        user_text = _compact_line(_extract_section(transcript_text, "User") or transcript_text)
        merlin_text = _compact_line(_extract_section(transcript_text, "Merlin"))
        transcript_blocks.append(
            "\n".join(
                [
                    f"### Transcript: {record.transcript_id}",
                    "",
                    f"- User intent: {user_text or 'not available'}",
                    f"- Merlin response signal: {merlin_text or 'not available'}",
                ]
            )
        )

    prompt_path = master_prompt_path(room_path)
    tmp_path = prompt_path.with_suffix(".tmp")
    content = "\n".join(
        [
            "---",
            f"room_id: {safe_room_id}",
            f"name: {safe_room_name}",
            "status: draft",
            f"generated_at: {ts}",
            f"approval_id: {safe_approval_id}",
            f"source_transcript_count: {len(transcripts)}",
            "approved_for_context: false",
            "memory_written: false",
            "context_reuse: disabled_until_user_approved",
            "---",
            "",
            "# Room Master Prompt Draft",
            "",
            "## Purpose",
            "",
            f"This prompt condenses the local `{safe_room_name}` Room into scoped context for Merlin. It is a draft and must be reviewed before reuse.",
            "",
            "## Operating Boundary",
            "",
            "- Use this Room context only when the user selects this Room.",
            "- Do not share this context with other Rooms unless the user explicitly enables sharing.",
            "- Do not treat this draft as approved memory.",
            "- Do not infer secrets or private facts that are not present in the Room.",
            "",
            "## Current Room Signals",
            "",
            *transcript_blocks,
            "",
            "## Review Checklist",
            "",
            "- Remove anything that should not be reused.",
            "- Add durable goals, preferences, terminology, and decisions only after user review.",
            "- Approve context reuse separately from transcript storage.",
            "",
        ]
    )

    try:
        prompt_path.parent.mkdir(parents=True, exist_ok=True)
        tmp_path.write_text(content, encoding="utf-8")
        tmp_path.replace(prompt_path)
    except OSError:
        try:
            tmp_path.unlink(missing_ok=True)
        except OSError:
            pass
        raise

    return RoomMasterPromptDraftResult(
        room_id=safe_room_id,
        room_name=safe_room_name,
        status="draft",
        master_prompt_path=str(prompt_path),
        generated_at=ts,
        source_transcript_count=len(transcripts),
        approval_id=safe_approval_id,
        bytes_written=len(content.encode("utf-8")),
    )


def room_manifest() -> dict[str, Any]:
    brain_root = brain_root_path()
    rooms_root = rooms_root_path()
    rooms = list_rooms(rooms_root)
    archived_rooms = list_archived_rooms(rooms_root)
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
        "master_prompt_enabled": False,
        "master_prompt_draft_api_enabled": True,
        "master_prompt_policy": "draft_requires_backend_approval_context_reuse_disabled",
        "room_archive_api_enabled": True,
        "room_archive_policy": "backend_approval_required_local_archive_only",
        "room_restore_api_enabled": True,
        "room_restore_policy": "backend_approval_required_local_restore_only",
        "tracked_issue": "#135",
        "rooms": [room.model_dump() for room in rooms],
        "archived_rooms": [room.model_dump() for room in archived_rooms],
        "archived_total": len(archived_rooms),
        "total": len(rooms),
    }
