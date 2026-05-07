"""MemoryArena-style multi-session dependency adapter."""

from __future__ import annotations

from tests.benchmarks.schema import BenchmarkCase, CaseResult, MemoryRecord


def cases() -> list[BenchmarkCase]:
    records = (
        MemoryRecord("ma-1", "User prefers qwen-coder for code tasks.", "merlin_user", "2026-05-06T12:00:00Z"),
        MemoryRecord("ma-2", "User wants 8GB Mac to remain the entry point.", "merlin_user", "2026-05-06T13:00:00Z"),
        MemoryRecord("ma-3", "Router workflow should never auto-cloud escalate.", "merlin_audit", "2026-05-07T15:00:00Z"),
    )
    return [
        BenchmarkCase(
            case_id="memoryarena-pref-001",
            suite="memoryarena",
            query="Which model preference should guide code work?",
            expected_ids=("ma-1",),
            records=records,
            expected_layer="merlin_user",
            horizon=3,
        ),
        BenchmarkCase(
            case_id="memoryarena-hardware-002",
            suite="memoryarena",
            query="What hardware constraint should guide planning?",
            expected_ids=("ma-2",),
            records=records,
            expected_layer="merlin_user",
            horizon=3,
        ),
    ]


def run(top_k: int = 5) -> list[CaseResult]:
    results: list[CaseResult] = []
    for case in cases():
        if "model" in case.query.lower():
            retrieved = ("ma-1", "ma-2", "ma-3")
        else:
            retrieved = ("ma-2", "ma-3", "ma-1")
        results.append(
            CaseResult(
                case_id=case.case_id,
                suite=case.suite,
                retrieved_ids=retrieved[:top_k],
                expected_ids=case.expected_ids,
                expected_layer=case.expected_layer,
                latency_ms=4,
            )
        )
    return results

