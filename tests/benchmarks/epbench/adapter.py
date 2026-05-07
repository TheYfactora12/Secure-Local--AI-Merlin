"""EpBench-style episodic recall adapter.

This offline adapter uses deterministic fixtures to validate the benchmark
harness before live Qdrant/Ollama integration exists.
"""

from __future__ import annotations

from tests.benchmarks.schema import BenchmarkCase, CaseResult, MemoryRecord


def cases() -> list[BenchmarkCase]:
    records = (
        MemoryRecord("ep-1", "User installed core profile on Monday.", "merlin_session", "2026-05-04T10:00:00Z"),
        MemoryRecord("ep-2", "User validated launchd status API on Tuesday.", "merlin_session", "2026-05-05T10:00:00Z"),
        MemoryRecord("ep-3", "User closed v1.3 router reliability on Thursday.", "merlin_audit", "2026-05-07T15:30:00Z"),
    )
    return [
        BenchmarkCase(
            case_id="epbench-order-001",
            suite="epbench",
            query="What happened after core install and before router close?",
            expected_ids=("ep-2",),
            records=records,
            expected_layer="merlin_session",
        ),
        BenchmarkCase(
            case_id="epbench-router-002",
            suite="epbench",
            query="Which event closed router reliability?",
            expected_ids=("ep-3",),
            records=records,
            expected_layer="merlin_audit",
        ),
    ]


def run(top_k: int = 5) -> list[CaseResult]:
    results: list[CaseResult] = []
    for case in cases():
        if "router" in case.query.lower():
            retrieved = ("ep-3", "ep-2", "ep-1")
        else:
            retrieved = ("ep-2", "ep-1", "ep-3")
        results.append(
            CaseResult(
                case_id=case.case_id,
                suite=case.suite,
                retrieved_ids=retrieved[:top_k],
                expected_ids=case.expected_ids,
                expected_layer=case.expected_layer,
                latency_ms=3,
            )
        )
    return results

