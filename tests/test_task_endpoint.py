from __future__ import annotations

import httpx
from fastapi.testclient import TestClient

from merlin.persona_injector import IDENTITY_AND_LANGUAGE_BLOCK, PI_WARMTH_BLOCK, build_system_prompt
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
    assert detail["approval_supported"] is True
    assert detail["approval_scope"] == "one_time_local_model_call"
    assert detail["session_id"]


def test_task_route_approval_allows_one_local_model_call_without_raw_prompt(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())

    payload = {"input": "write a python function", "session_id": "session-route-1"}
    approval_response = client.post("/approvals/task-route", json=payload)
    approval_body = approval_response.json()

    assert approval_response.status_code == 200
    assert approval_body["status"] == "required_pending"
    assert approval_body["action"] == "task_route_model_call"
    assert approval_body["execution_allowed"] is False
    assert approval_body["payload_summary"]["raw_content_in_approval"] is False
    assert approval_body["payload_summary"]["tool_execution"] == "none"
    assert approval_body["payload_summary"]["memory_write"] is False
    assert approval_body["payload_summary"]["cloud_calls"] == "none"
    assert "write a python function" not in str(approval_body)

    approval_id = approval_body["approval_request_id"]
    decision_response = client.post(f"/approvals/{approval_id}/approve")
    assert decision_response.status_code == 200
    assert decision_response.json()["execution_allowed"] is True

    response = client.post("/task", json={**payload, "approval_id": approval_id})
    assert response.status_code == 200
    body = response.json()
    assert body["response"] == "Merlin response"
    assert body["route"]["route_id"] == "code"
    assert body["approved"] is True
    assert body["memory_written"] is False

    reused_response = client.post("/task", json={**payload, "approval_id": approval_id})
    assert reused_response.status_code == 403
    assert "not approved" in reused_response.json()["detail"]["message"]


def test_model_only_chat_allows_protected_route_without_tool_approval(monkeypatch) -> None:
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", lambda *args, **kwargs: _FakeLiteLLMResponse())

    response = client.post("/task", json={"input": "write a python function", "model_only": True})

    assert response.status_code == 200
    body = response.json()
    assert body["response"] == "Merlin response"
    assert body["route"]["route_id"] == "code"
    assert body["route"]["requires_approval"] is True
    assert body["route"]["approval_gates"] == [
        "service_start",
        "file_read",
        "file_write",
        "shell_command",
        "git_operation",
        "openhands_task",
    ]
    assert body["approved"] is True
    assert body["memory_written"] is False


def test_task_route_approval_rejects_prompt_mismatch(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)

    approval_response = client.post(
        "/approvals/task-route",
        json={"input": "write a python function", "session_id": "session-route-1"},
    )
    approval_id = approval_response.json()["approval_request_id"]
    client.post(f"/approvals/{approval_id}/approve")

    mismatch = client.post(
        "/task",
        json={
            "input": "write a javascript function",
            "session_id": "session-route-1",
            "approval_id": approval_id,
        },
    )

    assert mismatch.status_code == 403
    assert "payload hash" in mismatch.json()["detail"]["message"]


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


def test_system_prompt_prevents_model_identity_and_language_drift() -> None:
    route = route_task("explain how RAG works")
    prompt = build_system_prompt(route)

    assert IDENTITY_AND_LANGUAGE_BLOCK in prompt
    assert "You are Merlin AI" in prompt
    assert "Never identify as Qwen" in prompt
    assert "Respond in clear English unless the user explicitly asks for another language." in prompt
    assert f"Technical engine alias for this task: {route.selected_model_alias}" in prompt
    assert "If the user asks what model was used, answer with this engine alias" in prompt


def test_task_endpoint_sends_merlin_identity_guard_to_litellm(monkeypatch) -> None:
    captured = {}

    def fake_post(*args, **kwargs):
        captured.update(kwargs)
        return _FakeLiteLLMResponse()

    monkeypatch.setattr("merlin.task_endpoint.observe_task_outcome", _noop_outcome_observer)
    monkeypatch.setattr("merlin.task_endpoint.httpx.post", fake_post)

    response = client.post("/task", json={"input": "who are you?"})

    assert response.status_code == 200
    system_message = captured["json"]["messages"][0]["content"]
    assert "You are Merlin AI" in system_message
    assert "Never identify as Qwen" in system_message
    assert "Respond in clear English unless the user explicitly asks for another language." in system_message
    assert "Technical engine alias for this task:" in system_message


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


