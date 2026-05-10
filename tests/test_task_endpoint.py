from __future__ import annotations

import httpx
from fastapi.testclient import TestClient

from merlin.persona_injector import PI_WARMTH_BLOCK, build_system_prompt
from merlin.router import route_task
from merlin.task_endpoint import app


client = TestClient(app)


class _FakeLiteLLMResponse:
    def raise_for_status(self) -> None:
        return None

    def json(self) -> dict:
        return {"choices": [{"message": {"content": "Merlin response"}}]}


def _noop_outcome_observer(**kwargs):
    return None


def test_task_endpoint_tests_do_not_write_outcome_logs_by_default(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())

    response = client.post("/task", json={"input": "explain how RAG works"})

    assert response.status_code == 200


def test_post_task_with_valid_input_routes_correctly(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())

    response = client.post("/task", json={"input": "explain how RAG works"})

    assert response.status_code == 200
    body = response.json()
    assert body["response"] == "Merlin response"
    assert body["route"]["route_id"] == "general"
    assert body["approved"] is True
    assert body["memory_written"] is False


def test_litellm_call_includes_authorization_header(monkeypatch) -> None:
    captured = {}

    def fake_post(*args, **kwargs):
        captured.update(kwargs)
        return _FakeLiteLLMResponse()

    monkeypatch.setenv("LITELLM_MASTER_KEY", "test-local-key")
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", fake_post)

    response = client.post("/task", json={"input": "explain routing"})

    assert response.status_code == 200
    assert captured["headers"] == {"Authorization": "Bearer test-local-key"}


def test_post_task_with_empty_string_returns_400() -> None:
    response = client.post("/task", json={"input": "   "})
    assert response.status_code == 400


def test_post_task_with_input_exceeding_4000_chars_returns_400() -> None:
    response = client.post("/task", json={"input": "x" * 4001})
    assert response.status_code == 400


def test_post_task_route_requiring_approval_returns_403_with_gates(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)

    response = client.post("/task", json={"input": "write a python function"})

    assert response.status_code == 403
    detail = response.json()["detail"]
    assert detail["route_id"] == "code"
    assert detail["route"]["route_id"] == "code"
    assert detail["route"]["staff_mode"] == "software_engineer"
    assert detail["route"]["selected_model_alias"]
    assert detail["approval_gates"] == [
        "service_start",
        "file_read",
        "file_write",
        "shell_command",
        "git_operation",
        "openhands_task",
    ]


def test_post_task_when_litellm_unreachable_returns_degraded_response(monkeypatch) -> None:
    def raise_connect_error(*args, **kwargs):
        raise httpx.ConnectError("unreachable")

    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", raise_connect_error)

    response = client.post("/task", json={"input": "explain how Qdrant works"})

    assert response.status_code == 200
    body = response.json()
    assert body["response"] == "Merlin is starting up. Try again in 30 seconds."
    assert body["route"] == {}
    assert body["approved"] is False
    assert body["degraded"] is True


def test_system_prompt_contains_persona_name_merlin() -> None:
    prompt = build_system_prompt(route_task("explain how RAG works"))
    assert "Name: Merlin" in prompt


def test_system_prompt_contains_guardian_ethos_commitment_text() -> None:
    prompt = build_system_prompt(route_task("explain how RAG works"))
    assert "Protect human agency; Merlin advises and assists but does not rule." in prompt


def test_pi_warmth_block_is_present_in_every_system_prompt() -> None:
    prompt = build_system_prompt(route_task("explain how RAG works"))
    assert PI_WARMTH_BLOCK in prompt


def test_save_room_transcript_requires_approval_id() -> None:
    response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "Merlin Rooms.",
            "session_id": "session-1",
        },
    )

    assert response.status_code == 403
    detail = response.json()["detail"]
    assert "file_write" in detail["approval_gates"]
    assert detail["memory_extraction"] == "not_performed_requires_separate_approval"


def test_save_room_transcript_writes_local_file_without_memory(tmp_path, monkeypatch) -> None:
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-room-1"

    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    approval_response = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "Merlin Rooms.",
            "session_id": "session-1",
        },
    )
    approval_body = approval_response.json()
    approval_id = approval_body["approval_request_id"]
    decision_response = client.post(f"/approvals/{approval_id}/approve")

    assert approval_response.status_code == 200
    assert approval_body["status"] == "required_pending"
    assert approval_body["execution_allowed"] is False
    assert approval_body["payload_summary"]["raw_content_in_approval"] is False
    assert "What are we building?" not in str(approval_body)
    assert decision_response.status_code == 200
    assert decision_response.json()["execution_allowed"] is True

    response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "Merlin Rooms.",
            "session_id": "session-1",
            "approval_id": approval_id,
        },
    )
    body = response.json()
    transcript_text = (tmp_path / "rooms" / "merlin-build" / "transcripts" / f"{body['transcript_id']}.md").read_text(
        encoding="utf-8"
    )

    assert response.status_code == 200
    assert body["status"] == "saved_local_transcript_only"
    assert body["memory_written"] is False
    assert body["memory_extraction"] == "not_performed_requires_separate_approval"
    assert body["audit_id"] == "audit-room-1"
    assert "What are we building?" in transcript_text
    assert "Merlin Rooms." in transcript_text
    assert audit_calls[0][0] == "room_transcript_save"
    assert audit_calls[0][1]["approval_id"] == approval_id
    assert audit_calls[0][1]["raw_transcript_in_audit"] is False
    assert "What are we building?" not in str(audit_calls[0][1])
    assert "Merlin Rooms." not in str(audit_calls[0][1])


