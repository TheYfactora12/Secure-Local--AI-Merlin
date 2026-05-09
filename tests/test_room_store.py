from __future__ import annotations

from merlin.room_store import list_rooms, room_manifest


def test_room_manifest_defaults_to_read_only_no_context(monkeypatch, tmp_path) -> None:
    brain_root = tmp_path / "brain"
    monkeypatch.setenv("MERLIN_BRAIN_ROOT", str(brain_root))
    monkeypatch.delenv("MERLIN_ROOMS_ROOT", raising=False)

    manifest = room_manifest()

    assert manifest["mode"] == "read_only_rooms_manifest"
    assert manifest["brain_root"] == str(brain_root)
    assert manifest["rooms_root"] == str(brain_root / "rooms")
    assert manifest["reference_policy"] == "no_room_context"
    assert manifest["active_room"] is None
    assert manifest["save_to_room_enabled"] is False
    assert manifest["memory_extraction_enabled"] is False
    assert manifest["cloud_sync_default"] is False
    assert manifest["browser_file_controls_enabled"] is False
    assert manifest["rooms"] == []


def test_list_rooms_discovers_metadata_without_reading_transcripts(tmp_path) -> None:
    room = tmp_path / "merlin-build"
    transcripts = room / "transcripts"
    summaries = room / "summaries"
    transcripts.mkdir(parents=True)
    summaries.mkdir()
    (room / "room.md").write_text("name: Merlin Build\n", encoding="utf-8")
    (transcripts / "2026-05-09.md").write_text("raw chat stays local", encoding="utf-8")
    (summaries / "2026-05-09-summary.md").write_text("summary", encoding="utf-8")

    records = list_rooms(tmp_path)

    assert len(records) == 1
    record = records[0]
    assert record.room_id == "merlin-build"
    assert record.name == "Merlin Build"
    assert record.transcript_count == 1
    assert record.summary_count == 1
    assert record.reference_policy == "no_room_context"
    assert record.memory_extraction == "requires_approval"
    assert "raw chat stays local" not in record.model_dump_json()


def test_list_rooms_ignores_unsafe_or_incomplete_room_dirs(tmp_path) -> None:
    unsafe = tmp_path / "../unsafe"
    incomplete = tmp_path / "incomplete-room"
    bad_name = tmp_path / "-bad"
    unsafe.mkdir(parents=True, exist_ok=True)
    incomplete.mkdir()
    bad_name.mkdir()
    (bad_name / "room.md").write_text("name: Bad\n", encoding="utf-8")

    records = list_rooms(tmp_path)

    assert records == []


def test_room_manifest_uses_explicit_rooms_root(monkeypatch, tmp_path) -> None:
    brain_root = tmp_path / "brain"
    rooms_root = tmp_path / "custom-rooms"
    monkeypatch.setenv("MERLIN_BRAIN_ROOT", str(brain_root))
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(rooms_root))

    manifest = room_manifest()

    assert manifest["brain_root"] == str(brain_root)
    assert manifest["rooms_root"] == str(rooms_root)
    assert manifest["rooms_root_source"] == "MERLIN_ROOMS_ROOT"
