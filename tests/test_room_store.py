from __future__ import annotations

from merlin.room_store import (
    delete_room_transcript,
    generate_room_master_prompt_draft,
    list_room_transcripts,
    list_rooms,
    read_room_transcript,
    room_manifest,
    save_room_transcript,
)


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
    assert manifest["save_to_room_api_enabled"] is True
    assert manifest["save_to_room_policy"] == "backend_approval_required"
    assert manifest["master_prompt_enabled"] is False
    assert manifest["master_prompt_draft_api_enabled"] is True
    assert manifest["master_prompt_policy"] == "draft_requires_backend_approval_context_reuse_disabled"
    assert manifest["memory_extraction_enabled"] is False
    assert manifest["cloud_sync_default"] is False
    assert manifest["browser_file_controls_enabled"] is False
    assert manifest["browser_save_controls_enabled"] is False
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
    assert len(record.transcripts) == 1
    assert record.transcripts[0].transcript_id == "2026-05-09"
    assert record.transcripts[0].raw_content_loaded is False
    assert record.summary_count == 1
    assert record.master_prompt is not None
    assert record.master_prompt.status == "missing"
    assert record.master_prompt.raw_content_loaded is False
    assert record.reference_policy == "no_room_context"
    assert record.memory_extraction == "requires_approval"
    assert "raw chat stays local" not in record.model_dump_json()


def test_list_room_transcripts_returns_metadata_without_raw_content(tmp_path) -> None:
    room = tmp_path / "merlin-build"
    transcripts = room / "transcripts"
    transcripts.mkdir(parents=True)
    (transcripts / "2026-05-09-a.md").write_text("private transcript one", encoding="utf-8")
    (transcripts / "2026-05-09-b.md").write_text("private transcript two", encoding="utf-8")

    records = list_room_transcripts(room)

    assert [record.transcript_id for record in records] == ["2026-05-09-b", "2026-05-09-a"]
    assert all(record.size_bytes > 0 for record in records)
    assert all(record.raw_content_loaded is False for record in records)
    assert "private transcript" not in str([record.model_dump() for record in records])


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


def test_save_room_transcript_writes_local_markdown_without_memory(tmp_path) -> None:
    result = save_room_transcript(
        room_id="merlin-build",
        room_name="Merlin Build",
        user_input="What are we building?",
        merlin_response="A local-first Merlin product.",
        session_id="session-1",
        approval_id="approval-1",
        root=tmp_path,
        created_at="2026-05-09T12:00:00+00:00",
    )
    transcript = (tmp_path / "merlin-build" / "transcripts" / f"{result.transcript_id}.md").read_text(
        encoding="utf-8"
    )

    assert result.room_id == "merlin-build"
    assert result.room_name == "Merlin Build"
    assert result.approved_memory_written is False
    assert result.memory_extraction == "not_performed_requires_separate_approval"
    assert "What are we building?" in transcript
    assert "A local-first Merlin product." in transcript
    assert "memory_extraction: not_performed_requires_separate_approval" in transcript
    assert (tmp_path / "merlin-build" / "room.md").exists()


def test_save_room_transcript_requires_safe_room_id(tmp_path) -> None:
    try:
        save_room_transcript(
            room_id="../bad",
            room_name="Bad",
            user_input="hello",
            merlin_response="hi",
            session_id="session-1",
            approval_id="approval-1",
            root=tmp_path,
        )
    except ValueError as exc:
        assert "room_id must be a safe slug" in str(exc)
    else:
        raise AssertionError("unsafe room ids must be rejected")


def test_save_room_transcript_requires_approval_id(tmp_path) -> None:
    try:
        save_room_transcript(
            room_id="merlin-build",
            room_name="Merlin Build",
            user_input="hello",
            merlin_response="hi",
            session_id="session-1",
            approval_id=" ",
            root=tmp_path,
        )
    except ValueError as exc:
        assert "approval_id must not be empty" in str(exc)
    else:
        raise AssertionError("approval_id must be required")


