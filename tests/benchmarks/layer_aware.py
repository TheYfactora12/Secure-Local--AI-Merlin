"""Layer-aware memory benchmark scoring."""

from __future__ import annotations

from tests.benchmarks.schema import BenchmarkCase, CaseResult


def expected_layer_for_case(case: BenchmarkCase) -> str:
    return case.expected_layer


def layer_accuracy(cases: list[BenchmarkCase], results: list[CaseResult]) -> float:
    if not cases:
        return 0.0
    expected_by_id = {case.case_id: case.expected_layer for case in cases}
    correct = 0
    for result in results:
        if expected_by_id.get(result.case_id) == result.expected_layer:
            correct += 1
    return correct / len(cases)

