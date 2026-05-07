"""Phase 3C review-only user preference extraction.

This module intentionally does not call an LLM, write memory, touch Qdrant, or
modify config. It creates structured preference candidates for human review.
"""
# PATENT NOTICE — Element 3 (Negation-Aware Confidence Suppression Function)
# Conception date: 2026-05-07 — Kevin Paul Medeiros Jr
# Record: docs/ip/INVENTOR_RECORD.md
# Issue: #82
# The function negation_suppressed_confidence() below is a named, independently
# testable implementation of Patent Provisional A, Claim 3.

from __future__ import annotations

import re
from collections.abc import Callable
from typing import Literal

from pydantic import BaseModel, Field, field_validator


PreferenceCategory = Literal[
    "coding_style",
    "tool_preference",
    "communication_style",
    "workflow_pattern",
    "domain_expertise",
    "architecture_decision",   # NEW — design rules and structural decisions
]

WRITE_CONFIDENCE_THRESHOLD = 0.85
MAX_PREFERENCES_PER_SESSION = 3
MAX_REVIEW_CANDIDATES = 8   # max candidates returned for human review
                             # MAX_PREFERENCES_PER_SESSION (3) is the auto-write cap only
MAX_EVIDENCE_CHARS = 80

# ---------------------------------------------------------------------------
# Negation suppression constants (Patent Provisional A, Claim 3)
# ---------------------------------------------------------------------------
# These values were deliberately chosen by the inventor and are claim-relevant.
# Do NOT change without updating docs/ip/INVENTOR_RECORD.md and issue #82.
NEGATION_SUPPRESSION_WEIGHT: float = 0.15   # multiplied against raw confidence on negation hit
NEGATION_TOKEN_WINDOW: int = 5              # tokens preceding candidate scanned for markers

_NEGATION_MARKERS: frozenset[str] = frozenset({
    "don't", "dont", "never", "avoid", "stop", "no",
    "neither", "nor", "without", "refuse", "won't", "wont",
    "cannot", "can't", "cant",
})

_SECRET_PATTERNS: tuple[tuple[re.Pattern[str], str | Callable[[re.Match[str]], str]], ...] = (
    (re.compile(r"AKIA[0-9A-Z]{16}"), "[REDACTED-AWS-KEY]"),
    (re.compile(r"eyJ[A-Za-z0-9_/+=-]{20,}"), "[REDACTED-JWT]"),
    (re.compile(r"sk-ant-[A-Za-z0-9_-]{20,}"), "[REDACTED-API-KEY]"),
    (re.compile(r"sk-[A-Za-z0-9]{20,}"), "[REDACTED-API-KEY]"),
    (
        re.compile(
            r"\b(password|secret|token|api_key|apikey|credential|private)\s*=\s*\S+",
            re.IGNORECASE,
        ),
        lambda match: f"{match.group(1)}=[REDACTED]",
    ),
)

