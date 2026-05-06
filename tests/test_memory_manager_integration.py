from __future__ import annotations

import os

import pytest

from merlin.memory_manager import MemoryManager


pytestmark = pytest.mark.skipif(
    os.environ.get("INTEGRATION_TESTS") != "true",
    reason="Set INTEGRATION_TESTS=true to run live Qdrant/Ollama memory tests.",
)


def test_live_list_collections() -> None:
    manager = MemoryManager()
    collections = manager.list_collections()
    assert any(collection["name"] == "merlin-session" for collection in collections)
