"""Offline memory benchmark runner."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from importlib import import_module
from pathlib import Path
from typing import Any

from tests.benchmarks.layer_aware import layer_accuracy
from tests.benchmarks.metrics import (
    contradiction_drift_rate,
    f1_at_k,
    hit_at_k,
    latency_summary,
    recall_at_k,
)
from tests.benchmarks.schema import BenchmarkCase, CaseResult

SUITES = ("epbench", "memoryarena", "amabench")
DEFAULT_TOP_K = 5
DEFAULT_MIN_RECALL_AT_5 = 0.75


def load_adapter(suite: str):
    if suite not in SUITES:
        raise ValueError(f"unknown benchmark suite: {suite}")
    return import_module(f"tests.benchmarks.{suite}.adapter")


def run_suite(suite: str, top_k: int = DEFAULT_TOP_K) -> dict[str, Any]:
    adapter = load_adapter(suite)
    cases: list[BenchmarkCase] = adapter.cases()
    results: list[CaseResult] = adapter.run(top_k=top_k)
    summary = {
        "suite": suite,
        "case_count": len(cases),
        "top_k": top_k,
        "hit_at_k": round(hit_at_k(results, top_k), 4),
        "recall_at_k": round(recall_at_k(results, top_k), 4),
        "f1_at_k": round(f1_at_k(results, top_k), 4),
        "layer_accuracy": round(layer_accuracy(cases, results), 4),
        "contradiction_drift_rate": round(contradiction_drift_rate(results), 4),
        "latency": latency_summary(results),
        "generated_at": datetime.now(UTC).isoformat(),
        "results": [
            {
                "case_id": result.case_id,
                "retrieved_ids": list(result.retrieved_ids),
                "expected_ids": list(result.expected_ids),
                "hit": result.hit,
                "latency_ms": result.latency_ms,
            }
            for result in results
        ],
    }
    return summary


def run_many(suites: list[str], top_k: int = DEFAULT_TOP_K) -> list[dict[str, Any]]:
    selected = list(SUITES) if suites == ["all"] else suites
    return [run_suite(suite, top_k=top_k) for suite in selected]


def write_jsonl(path: Path, summaries: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        for summary in summaries:
            handle.write(json.dumps(summary, sort_keys=True) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run offline Merlin memory benchmarks")
    parser.add_argument("--suite", choices=("all", *SUITES), default="epbench")
    parser.add_argument("--profile", choices=("offline",), default="offline")
    parser.add_argument("--top-k", type=int, default=DEFAULT_TOP_K)
    parser.add_argument("--min-recall-at-5", type=float, default=DEFAULT_MIN_RECALL_AT_5)
    parser.add_argument("--jsonl-out", default="")
    args = parser.parse_args()

    summaries = run_many([args.suite], top_k=args.top_k)
    if args.jsonl_out:
        write_jsonl(Path(args.jsonl_out), summaries)

    print(json.dumps({"profile": args.profile, "summaries": summaries}, indent=2, sort_keys=True))

    if args.suite in {"all", "epbench"}:
        epbench = next(summary for summary in summaries if summary["suite"] == "epbench")
        if epbench["recall_at_k"] < args.min_recall_at_5:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

