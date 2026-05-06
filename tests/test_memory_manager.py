from __future__ import annotations

from typing import Any

import pytest

from merlin.config_loader import DimensionMismatchError
from merlin.memory_manager import MemoryManager


def _vector(dimensions: int) -> list[float]:
    return [0.01] * dimensions


def _manager(monkeypatch: pytest.MonkeyPatch) -> MemoryManager:
    monkeypatch.setattr(MemoryManager, "_check_qdrant", lambda self: None)
    return MemoryManager()


def test_happy_path_write_search_delete_round_trip(monkeypatch: pytest.MonkeyPatch) -> None:
    manager = _manager(monkeypatch)
    calls: list[tuple[str, str, dict[str, Any] | None]] = []

    monkeypatch.setattr(manager, "_embed_text", lambda text: _vector(768))

    def fake_request(method: str, path: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
        calls.append((method, path, body))
        if path.endswith("/points/search"):
            return {"result": [{"id": "point-1", "score": 0.91, "payload": {"text": "hello"}}]}
        return {"status": "ok", "result": {"count": 1}}

    monkeypatch.setattr(manager, "_request_json", fake_request)

    point_id = manager.write("merlin-session", "hello", {"source": "unit"})
    assert point_id is not None

    results = manager.search("merlin-session", "hello")
    assert results == [{"id": "point-1", "score": 0.91, "payload": {"text": "hello"}}]
    assert manager.delete("merlin-session", point_id) is True
    assert any(call[0] == "PUT" and "/collections/merlin_session/points" in call[1] for call in calls)


def test_writing_768_dim_embedding_to_documents_raises_immediately(monkeypatch: pytest.MonkeyPatch) -> None:
    manager = _manager(monkeypatch)
    monkeypatch.setattr(manager, "_embed_text", lambda text: _vector(768))

    with pytest.raises(DimensionMismatchError):
        manager.write("documents", "test text", {})


def test_writing_1536_dim_vector_to_merlin_session_raises_immediately(monkeypatch: pytest.MonkeyPatch) -> None:
    manager = _manager(monkeypatch)
    monkeypatch.setattr(manager, "_embed_text", lambda text: _vector(1536))

    with pytest.raises(DimensionMismatchError):
        manager.write("merlin-session", "test text", {})


def test_qdrant_unreachable_enters_degraded_mode_and_write_returns_none(monkeypatch: pytest.MonkeyPatch) -> None:
    def fail_startup(self: MemoryManager) -> None:
        self._activate_degraded("startup", "*")

    monkeypatch.setattr(MemoryManager, "_check_qdrant", fail_startup)
    manager = MemoryManager()

    assert manager.degraded is True
    assert manager.write("merlin-session", "test", {}) is None


def test_list_collections_returns_merlin_session(monkeypatch: pytest.MonkeyPatch) -> None:
    manager = _manager(monkeypatch)
    monkeypatch.setattr(manager, "_request_json", lambda method, path, body=None: {"result": {"count": 0}})

    collections = manager.list_collections()
    assert any(collection["name"] == "merlin-session" for collection in collections)
