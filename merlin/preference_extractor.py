"""Phase 3C review-only user preference extraction.

This module intentionally does not call an LLM, write memory, touch Qdrant, or
modify config. It creates structured preference candidates for human review.
"""

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
]

WRITE_CONFIDENCE_THRESHOLD = 0.85
MAX_PREFERENCES_PER_SESSION = 3
MAX_EVIDENCE_CHARS = 80

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


def extract_preferences(session_text: str) -> list[PreferenceCandidate]:
    """Extract up to three review-only preference candidates from a session.

    The output is intentionally conservative. Candidates below the write
    confidence threshold are returned for review with write_eligible=false.
    This function never persists preferences.
    """

    text = session_text.strip()
    if not text:
        return []

    candidates: list[PreferenceCandidate] = []
    seen: set[str] = set()
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
            candidates.append(
                PreferenceCandidate(
                    preference_text=redact_sensitive_text(preference_text),
                    category=_categorize(match.group(0)),
                    confidence=confidence,
                    evidence=redact_sensitive_text(evidence),
                    write_eligible=confidence >= WRITE_CONFIDENCE_THRESHOLD,
                )
            )

    candidates.sort(key=lambda item: item.confidence, reverse=True)
    return candidates[:MAX_PREFERENCES_PER_SESSION]


def redact_sensitive_text(text: str) -> str:
    """Redact common secret shapes before preference review output."""

    redacted = text
    for pattern, replacement in _SECRET_PATTERNS:
        redacted = pattern.sub(replacement, redacted)
    return redacted


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
    lowered = evidence.casefold()
    if any(marker in lowered for marker in ("maybe", "sometimes", "might", "could")):
        return min(base_confidence, 0.7)
    if any(marker in lowered for marker in ("always", "strongly", "must", "need")):
        return min(1.0, base_confidence + 0.02)
    return base_confidence


def _categorize(evidence: str) -> PreferenceCategory:
    lowered = evidence.casefold()
    if _contains_any(lowered, ("python", "bash", "pytest", "test", "refactor", "code", "typing")):
        return "coding_style"
    if _contains_any(lowered, ("docker", "github", "qdrant", "ollama", "litellm", "n8n", "qwen", "model")):
        return "tool_preference"
    if _contains_any(lowered, ("explain", "concise", "direct", "honest", "don't lie", "tone", "ask")):
        return "communication_style"
    if _contains_any(lowered, ("commit", "push", "roadmap", "issue", "milestone", "validate", "best practice")):
        return "workflow_pattern"
    if _contains_any(lowered, ("bank", "finance", "financial", "ffiec", "compliance", "security")):
        return "domain_expertise"
    return "workflow_pattern"


def _contains_any(value: str, needles: tuple[str, ...]) -> bool:
    return any(needle in value for needle in needles)
