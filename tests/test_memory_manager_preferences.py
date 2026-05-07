"""Tests for MemoryManager Phase 3C PreferenceStore methods.

All Qdrant calls are mocked — no live Qdrant required.
"""
from __future__ import annotations

import io
import json
from contextlib import redirect_stdout
from unittest.mock import MagicMock, patch

import pytest

from merlin.preference_extractor import PreferenceCandidate


def _make_manager():
    """Build a MemoryManager with all network calls patched out."""
    from merlin.memory_manager import MemoryManager

    with patch.object(MemoryManager, "_check_qdrant", return_value=None), \
         patch.object(MemoryManager, "_build_collection_specs", return_value={}):
        mm = MemoryManager.__new__(MemoryManager)
        mm.degraded = False
        mm.timeout = 1
        mm.qdrant_url = "http://localhost:6333"
        mm.embedding_model = "nomic-embed-text"
        mm.embedding_dimensions = 384
        mm.collections = {}
    return mm


def _candidate(
    text: str = "User prefers Python over JavaScript",
    category: str = "coding_style",
    confidence: float = 0.92,
) -> PreferenceCandidate:
    return PreferenceCandidate(
        preference_text=text,
        category=category,
        confidence=confidence,
        evidence="I prefer Python",
        write_eligible=confidence >= 0.85,
    )


# ---------------------------------------------------------------------------
# test_write_approved_preference_success
# ---------------------------------------------------------------------------

def test_write_approved_preference_success() -> None:
    mm = _make_manager()
    good_response = {"result": {"operation_id": 1, "status": "completed"}}

    with patch.object(mm, "search_preferences_by_text", return_value=[]), \
         patch.object(mm, "_request_json", return_value=good_response):
        result = mm.write_approved_preference(_candidate(), approval_id="test-approval-001")

    assert result is not None
    assert len(result) > 0  # UUID string


# ---------------------------------------------------------------------------
# test_write_approved_preference_dedup_skip
# ---------------------------------------------------------------------------

def test_write_approved_preference_dedup_skip() -> None:
    mm = _make_manager()
    existing = [{"preference_text": "User prefers Python over JavaScript", "category": "coding_style"}]

    with patch.object(mm, "search_preferences_by_text", return_value=existing):
        result = mm.write_approved_preference(_candidate(), approval_id="test-approval-002")

    assert result is None


# ---------------------------------------------------------------------------
# test_write_approved_preference_qdrant_down
# ---------------------------------------------------------------------------

def test_write_approved_preference_qdrant_down() -> None:
    mm = _make_manager()

    with patch.object(mm, "search_preferences_by_text", return_value=[]), \
         patch.object(mm, "_request_json", side_effect=OSError("connection refused")):
        result = mm.write_approved_preference(_candidate(), approval_id="test-approval-003")

    assert result is None


# ---------------------------------------------------------------------------
# test_get_preferences_by_category_returns_sorted
# ---------------------------------------------------------------------------

def test_get_preferences_by_category_returns_sorted() -> None:
    mm = _make_manager()
    scroll_response = {
        "result": {
            "points": [
                {"id": "a", "payload": {"preference_text": "older", "category": "coding_style", "created_at": "2026-01-01T00:00:00+00:00"}},
                {"id": "b", "payload": {"preference_text": "newer", "category": "coding_style", "created_at": "2026-05-01T00:00:00+00:00"}},
            ]
        }
    }

    with patch.object(mm, "_request_json", return_value=scroll_response):
        result = mm.get_preferences_by_category("coding_style")

    assert len(result) == 2
    assert result[0]["preference_text"] == "newer"  # newest first
    assert result[1]["preference_text"] == "older"


# ---------------------------------------------------------------------------
# test_get_preferences_by_category_qdrant_down
# ---------------------------------------------------------------------------

def test_get_preferences_by_category_qdrant_down() -> None:
    mm = _make_manager()

    with patch.object(mm, "_request_json", side_effect=OSError("connection refused")):
        result = mm.get_preferences_by_category("coding_style")

    assert result == []


# ---------------------------------------------------------------------------
# test_search_preferences_by_text_match
# ---------------------------------------------------------------------------

def test_search_preferences_by_text_match() -> None:
    mm = _make_manager()
    scroll_response = {
        "result": {
            "points": [
                {"id": "x", "payload": {"preference_text": "User prefers Python over JavaScript", "category": "coding_style"}},
            ]
        }
    }

    with patch.object(mm, "_request_json", return_value=scroll_response):
        result = mm.search_preferences_by_text("User prefers Python over JavaScript")

    assert len(result) == 1
    assert result[0]["preference_text"] == "User prefers Python over JavaScript"


# ---------------------------------------------------------------------------
# test_search_preferences_by_text_no_match
# ---------------------------------------------------------------------------

def test_search_preferences_by_text_no_match() -> None:
    mm = _make_manager()
    scroll_response = {"result": {"points": []}}

    with patch.object(mm, "_request_json", return_value=scroll_response):
        result = mm.search_preferences_by_text("nonexistent preference")

    assert result == []