def test_create_room_endpoint_writes_local_metadata_without_memory(tmp_path, monkeypatch) -> None:
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-room-create-1"

    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    response = client.post("/rooms", json={"room_name": "Client Risk Review"})
    body = response.json()

    assert response.status_code == 200
    assert body["status"] == "created_local_room_only"
    assert body["room_id"] == "client-risk-review"
    assert body["room_name"] == "Client Risk Review"
    assert body["memory_written"] is False
    assert body["context_reuse"] == "disabled_until_user_approved"
    assert body["audit_id"] == "audit-room-create-1"
    assert (tmp_path / "rooms" / "client-risk-review" / "room.md").exists()
    assert audit_calls[0][0] == "room_create"
    assert audit_calls[0][1]["raw_transcript_in_audit"] is False


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
    assert body["transcript_title"] == "What are we building?"
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
    reused_response = client.post(
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
    assert reused_response.status_code == 403
    assert "approval is not approved for execution" in reused_response.text


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


def test_read_room_transcript_requires_approval_id() -> None:
    response = client.post(
        "/rooms/transcripts/read",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": "2026-05-09",
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"]["approval_gates"] == ["file_read"]
    assert response.json()["detail"]["memory_written"] is False


def test_read_room_transcript_requires_matching_one_time_approval(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-read-1"

    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    transcript_approval = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "A local Room reopen flow.",
            "session_id": "session-1",
        },
    )
    transcript_approval_id = transcript_approval.json()["approval_request_id"]
    client.post(f"/approvals/{transcript_approval_id}/approve")
    save_response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "What are we building?",
            "merlin_response": "A local Room reopen flow.",
            "session_id": "session-1",
            "approval_id": transcript_approval_id,
        },
    )
    transcript_id = save_response.json()["transcript_id"]

    read_without_read_approval = client.post(
        "/rooms/transcripts/read",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": transcript_id,
            "approval_id": transcript_approval_id,
        },
    )
    assert read_without_read_approval.status_code == 403
    assert "approval is not approved for execution" in read_without_read_approval.text

    approval_response = client.post(
        "/approvals/room-transcript-read",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": transcript_id,
        },
    )
    approval_id = approval_response.json()["approval_request_id"]
    assert approval_response.json()["approval_gates"] == ["file_read"]
    assert approval_response.json()["payload_summary"]["raw_content_in_approval"] is False
    client.post(f"/approvals/{approval_id}/approve")

    response = client.post(
        "/rooms/transcripts/read",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": transcript_id,
            "approval_id": approval_id,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "read_local_transcript_only"
    assert body["user_input"] == "What are we building?"
    assert body["merlin_response"] == "A local Room reopen flow."
    assert body["memory_written"] is False
    assert body["context_reuse"] == "disabled_until_user_approved"
    assert body["raw_content_loaded"] is True
    assert audit_calls[-1][0] == "room_transcript_read"
    assert audit_calls[-1][1]["raw_transcript_in_audit"] is False
    assert "A local Room reopen flow." not in str(audit_calls[-1][1])

    reused_response = client.post(
        "/rooms/transcripts/read",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": transcript_id,
            "approval_id": approval_id,
        },
    )
    assert reused_response.status_code == 403
    assert "approval is not approved for execution" in reused_response.text


