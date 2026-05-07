"""Tests for router.py Phase 3C preference injection helpers.

Tests are isolated: no live Qdrant, no config loading.
"""
from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from merlin.router import (
    _inject_preferences,
    _preference_context_for_domain,
)


# ---------------------------------------------------------------------------
# test_preferences_injected_into_system_prompt
# ---------------------------------------------------------------------------

def test_preferences_injected_into_system_prompt() -> None:
    prefs = ["User prefers 3 commits not 1", "User always wants tests included"]
    result = _inject_preferences("You are Merlin.", prefs)
    assert "ACTIVE USER PREFERENCES" in result
    assert "User prefers 3 commits not 1" in result
    assert "You are Merlin." in result
    # Preference block appears before original prompt
    assert result.index("ACTIVE USER PREFERENCES") < result.index("You are Merlin.")


# ---------------------------------------------------------------------------
# test_no_preferences_system_prompt_unchanged
# ---------------------------------------------------------------------------

def test_no_preferences_system_prompt_unchanged() -> None:
    original = "You are Merlin."
    result = _inject_preferences(original, [])
    assert result == original


# ---------------------------------------------------------------------------
# test_preference_injection_qdrant_down
# ---------------------------------------------------------------------------

def test_preference_injection_qdrant_down() -> None:
    """When MemoryManager raises on init, _preference_context_for_domain returns []."""
    with patch("merlin.router.MemoryManager", side_effect=Exception("Qdrant down")):
        result = _preference_context_for_domain("coding_style")
    assert result == []


# ---------------------------------------------------------------------------
# test_max_5_preferences_injected
# ---------------------------------------------------------------------------

def test_max_5_preferences_injected() -> None:
    prefs = [f"Pref {i}" for i in range(10)]
    result = _inject_preferences("Base prompt.", prefs)
    # Count bullet lines
    bullet_lines = [line for line in result.splitlines() if line.startswith("- ")]
    assert len(bullet_lines) == 5


# ---------------------------------------------------------------------------
# test_inject_preferences_format
# ---------------------------------------------------------------------------

def test_inject_preferences_format() -> None:
    prefs = ["User prefers Python", "User never wants verbose logs"]
    result = _inject_preferences("Original.", prefs)
    lines = result.splitlines()
    assert lines[0] == "ACTIVE USER PREFERENCES (apply to this task):"
    assert lines[1] == "- User prefers Python"
    assert lines[2] == "- User never wants verbose logs"
    # Blank line separator before original prompt
    assert "" in lines
    assert "Original." in result
