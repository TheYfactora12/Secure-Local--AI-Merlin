"""Shared metrics for offline memory benchmark adapters."""

from __future__ import annotations

from statistics import median

from tests.benchmarks.schema import CaseResult


def hit_at_k(results: list[CaseResult], k: int = 5) -> float:
    if not results:
        return 0.0
    hits = 0
    for result in results:
        retrieved = result.retrieved_ids[:k]
        if any(record_id in retrieved for record_id in result.expected_ids):
            hits += 1
    return hits / len(results)


def recall_at_k(results: list[CaseResult], k: int = 5) -> float:
    if not results:
        return 0.0
    total = 0.0
    for result in results:
        expected = set(result.expected_ids)
        retrieved = set(result.retrieved_ids[:k])
        total += len(expected & retrieved) / len(expected) if expected else 0.0
    return total / len(results)


def f1_at_k(results: list[CaseResult], k: int = 5) -> float:
    if not results:
        return 0.0
    scores: list[float] = []
    for result in results:
        expected = set(result.expected_ids)
        retrieved = set(result.retrieved_ids[:k])
        if not expected or not retrieved:
            scores.append(0.0)
            continue
        precision = len(expected & retrieved) / len(retrieved)
        recall = len(expected & retrieved) / len(expected)
        if precision + recall == 0:
            scores.append(0.0)
        else:
            scores.append(2 * precision * recall / (precision + recall))
    return sum(scores) / len(scores)


def kendall_tau(expected_order: list[str], actual_order: list[str]) -> float:
    shared = [item for item in expected_order if item in actual_order]
    if len(shared) < 2:
        return 1.0 if shared else 0.0
    actual_rank = {item: idx for idx, item in enumerate(actual_order)}
    concordant = 0
    discordant = 0
    for left_index, left in enumerate(shared):
        for right in shared[left_index + 1:]:
            expected_cmp = left_index < shared.index(right)
            actual_cmp = actual_rank[left] < actual_rank[right]
            if expected_cmp == actual_cmp:
                concordant += 1
            else:
                discordant += 1
    total = concordant + discordant
    return (concordant - discordant) / total if total else 0.0


def latency_summary(results: list[CaseResult]) -> dict[str, int]:
    if not results:
        return {"p50_ms": 0, "p95_ms": 0}
    latencies = sorted(result.latency_ms for result in results)
    p95_index = min(len(latencies) - 1, int(round((len(latencies) - 1) * 0.95)))
    return {"p50_ms": int(median(latencies)), "p95_ms": int(latencies[p95_index])}


def contradiction_drift_rate(results: list[CaseResult]) -> float:
    if not results:
        return 0.0
    drifted = sum(1 for result in results if not result.hit)
    return drifted / len(results)
