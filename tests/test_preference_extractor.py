"""Tests for preference_extractor.py — Phase 3C upgrade.

All original tests preserved. 9 new tests added for Gaps 1-4.
"""
from __future__ import annotations

import pytest

from merlin.preference_extractor import (
    MAX_PREFERENCES_PER_SESSION,
    MAX_REVIEW_CANDIDATES,
    WRITE_CONFIDENCE_THRESHOLD,
    PreferenceCandidate,
    extract_preferences,
    redact_sensitive_text,
)


# ---------------------------------------------------------------------------
# Original tests — must continue passing
# ---------------------------------------------------------------------------

def test_empty_session_returns_empty() -> None:
    assert extract_preferences("") == []
    assert extract_preferences("   ") == []


def test_explicit_prefer_extracts_candidate() -> None:
    result = extract_preferences("I prefer Python over JavaScript")
    assert len(result) >= 1
    assert any("python" in c.preference_text.lower() for c in result)


def test_write_eligible_requires_threshold() -> None:
    result = extract_preferences("maybe use dark mode")
    for c in result:
        if "dark mode" in c.preference_text.lower():
            assert not c.write_eligible


def test_redact_aws_key() -> None:
    text = "AKIAIOSFODNN7EXAMPLE please use this"
    redacted = redact_sensitive_text(text)
    assert "AKIAIOSFODNN7EXAMPLE" not in redacted
    assert "[REDACTED-AWS-KEY]" in redacted


def test_redact_jwt() -> None:
    text = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig"
    redacted = redact_sensitive_text(text)
    assert "eyJ" not in redacted


def test_candidates_sorted_by_confidence_descending() -> None:
    text = "I prefer Python. I usually use pytest. maybe use black."
    result = extract_preferences(text)
    confidences = [c.confidence for c in result]
    assert confidences == sorted(confidences, reverse=True)


def test_duplicate_preference_text_deduplicated() -> None:
    text = "I prefer Python. I prefer Python."
    result = extract_preferences(text)
    texts = [c.preference_text.casefold() for c in result]
    assert len(texts) == len(set(texts))


def test_evidence_truncated_to_max_chars() -> None:
    long_pref = "I prefer " + "x" * 200
    result = extract_preferences(long_pref)
    for c in result:
        assert len(c.evidence) <= 80


# ---------------------------------------------------------------------------
# NEW tests — Gaps 1-4
# ---------------------------------------------------------------------------

def test_implicit_never_pattern() -> None:
    """GAP 1: 'never add' implicit pattern extracts a preference."""
    result = extract_preferences("never add colored borders to cards")
    assert len(result) >= 1
    texts = " ".join(c.preference_text.lower() for c in result)
    assert "border" in texts or "colored" in texts


def test_implicit_always_pattern() -> None:
    """GAP 1: 'always write' implicit pattern; category should be coding_style."""
    result = extract_preferences("always write tests with the code")
    assert len(result) >= 1
    match = next((c for c in result if "test" in c.preference_text.lower()), None)
    assert match is not None
    assert match.category == "coding_style"


def test_implicit_commit_split() -> None:
    """GAP 1: commit count pattern extracts a preference."""
    result = extract_preferences("make it 3 commits not 1")
    assert len(result) >= 1
    texts = " ".join(c.preference_text.lower() for c in result)
    assert "commit" in texts or "3" in texts


def test_architecture_decision_category() -> None:
    """GAP 2: evidence with 'architecture' maps to architecture_decision."""
    result = extract_preferences("I prefer a layered architecture with clear module boundaries")
    assert len(result) >= 1
    cats = [c.category for c in result]
    assert "architecture_decision" in cats


def test_negation_drops_confidence() -> None:
    """GAP 4: 'don't strongly prefer Docker' should produce confidence < 0.85."""
    result = extract_preferences("I don't strongly prefer Docker over Podman")
    # The phrase fires the explicit 'I prefer' or 'don't want' pattern
    # After negation calibration, confidence must be below WRITE_CONFIDENCE_THRESHOLD
    for c in result:
        if "docker" in c.preference_text.lower() or "docker" in c.evidence.lower():
            assert c.confidence < WRITE_CONFIDENCE_THRESHOLD, (
                f"Expected confidence < {WRITE_CONFIDENCE_THRESHOLD}, got {c.confidence}"
            )


def test_two_tier_cap_returns_up_to_8() -> None:
    """GAP 3: 10 distinct preference signals → up to MAX_REVIEW_CANDIDATES (8) returned."""
    signals = [
        "I prefer Python",
        "I always use pytest",
        "I usually add type hints",
        "I want concise output",
        "I need fast responses",
        "make sure tests pass",
        "I'd rather use bash than zsh",
        "I do not want verbose logs",
        "never add debug prints to production code",
        "always write tests with the code",
    ]
    session = ". ".join(signals)
    result = extract_preferences(session)
    assert len(result) <= MAX_REVIEW_CANDIDATES
    assert len(result) >= 1  # at least some candidates extracted


def test_write_eligible_still_capped_at_3() -> None:
    """GAP 3: Of all returned candidates, at most MAX_PREFERENCES_PER_SESSION (3) are write_eligible."""
    signals = [
        "I prefer Python",
        "I always use pytest",
        "I usually add type hints",
        "I want concise output",
        "I need fast responses",
        "make sure tests pass",
        "I'd rather use bash than zsh",
        "I do not want verbose logs",
        "never add debug prints to production code",
        "always write tests with the code",
    ]
    session = ". ".join(signals)
    result = extract_preferences(session)
    write_eligible_count = sum(1 for c in result if c.write_eligible)
    assert write_eligible_count <= MAX_PREFERENCES_PER_SESSION


def test_domain_expertise_includes_nist() -> None:
    """GAP 2: 'nist' in evidence maps to domain_expertise."""
    result = extract_preferences("I prefer nist controls for all security decisions")
    assert len(result) >= 1
    cats = [c.category for c in result]
    assert "domain_expertise" in cats


def test_tool_preference_includes_wizard() -> None:
    """GAP 2: 'wizard install' in evidence maps to tool_preference."""
    result = extract_preferences("I prefer using wizard install for all deployments")
    assert len(result) >= 1
    cats = [c.category for c in result]
    assert "tool_preference" in cats
