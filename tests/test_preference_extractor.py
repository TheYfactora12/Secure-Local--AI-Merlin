from __future__ import annotations

from merlin.preference_extractor import (
    MAX_PREFERENCES_PER_SESSION,
    WRITE_CONFIDENCE_THRESHOLD,
    extract_preferences,
)


def test_extracts_explicit_coding_preference() -> None:
    candidates = extract_preferences("I prefer Python over Bash for scripts. Keep tests tight.")

    assert len(candidates) == 1
    candidate = candidates[0]
    assert candidate.preference_text == "User prefers Python over Bash for scripts"
    assert candidate.category == "coding_style"
    assert candidate.confidence >= WRITE_CONFIDENCE_THRESHOLD
    assert candidate.write_eligible is True
    assert candidate.evidence == "I prefer Python over Bash for scripts"


def test_extracts_tool_preference() -> None:
    candidates = extract_preferences("For local memory, I prefer Qdrant with Ollama embeddings.")

    assert candidates[0].category == "tool_preference"
    assert "Qdrant" in candidates[0].preference_text
    assert candidates[0].write_eligible is True


def test_extracts_communication_preference() -> None:
    candidates = extract_preferences("I want direct honest answers when something cannot be done.")

    assert candidates[0].category == "communication_style"
    assert candidates[0].write_eligible is True


def test_weak_preference_is_review_only() -> None:
    candidates = extract_preferences("Maybe use Python for a helper if it makes sense.")

    assert len(candidates) == 1
    assert candidates[0].confidence < WRITE_CONFIDENCE_THRESHOLD
    assert candidates[0].write_eligible is False


def test_no_preference_for_passing_remark() -> None:
    candidates = extract_preferences("Yesterday I used Python and Docker while testing the installer.")

    assert candidates == []


def test_limits_to_three_preferences_per_session() -> None:
    candidates = extract_preferences(
        "I prefer Python for scripts. "
        "I prefer Qdrant for vector memory. "
        "I want direct answers. "
        "I usually validate before commits. "
        "I prefer local models."
    )

    assert len(candidates) == MAX_PREFERENCES_PER_SESSION
    assert all(candidate.write_eligible for candidate in candidates)


def test_evidence_is_capped_at_80_chars() -> None:
    candidates = extract_preferences(
        "I prefer extremely detailed validation notes with every command, every result, "
        "and every risk called out before any commit."
    )

    assert len(candidates[0].evidence) <= 80


def test_secrets_are_redacted_from_output() -> None:
    candidates = extract_preferences(
        "I prefer password=supersecret123 for nothing and sk-abcdefghijklmnopqrstuvwxyz123456 "
        "should never appear."
    )
    rendered = str([candidate.model_dump() for candidate in candidates])

    assert "supersecret123" not in rendered
    assert "sk-abcdefghijklmnopqrstuvwxyz123456" not in rendered
    assert "[REDACTED]" in rendered or "[REDACTED-API-KEY]" in rendered


def test_empty_session_returns_empty_list() -> None:
    assert extract_preferences("   ") == []