_PREFERENCE_PATTERNS: tuple[tuple[re.Pattern[str], float], ...] = (
    # Explicit declaration patterns
    (re.compile(r"\bI\s+(?:strongly\s+)?prefer\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.92),
    (re.compile(r"\bI\s+always\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.9),
    (re.compile(r"\bI\s+usually\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.88),
    (re.compile(r"\bI\s+want\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.87),
    (re.compile(r"\bI\s+need\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.87),
    (re.compile(r"\bmake sure\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.86),
    (re.compile(r"\buse\s+([^.!?\n]{3,120})\s+instead of\s+([^.!?\n]{3,120})", re.IGNORECASE), 0.9),
    (re.compile(r"\bI(?:'d| would)\s+rather\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.88),
    (re.compile(r"\bI\s+(?:do not|don't)\s+want\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.87),
    (re.compile(r"\bmaybe\s+(?:use|prefer|keep)\s+([^.!?\n]{3,160})", re.IGNORECASE), 0.55),
    # Implicit instruction patterns — the 80% of real preferences that are commands
    (re.compile(r"\bdon't\s+(?:use|add|include|put|make)\s+([^.!?\n]{3,120})", re.IGNORECASE), 0.86),
    (re.compile(r"\bnever\s+(?:use|add|include|do|make|put)\s+([^.!?\n]{3,120})", re.IGNORECASE), 0.90),
    (re.compile(r"\balways\s+(?:add|include|use|write|run|make|put)\s+([^.!?\n]{3,120})", re.IGNORECASE), 0.88),
    (re.compile(r"\bkeep\s+(?:it|them|this|that)\s+([^.!?\n]{3,100})", re.IGNORECASE), 0.78),
    (re.compile(r"\bsplit\s+(?:it|this|that)\s+into\s+([^.!?\n]{3,100})", re.IGNORECASE), 0.82),
    (re.compile(r"\b(?:not|no)\s+([^.!?\n]{3,80}),?\s+(?:just|only|instead)\s+([^.!?\n]{3,80})", re.IGNORECASE), 0.83),
    (re.compile(r"\bone\s+commit\s+(?:per|for|not)\s+([^.!?\n]{3,100})", re.IGNORECASE), 0.85),
    (re.compile(r"\b(\d+)\s+commits?\s+(?:not|instead of|rather than)\s+\d+", re.IGNORECASE), 0.88),
)


class PreferenceCandidate(BaseModel):
    """A preference candidate for review before any memory write."""

    preference_text: str = Field(min_length=1)
    category: PreferenceCategory
    confidence: float = Field(ge=0.0, le=1.0)
    evidence: str = Field(min_length=1, max_length=MAX_EVIDENCE_CHARS)
    write_eligible: bool = False

    @field_validator("preference_text", "evidence")
    @classmethod
    def _must_be_redacted(cls, value: str) -> str:
        redacted = redact_sensitive_text(value)
        if redacted != value:
            return redacted
        return value


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def negation_suppressed_confidence(
    raw_confidence: float,
    evidence: str,
    suppression_weight: float = NEGATION_SUPPRESSION_WEIGHT,
    token_window: int = NEGATION_TOKEN_WINDOW,
) -> float:
    """Return confidence degraded by suppression_weight if a negation marker
    precedes the candidate preference term within token_window tokens.

    This is Patent Provisional A, Claim 3 (Element 3 in INVENTOR_RECORD.md).
    Conception date: 2026-05-07 — Kevin Paul Medeiros Jr.

    Design contract (do not change without updating the inventor record):
    - Scans the ``token_window`` tokens immediately preceding the matched
      candidate for membership in ``_NEGATION_MARKERS``.
    - On a hit: returns ``raw_confidence * suppression_weight``.
      Confidence is DEGRADED, not inverted. The candidate is preserved in
      the staging queue for human review. This is the architectural
      distinction from NLP negation-as-semantic-inversion approaches.
    - No hit: returns ``raw_confidence`` unchanged.
    - ``suppression_weight`` and ``token_window`` are configurable but
      default to the claim-relevant values (0.15 and 5).

    Args:
        raw_confidence: The base confidence score from the pattern match.
        evidence: The matched text from the session (the full match group(0)).
        suppression_weight: Multiplier applied on negation detection.
            Default NEGATION_SUPPRESSION_WEIGHT = 0.15.
        token_window: Number of tokens preceding the first content word
            to scan for negation markers.
            Default NEGATION_TOKEN_WINDOW = 5.

    Returns:
        float: Adjusted confidence in [0.0, 1.0].
    """
    tokens = evidence.lower().split()
    # Identify the first non-stopword content token as the "candidate anchor".
    # We scan the token_window tokens that precede it.
    _STOPWORDS = frozenset({"i", "to", "the", "a", "an", "my", "me", "you", "we", "it", "that"})
    anchor_index: int | None = None
    for idx, token in enumerate(tokens):
        cleaned = re.sub(r"[^a-z']", "", token)
        if cleaned and cleaned not in _STOPWORDS:
            anchor_index = idx
            break

    if anchor_index is None:
        return raw_confidence

    window_start = max(0, anchor_index - token_window)
    preceding_tokens = [
        re.sub(r"[^a-z']", "", t) for t in tokens[window_start:anchor_index]
    ]

    if any(t in _NEGATION_MARKERS for t in preceding_tokens):
        return round(raw_confidence * suppression_weight, 4)

    return raw_confidence


def extract_preferences(session_text: str) -> list[PreferenceCandidate]:
    """Extract preference candidates from a session for human review.

    Returns up to MAX_REVIEW_CANDIDATES (8) for human review.
    Of those, at most MAX_PREFERENCES_PER_SESSION (3) will have write_eligible=True.
    Callers must enforce the auto-write cap on write_eligible items.
    This function never persists preferences.
    """

    text = session_text.strip()
    if not text:
        return []

    candidates: list[PreferenceCandidate] = []
    seen: set[str] = set()
    write_eligible_count = 0

    for pattern, base_confidence in _PREFERENCE_PATTERNS:
        for match in pattern.finditer(text):
            evidence = _truncate_evidence(match.group(0))
            preference_body = _preference_body(match)
            if not preference_body:
                continue

            preference_text = _to_third_person_preference(preference_body, match.group(0))
            key = preference_text.casefold()
            if key in seen:
                continue
            seen.add(key)

            confidence = _calibrated_confidence(base_confidence, match.group(0))
            is_write_eligible = (
                confidence >= WRITE_CONFIDENCE_THRESHOLD
                and write_eligible_count < MAX_PREFERENCES_PER_SESSION
            )
            if is_write_eligible:
                write_eligible_count += 1

            candidates.append(
                PreferenceCandidate(
                    preference_text=redact_sensitive_text(preference_text),
                    category=_categorize(match.group(0)),
                    confidence=confidence,
                    evidence=redact_sensitive_text(evidence),
                    write_eligible=is_write_eligible,
                )
            )

    candidates.sort(key=lambda item: item.confidence, reverse=True)
    # Return up to MAX_REVIEW_CANDIDATES for human review.
    # write_eligible=True candidates are capped at MAX_PREFERENCES_PER_SESSION.
    # Callers must enforce the auto-write cap on write_eligible items.
    return candidates[:MAX_REVIEW_CANDIDATES]


def redact_sensitive_text(text: str) -> str:
    """Redact common secret shapes before preference review output."""

    redacted = text
    for pattern, replacement in _SECRET_PATTERNS:
        redacted = pattern.sub(replacement, redacted)
    return redacted


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _preference_body(match: re.Match[str]) -> str:
    if len(match.groups()) >= 2 and "instead of" in match.group(0).casefold():
        return f"use {match.group(1).strip()} instead of {match.group(2).strip()}"
    return match.group(1).strip()


def _to_third_person_preference(preference_body: str, evidence: str) -> str:
    body = _normalize_body(preference_body)
    lowered_evidence = evidence.casefold()
    if "do not want" in lowered_evidence or "don't want" in lowered_evidence:
        return f"User does not want {body}"
    if "make sure" in lowered_evidence:
        return f"User wants Merlin to {body}"
    if "never" in lowered_evidence:
        return f"User never wants {body}"
    if body.startswith(("to ", "that ")):
        return f"User prefers {body}"
    return f"User prefers {body}"


def _normalize_body(value: str) -> str:
    body = " ".join(value.strip().split())
    body = re.sub(r"^(that|to)\s+", lambda match: f"{match.group(1)} ", body, flags=re.IGNORECASE)
    return body[:180].rstrip(" ,;:")


def _truncate_evidence(value: str) -> str:
    evidence = " ".join(value.strip().split())
    if len(evidence) <= MAX_EVIDENCE_CHARS:
        return evidence
    return evidence[: MAX_EVIDENCE_CHARS - 3].rstrip() + "..."


def _calibrated_confidence(base_confidence: float, evidence: str) -> float:
    """Calibrate raw pattern confidence for a matched evidence string.

    Call order (do not reorder):
    1. negation_suppressed_confidence() — Patent Provisional A, Claim 3.
       Must run FIRST. If a negation marker precedes the candidate within the
       token window, confidence is degraded to base * 0.15. No further
       boosting is applied to a suppressed candidate.
    2. Hedging words — cap at 0.70.
    3. Certainty amplifiers — boost by +0.02, cap at 1.0.
    """
    # Step 1: negation suppression (Claim 3) — first guard, no boosting after.
    suppressed = negation_suppressed_confidence(base_confidence, evidence)
    if suppressed != base_confidence:
        # Negation was detected — return immediately, no further adjustment.
        return suppressed

    lowered = evidence.casefold()

    # Step 2: legacy phrase-level negation (hedging / uncertainty markers).
    _NEGATION_PHRASES = (
        "don't strongly", "not necessarily", "don't really", "not really",
        "not sure", "not always", "doesn't matter", "either way",
        "not important", "don't mind",
    )
    if any(phrase in lowered for phrase in _NEGATION_PHRASES):
        return min(base_confidence, 0.55)  # below WRITE_CONFIDENCE_THRESHOLD

    # Step 3: hedging words.
    if any(m in lowered for m in ("maybe", "sometimes", "might", "could", "perhaps")):
        return min(base_confidence, 0.70)

    # Step 4: certainty amplifiers.
    if any(m in lowered for m in ("always", "strongly", "must", "need", "never", "every")):
        return min(1.0, base_confidence + 0.02)

    return base_confidence


def _categorize(evidence: str) -> PreferenceCategory:
    lowered = evidence.casefold()

    if _contains_any(lowered, (
        "python", "bash", "pytest", "test", "refactor", "code", "typing",
        "commit", "commits", "split", "pr", "pull request", "branch",
    )):
        return "coding_style"

    if _contains_any(lowered, (
        "docker", "github", "qdrant", "ollama", "litellm", "n8n", "qwen",
        "model", "wizard", "cli", "install", "installer", "pkg", "launchd",
        "compose", "upgrade", "backup", "restore",
    )):
        return "tool_preference"

    if _contains_any(lowered, (
        "explain", "concise", "direct", "honest", "don't lie", "tone",
        "ask", "format", "bullet", "table", "section", "header",
    )):
        return "communication_style"

    if _contains_any(lowered, (
        "architecture", "design", "tradeoff", "pattern", "structure",
        "phase", "layer", "module", "service", "component", "interface",
        "always", "never", "every", "each",
    )):
        return "architecture_decision"   # catches design rules

    if _contains_any(lowered, (
        "bank", "finance", "financial", "ffiec", "ncua", "glba", "cis",
        "nist", "iso", "compliance", "security", "audit", "risk",
        "vulnerability", "threat", "regulated",
    )):
        return "domain_expertise"

    if _contains_any(lowered, (
        "roadmap", "issue", "milestone", "validate", "best practice",
        "workflow", "process", "step", "checklist",
    )):
        return "workflow_pattern"

    return "workflow_pattern"


def _contains_any(value: str, needles: tuple[str, ...]) -> bool:
    for needle in needles:
        if " " in needle or "'" in needle or "-" in needle:
            if needle in value:
                return True
            continue
        if re.search(rf"\b{re.escape(needle)}\b", value):
            return True
    return False