def test_read_room_transcript_returns_selected_local_chat_without_memory(tmp_path) -> None:
    saved = save_room_transcript(
        room_id="merlin-build",
        room_name="Merlin Build",
        user_input="What should the chat do?",
        merlin_response="Reopen saved Room chats only after approval.",
        session_id="session-1",
        approval_id="approval-1",
        root=tmp_path,
        created_at="2026-05-09T12:00:00+00:00",
    )

    result = read_room_transcript(
        room_id="merlin-build",
        transcript_id=saved.transcript_id,
        root=tmp_path,
    )

    assert result.room_id == "merlin-build"
    assert result.room_name == "Merlin Build"
    assert result.transcript_id == saved.transcript_id
    assert result.user_input == "What should the chat do?"
    assert result.merlin_response == "Reopen saved Room chats only after approval."
    assert result.raw_content_loaded is True
    assert result.memory_written is False
    assert result.context_reuse == "disabled_until_user_approved"


def test_read_room_transcript_rejects_unsafe_transcript_id(tmp_path) -> None:
    try:
        read_room_transcript(
            room_id="merlin-build",
            transcript_id="../bad",
            root=tmp_path,
        )
    except ValueError as exc:
        assert "room_id must be a safe slug" in str(exc)
    else:
        raise AssertionError("unsafe transcript ids must be rejected")


def test_delete_room_transcript_removes_one_saved_session_only(tmp_path) -> None:
    first = save_room_transcript(
        room_id="merlin-build",
        room_name="Merlin Build",
        user_input="First session",
        merlin_response="Keep this one.",
        session_id="session-1",
        approval_id="approval-1",
        root=tmp_path,
        created_at="2026-05-09T12:00:00+00:00",
    )
    second = save_room_transcript(
        room_id="merlin-build",
        room_name="Merlin Build",
        user_input="Second session",
        merlin_response="Delete this one.",
        session_id="session-2",
        approval_id="approval-2",
        root=tmp_path,
        created_at="2026-05-09T13:00:00+00:00",
    )

    result = delete_room_transcript(
        room_id="merlin-build",
        transcript_id=second.transcript_id,
        approval_id="approval-delete-1",
        root=tmp_path,
        deleted_at="2026-05-09T14:00:00+00:00",
    )

    assert result.room_id == "merlin-build"
    assert result.transcript_id == second.transcript_id
    assert result.memory_written is False
    assert result.context_reuse == "disabled_until_user_approved"
    assert (tmp_path / "merlin-build" / "transcripts" / f"{first.transcript_id}.md").exists()
    assert not (tmp_path / "merlin-build" / "transcripts" / f"{second.transcript_id}.md").exists()
    assert (tmp_path / "merlin-build" / "room.md").exists()


def test_generate_room_master_prompt_draft_requires_transcript(tmp_path) -> None:
    try:
        generate_room_master_prompt_draft(
            room_id="merlin-build",
            room_name="Merlin Build",
            approval_id="approval-1",
            root=tmp_path,
        )
    except ValueError as exc:
        assert "requires at least one saved transcript" in str(exc)
    else:
        raise AssertionError("Room Master Prompt draft must require saved transcripts")


def test_generate_room_master_prompt_draft_writes_local_draft_without_memory(tmp_path) -> None:
    save_room_transcript(
        room_id="merlin-build",
        room_name="Merlin Build",
        user_input="We need an Apple-like local AI chat.",
        merlin_response="Focus on Rooms, local context, and approval-gated memory.",
        session_id="session-1",
        approval_id="approval-transcript-1",
        root=tmp_path,
        created_at="2026-05-09T12:00:00+00:00",
    )

    result = generate_room_master_prompt_draft(
        room_id="merlin-build",
        room_name="Merlin Build",
        approval_id="approval-master-1",
        root=tmp_path,
        generated_at="2026-05-09T13:00:00+00:00",
    )
    prompt_path = tmp_path / "merlin-build" / "master-prompts" / "master-prompt.md"
    prompt_text = prompt_path.read_text(encoding="utf-8")
    records = list_rooms(tmp_path)

    assert result.status == "draft"
    assert result.master_prompt_path == str(prompt_path)
    assert result.source_transcript_count == 1
    assert result.memory_written is False
    assert result.approved_for_context is False
    assert "status: draft" in prompt_text
    assert "approved_for_context: false" in prompt_text
    assert "memory_written: false" in prompt_text
    assert "context_reuse: disabled_until_user_approved" in prompt_text
    assert "Use this Room context only when the user selects this Room." in prompt_text
    assert "We need an Apple-like local AI chat." in prompt_text
    assert records[0].master_prompt is not None
    assert records[0].master_prompt.status == "draft"
    assert records[0].master_prompt.raw_content_loaded is False
    assert "We need an Apple-like local AI chat." not in records[0].model_dump_json()