def test_delete_room_transcript_requires_approval_id() -> None:
    response = client.post(
        "/rooms/transcripts/delete",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": "2026-05-09",
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"]["approval_gates"] == ["file_delete"]
    assert response.json()["detail"]["memory_written"] is False


def test_delete_room_transcript_requires_matching_one_time_approval(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-delete-1"

    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    first_approval = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Keep first transcript",
            "merlin_response": "First saved transcript.",
            "session_id": "session-1",
        },
    )
    first_approval_id = first_approval.json()["approval_request_id"]
    client.post(f"/approvals/{first_approval_id}/approve")
    first_save = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Keep first transcript",
            "merlin_response": "First saved transcript.",
            "session_id": "session-1",
            "approval_id": first_approval_id,
        },
    )
    first_transcript_id = first_save.json()["transcript_id"]

    second_approval = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Delete second transcript",
            "merlin_response": "Second saved transcript.",
            "session_id": "session-2",
        },
    )
    second_approval_id = second_approval.json()["approval_request_id"]
    client.post(f"/approvals/{second_approval_id}/approve")
    second_save = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Delete second transcript",
            "merlin_response": "Second saved transcript.",
            "session_id": "session-2",
            "approval_id": second_approval_id,
        },
    )
    second_transcript_id = second_save.json()["transcript_id"]

    delete_without_delete_approval = client.post(
        "/rooms/transcripts/delete",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": second_transcript_id,
            "approval_id": second_approval_id,
        },
    )
    assert delete_without_delete_approval.status_code == 403
    assert "approval is not approved for execution" in delete_without_delete_approval.text

    delete_approval = client.post(
        "/approvals/room-transcript-delete",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": second_transcript_id,
        },
    )
    delete_approval_id = delete_approval.json()["approval_request_id"]
    assert delete_approval.json()["approval_gates"] == ["file_delete"]
    assert delete_approval.json()["payload_summary"]["raw_content_in_approval"] is False
    client.post(f"/approvals/{delete_approval_id}/approve")

    response = client.post(
        "/rooms/transcripts/delete",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": second_transcript_id,
            "approval_id": delete_approval_id,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "deleted_local_transcript_only"
    assert body["transcript_id"] == second_transcript_id
    assert body["memory_written"] is False
    assert body["context_reuse"] == "disabled_until_user_approved"
    assert audit_calls[-1][0] == "room_transcript_delete"
    assert audit_calls[-1][1]["raw_transcript_in_audit"] is False
    assert "Second saved transcript." not in str(audit_calls[-1][1])
    assert (tmp_path / "rooms" / "merlin-build" / "transcripts" / f"{first_transcript_id}.md").exists()
    assert not (tmp_path / "rooms" / "merlin-build" / "transcripts" / f"{second_transcript_id}.md").exists()

    reused_response = client.post(
        "/rooms/transcripts/delete",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_id": first_transcript_id,
            "approval_id": delete_approval_id,
        },
    )
    assert reused_response.status_code == 403
    assert "approval is not approved for execution" in reused_response.text


def test_archive_room_requires_approval_id() -> None:
    response = client.post(
        "/rooms/archive",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 0,
            "summary_count": 0,
            "master_prompt_status": "missing",
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"]["approval_gates"] == ["file_archive"]
    assert response.json()["detail"]["memory_written"] is False
    assert response.json()["detail"]["approved_memory_deleted"] is False


def test_archive_room_requires_matching_one_time_approval(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-archive-1"

    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    transcript_approval = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Archive Room after this",
            "merlin_response": "Archive safely without deleting memory.",
            "session_id": "session-archive",
        },
    )
    transcript_approval_id = transcript_approval.json()["approval_request_id"]
    client.post(f"/approvals/{transcript_approval_id}/approve")
    save_response = client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Archive Room after this",
            "merlin_response": "Archive safely without deleting memory.",
            "session_id": "session-archive",
            "approval_id": transcript_approval_id,
        },
    )
    assert save_response.status_code == 200

    archive_approval = client.post(
        "/approvals/room-archive",
        json={"room_id": "merlin-build", "room_name": "Merlin Build"},
    )
    assert archive_approval.status_code == 200
    approval_body = archive_approval.json()
    assert approval_body["approval_gates"] == ["file_archive"]
    assert approval_body["payload_summary"]["raw_content_in_approval"] is False
    assert approval_body["payload_summary"]["approved_memory_delete"] is False
    assert approval_body["payload_summary"]["transcript_count"] == 1
    archive_approval_id = approval_body["approval_request_id"]

    blocked = client.post(
        "/rooms/archive",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": archive_approval_id,
        },
    )
    assert blocked.status_code == 403
    assert "approval is not approved for execution" in blocked.text

    client.post(f"/approvals/{archive_approval_id}/approve")
    response = client.post(
        "/rooms/archive",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": archive_approval_id,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "archived_local_room_only"
    assert body["memory_written"] is False
    assert body["approved_memory_deleted"] is False
    assert body["context_reuse"] == "disabled_until_user_approved"
    assert body["linked_memory_review"] == "not_available_requires_manual_memory_review"
    assert not (tmp_path / "rooms" / "merlin-build").exists()
    assert (tmp_path / "rooms" / ".archive").is_dir()
    assert audit_calls[-1][0] == "room_archive"
    assert audit_calls[-1][1]["raw_transcript_in_audit"] is False
    assert audit_calls[-1][1]["approved_memory_deleted"] is False
    assert "Archive safely without deleting memory." not in str(audit_calls[-1][1])

    reused = client.post(
        "/rooms/archive",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": archive_approval_id,
        },
    )
    assert reused.status_code == 404