def test_save_room_transcript_rejects_unapproved_or_mismatched_approval(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))

    approval_response = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "Merlin Rooms.",
            "session_id": "session-1",
        },
    )
    approval_id = approval_response.json()["approval_request_id"]

    pending_response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "Merlin Rooms.",
            "session_id": "session-1",
            "approval_id": approval_id,
        },
    )
    assert pending_response.status_code == 403
    assert "not approved" in pending_response.json()["detail"]["message"]

    client.post(f"/approvals/{approval_id}/approve")
    mismatched_response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Changed input",
            "merlin_response": "Merlin Rooms.",
            "session_id": "session-1",
            "approval_id": approval_id,
        },
    )
    assert mismatched_response.status_code == 403
    assert "payload hash" in mismatched_response.json()["detail"]["message"]


def test_save_room_transcript_rejects_unsafe_room_id(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))

    approval_response = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "../bad",
            "room_name": "Bad",
            "user_input": "hello",
            "merlin_response": "hi",
            "session_id": "session-1",
        },
    )
    approval_id = approval_response.json()["approval_request_id"]
    client.post(f"/approvals/{approval_id}/approve")

    response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "../bad",
            "room_name": "Bad",
            "user_input": "hello",
            "merlin_response": "hi",
            "session_id": "session-1",
            "approval_id": approval_id,
        },
    )

    assert response.status_code == 400


def test_room_master_prompt_approval_requires_saved_transcript(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))

    response = client.post(
        "/approvals/room-master-prompt",
        json={"room_id": "merlin-build", "room_name": "Merlin Build"},
    )

    assert response.status_code == 400
    assert "requires at least one saved transcript" in response.json()["detail"]


def test_room_master_prompt_draft_requires_approved_gate(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))

    approval_response = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "A Room-scoped local brain.",
            "session_id": "session-1",
        },
    )
    transcript_approval_id = approval_response.json()["approval_request_id"]
    client.post(f"/approvals/{transcript_approval_id}/approve")
    client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "A Room-scoped local brain.",
            "session_id": "session-1",
            "approval_id": transcript_approval_id,
        },
    )

    prepare_response = client.post(
        "/approvals/room-master-prompt",
        json={"room_id": "merlin-build", "room_name": "Merlin Build"},
    )
    approval_body = prepare_response.json()
    approval_id = approval_body["approval_request_id"]

    pending_response = client.post(
        "/rooms/master-prompt-drafts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "source_transcript_count": 1,
            "approval_id": approval_id,
        },
    )
    assert prepare_response.status_code == 200
    assert approval_body["action"] == "room_master_prompt_draft"
    assert approval_body["approval_gates"] == ["file_write"]
    assert approval_body["payload_summary"]["memory_write"] is False
    assert approval_body["payload_summary"]["context_reuse"] == "disabled_until_user_approved"
    assert "What are we building?" not in str(approval_body)
    assert pending_response.status_code == 403
    assert "not approved" in pending_response.json()["detail"]["message"]


def test_room_master_prompt_draft_writes_local_file_without_context_reuse(tmp_path, monkeypatch) -> None:
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-room-master-1"

    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    transcript_approval_response = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Build Room Master Prompts.",
            "merlin_response": "Generate local drafts only after approval.",
            "session_id": "session-1",
        },
    )
    transcript_approval_id = transcript_approval_response.json()["approval_request_id"]
    client.post(f"/approvals/{transcript_approval_id}/approve")
    client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Build Room Master Prompts.",
            "merlin_response": "Generate local drafts only after approval.",
            "session_id": "session-1",
            "approval_id": transcript_approval_id,
        },
    )

    master_approval_response = client.post(
        "/approvals/room-master-prompt",
        json={"room_id": "merlin-build", "room_name": "Merlin Build"},
    )
    master_approval_id = master_approval_response.json()["approval_request_id"]
    client.post(f"/approvals/{master_approval_id}/approve")

    response = client.post(
        "/rooms/master-prompt-drafts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "source_transcript_count": 1,
            "approval_id": master_approval_id,
        },
    )
    body = response.json()
    prompt_path = tmp_path / "rooms" / "merlin-build" / "master-prompts" / "master-prompt.md"
    prompt_text = prompt_path.read_text(encoding="utf-8")

    assert response.status_code == 200
    assert body["status"] == "draft_saved_local_only"
    assert body["master_prompt_path"] == str(prompt_path)
    assert body["memory_written"] is False
    assert body["approved_for_context"] is False
    assert body["context_reuse"] == "disabled_until_user_approved"
    assert body["audit_id"] == "audit-room-master-1"
    assert "Build Room Master Prompts." in prompt_text
    assert "approved_for_context: false" in prompt_text
    assert audit_calls[-1][0] == "room_master_prompt_draft"
    assert audit_calls[-1][1]["raw_prompt_in_audit"] is False
    assert audit_calls[-1][1]["raw_transcript_in_audit"] is False
    assert "Build Room Master Prompts." not in str(audit_calls[-1][1])
