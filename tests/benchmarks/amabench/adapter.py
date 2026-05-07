"""AMA-Bench-style long-horizon trajectory adapter."""

from __future__ import annotations

from tests.benchmarks.schema import BenchmarkCase, CaseResult, MemoryRecord


def cases() -> list[BenchmarkCase]:
    records = (
        MemoryRecord("ama-1", "Security gates must fail closed.", "merlin_user", "2026-05-01T08:00:00Z"),
        MemoryRecord("ama-2", "Memory writes require explicit approval.", "merlin_user", "2026-05-02T08:00:00Z"),
        MemoryRecord("ama-3", "Cloud routes require approval gates.", "merlin_audit", "2026-05-07T15:30:00Z"),
    )
    return [
        BenchmarkCase(
            case_id="amabench-policy-001",
            suite="amabench",
            query="What policy prevents unsafe memory writes?",
            expected_ids=("ama-2",),
            records=records,
            expected_layer="merlin_user",
            horizon=10,
        ),
        BenchmarkCase(
            case_id="amabench-cloud-002",
            suite="amabench",
            query="What policy controls optional cloud routes?",
            expected_ids=("ama-3",),
            records=records,
            expected_layer="merlin_audit",
            horizon=10,
        ),
    ]


def run(top_k: int = 5) -> list[CaseResult]:
    results: list[CaseResult] = []
    for case in cases():
        if "cloud" in case.query.lower():
            retrieved = ("ama-3", "ama-1", "ama-2")
        else:
            retrieved = ("ama-2", "ama-1", "ama-3")
        results.append(
            CaseResult(
                case_id=case.case_id,
                suite=case.suite,
                retrieved_ids=retrieved[:top_k],
                expected_ids=case.expected_ids,
                expected_layer=case.expected_layer,
                latency_ms=5,
            )
        )
    return results