def test_restore_room_requires_matching_one_time_approval(tmp_path, monkeypatch) -> None:
    monkeypatch.setenv("MERLIN_ROOMS_ROOT", str(tmp_path / "rooms"))
    monkeypatch.setenv("MERLIN_APPROVAL_LOG", str(tmp_path / "approvals.jsonl"))
    audit_calls = []

    class FakeMemoryManager:
        def write_audit_event(self, event_type: str, metadata: dict) -> str:
            audit_calls.append((event_type, metadata))
            return "audit-restore-1"

    monkeypatch.setattr("merlin.task_endpoint.MemoryManager", FakeMemoryManager)

    transcript_approval = client.post(
        "/approvals/room-transcript",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Restore Room after this",
            "merlin_response": "Restore safely without approving context reuse.",
            "session_id": "session-restore",
        },
    )
    transcript_approval_id = transcript_approval.json()["approval_request_id"]
    client.post(f"/approvals/{transcript_approval_id}/approve")
    assert client.post(
        "/rooms/transcripts",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "user_input": "Restore Room after this",
            "merlin_response": "Restore safely without approving context reuse.",
            "session_id": "session-restore",
            "approval_id": transcript_approval_id,
        },
    ).status_code == 200

    archive_approval = client.post(
        "/approvals/room-archive",
        json={"room_id": "merlin-build", "room_name": "Merlin Build"},
    )
    archive_approval_id = archive_approval.json()["approval_request_id"]
    client.post(f"/approvals/{archive_approval_id}/approve")
    archive_response = client.post(
        "/rooms/archive",
        json={
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": archive_approval_id,
        },
    )
    assert archive_response.status_code == 200
    archive_id = archive_response.json()["archived_room_path"].split("/")[-1]

    restore_without_approval = client.post(
        "/rooms/restore",
        json={
            "archive_id": archive_id,
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
        },
    )
    assert restore_without_approval.status_code == 403
    assert restore_without_approval.json()["detail"]["approval_gates"] == ["file_restore"]
    assert restore_without_approval.json()["detail"]["memory_written"] is False

    restore_approval = client.post(
        "/approvals/room-restore",
        json={"archive_id": archive_id},
    )
    assert restore_approval.status_code == 200
    approval_body = restore_approval.json()
    assert approval_body["approval_gates"] == ["file_restore"]
    assert approval_body["payload_summary"]["raw_content_in_approval"] is False
    assert approval_body["payload_summary"]["approved_memory_restore"] is False
    restore_approval_id = approval_body["approval_request_id"]

    blocked = client.post(
        "/rooms/restore",
        json={
            "archive_id": archive_id,
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": restore_approval_id,
        },
    )
    assert blocked.status_code == 403
    assert "approval is not approved for execution" in blocked.text

    client.post(f"/approvals/{restore_approval_id}/approve")
    response = client.post(
        "/rooms/restore",
        json={
            "archive_id": archive_id,
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": restore_approval_id,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "restored_local_room_only"
    assert body["memory_written"] is False
    assert body["approved_memory_restored"] is False
    assert body["context_reuse"] == "disabled_until_user_approved"
    assert (tmp_path / "rooms" / "merlin-build").is_dir()
    assert not (tmp_path / "rooms" / ".archive" / archive_id).exists()
    assert audit_calls[-1][0] == "room_restore"
    assert audit_calls[-1][1]["raw_transcript_in_audit"] is False
    assert audit_calls[-1][1]["approved_memory_restored"] is False
    assert "Restore safely without approving context reuse." not in str(audit_calls[-1][1])

    reused = client.post(
        "/rooms/restore",
        json={
            "archive_id": archive_id,
            "room_id": "merlin-build",
            "room_name": "Merlin Build",
            "transcript_count": 1,
            "summary_count": 0,
            "master_prompt_status": "missing",
            "approval_id": restore_approval_id,
        },
    )
    assert reused.status_code == 404


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
