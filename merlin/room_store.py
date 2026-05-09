"""Read-only Merlin Rooms manifest helpers.

Rooms are local chat/project context containers. This first #135 runtime slice
does not write transcripts, indexes, or memory. It only discovers a configured
Rooms root and any existing Room folders with a `room.md` metadata file so
Wizard HQ can show honest state before save-to-Room support exists.
"""

from __future__ import annotations

import os
import re
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


def brain_root_path() -> Path:
    override = os.environ.get("MERLIN_BRAIN_ROOT")
    return Path(override).expanduser() if override else DEFAULT_BRAIN_ROOT


def rooms_root_path() -> Path:
    override = os.environ.get("MERLIN_ROOMS_ROOT")
    return Path(override).expanduser() if override else brain_root_path() / "rooms"


def _safe_room_id(value: str) -> bool:
    return bool(ROOM_SLUG_PATTERN.fullmatch(value))


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
        "memory_extraction_enabled": False,
        "cloud_sync_default": False,
        "browser_file_controls_enabled": False,
        "tracked_issue": "#135",
        "rooms": [room.model_dump() for room in rooms],
        "total": len(rooms),
    }
