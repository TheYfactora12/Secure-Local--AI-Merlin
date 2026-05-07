"""Phase 3E skill scores from approved outcome history.

Scores are recomputed from `skill_outcomes` on every call. This module is
read-only: it does not write Qdrant, create files, call models, or modify
routing by itself.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

from merlin.memory_manager import MemoryManager


RECENCY_HALF_LIFE_DAYS = 30
MIN_OUTCOMES_FOR_SCORE = 3
CONFIDENCE_SCALE_FACTOR = 10

RATING_WEIGHTS: dict[str, float] = {
    "approved": 1.0,
    "corrected": 0.5,
    "rejected": 0.0,
    "none": 0.0,
}


@dataclass(frozen=True)
class SkillScore:
    agent: str
    domain: str
    score: float | None
    confidence: float
    sample_size: int
    last_seen: str | None
    trending: str
    route_bias: bool


@dataclass
class SkillReport:
    scores: list[SkillScore] = field(default_factory=list)
    total_outcomes_read: int = 0
    generated_at: str = ""

    def best_agent_for(self, domain: str) -> str | None:
        candidates = [score for score in self.scores if score.domain == domain and score.route_bias]
        if not candidates:
            return None
        return max(candidates, key=lambda score: (score.score or 0.0) * score.confidence).agent

    def as_table(self) -> str:
        header = f"{'AGENT':<20} {'DOMAIN':<12} {'SCORE':>6} {'CONF':>6} {'N':>5} {'TREND':<8} {'BIAS'}"
        rows = [header, "-" * len(header)]
        for score in self.scores:
            score_text = f"{score.score:.3f}" if score.score is not None else "n/a"
            rows.append(
                f"{score.agent:<20} {score.domain:<12} {score_text:>6} "
                f"{score.confidence:.3f} {score.sample_size:>5} {score.trending:<8} "
                f"{'yes' if score.route_bias else ''}"
            )
        return "\n".join(rows)


def compute_skill_report(
    memory: MemoryManager | None = None,
    min_outcomes: int = MIN_OUTCOMES_FOR_SCORE,
    route_bias_min_score: float = 0.65,
    route_bias_min_confidence: float = 0.40,
) -> SkillReport:
    """Read skill_outcomes from Qdrant and compute a current report."""

    report = SkillReport(generated_at=datetime.now(UTC).isoformat())
    try:
        mm = memory or MemoryManager()
        records = mm.scroll_collection("skill_outcomes", limit=1000)
    except Exception:
        return report

    report.total_outcomes_read = len(records)
    buckets: dict[tuple[str, str], list[tuple[float, float, str]]] = {}

    for record in records:
        payload = _payload(record)
        agent = str(payload.get("agent_target", "unknown"))
        domain = str(payload.get("skill_domain", "general"))
        rating = str(payload.get("outcome_rating", "none"))
        timestamp = str(payload.get("created_at", ""))
        if rating not in RATING_WEIGHTS:
            continue
        recency = _recency_weight(timestamp)
        rating_weight = RATING_WEIGHTS[rating]
        buckets.setdefault((agent, domain), []).append((rating_weight, recency, timestamp))

    for (agent, domain), outcomes in buckets.items():
        sample_size = len(outcomes)
        sorted_outcomes = sorted(outcomes, key=lambda item: item[2])
        last_seen = sorted_outcomes[-1][2] if sorted_outcomes else None
        if sample_size < min_outcomes:
            report.scores.append(
                SkillScore(
                    agent=agent,
                    domain=domain,
                    score=None,
                    confidence=0.0,
                    sample_size=sample_size,
                    last_seen=last_seen,
                    trending="unknown",
                    route_bias=False,
                )
            )
            continue

        numerator = sum(rating_weight * recency for rating_weight, recency, _ in outcomes)
        denominator = sum(recency for _, recency, _ in outcomes)
        score = round(numerator / denominator, 4) if denominator > 0 else 0.0
        confidence = round(1.0 - 1.0 / (1.0 + sample_size / CONFIDENCE_SCALE_FACTOR), 4)
        trending = _trend([(rating_weight, timestamp) for rating_weight, _, timestamp in sorted_outcomes])
        route_bias = score >= route_bias_min_score and confidence >= route_bias_min_confidence
        report.scores.append(
            SkillScore(
                agent=agent,
                domain=domain,
                score=score,
                confidence=confidence,
                sample_size=sample_size,
                last_seen=last_seen,
                trending=trending,
                route_bias=route_bias,
            )
        )

    report.scores.sort(key=lambda score: (score.confidence, score.score or 0.0), reverse=True)
    return report


def _payload(record: Any) -> dict[str, Any]:
    if hasattr(record, "payload"):
        payload = record.payload
    elif isinstance(record, dict):
        payload = record.get("payload", {})
    else:
        payload = {}
    return payload if isinstance(payload, dict) else {}


def _recency_weight(timestamp: str) -> float:
    try:
        parsed = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=UTC)
        age_days = max(0.0, (datetime.now(UTC) - parsed.astimezone(UTC)).total_seconds() / 86400)
        return math.exp(-math.log(2) * age_days / RECENCY_HALF_LIFE_DAYS)
    except Exception:
        return 1.0


def _trend(sorted_outcomes: list[tuple[float, str]]) -> str:
    sample_size = len(sorted_outcomes)
    if sample_size < 6:
        return "unknown"
    midpoint = sample_size // 2
    early = sum(score for score, _ in sorted_outcomes[:midpoint]) / midpoint
    late = sum(score for score, _ in sorted_outcomes[midpoint:]) / (sample_size - midpoint)
    delta = late - early
    if delta > 0.05:
        return "up"
    if delta < -0.05:
        return "down"
    return "stable"
