#!/usr/bin/env bash
# Local JSONL quality score summary for Merlin observability.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
LOG_DIR="${MERLIN_LOG_DIR:-${STACK_DIR}/logs}"
DAYS=7
OUTCOME_LOG=""
TRACE_LOG=""
BENCHMARK_LOG=""

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-score.sh [--days 7] [--log-dir <path>]

Options:
  --days <n>             Trend window in days, default 7
  --log-dir <path>       Logs directory, default $STACK_DIR/logs
  --outcome-log <path>   Override outcome JSONL path
  --trace-log <path>     Override route trace JSONL path
  --benchmark-log <path> Override benchmark JSONL path

Reads local redacted JSONL only. No Langfuse, Docker, Qdrant, Ollama, LiteLLM,
n8n, cloud, or network access is required.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      DAYS="${2:-}"
      [[ "$DAYS" =~ ^[0-9]+$ && "$DAYS" -gt 0 ]] || fail "--days requires a positive integer"
      shift 2
      ;;
    --log-dir)
      LOG_DIR="${2:-}"
      [[ -n "$LOG_DIR" ]] || fail "--log-dir requires a path"
      shift 2
      ;;
    --outcome-log)
      OUTCOME_LOG="${2:-}"
      [[ -n "$OUTCOME_LOG" ]] || fail "--outcome-log requires a path"
      shift 2
      ;;
    --trace-log)
      TRACE_LOG="${2:-}"
      [[ -n "$TRACE_LOG" ]] || fail "--trace-log requires a path"
      shift 2
      ;;
    --benchmark-log)
      BENCHMARK_LOG="${2:-}"
      [[ -n "$BENCHMARK_LOG" ]] || fail "--benchmark-log requires a path"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

OUTCOME_LOG="${OUTCOME_LOG:-${LOG_DIR}/merlin-outcomes.jsonl}"
TRACE_LOG="${TRACE_LOG:-${LOG_DIR}/merlin-route-decisions.jsonl}"
BENCHMARK_LOG="${BENCHMARK_LOG:-${LOG_DIR}/merlin-benchmarks.jsonl}"

python3 - "$DAYS" "$OUTCOME_LOG" "$TRACE_LOG" "$BENCHMARK_LOG" <<'PY'
from __future__ import annotations

import json
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path
from statistics import mean

days = int(sys.argv[1])
outcome_path = Path(sys.argv[2])
trace_path = Path(sys.argv[3])
benchmark_path = Path(sys.argv[4])
cutoff = datetime.now(UTC) - timedelta(days=days)


def parse_ts(value: str) -> datetime | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=UTC)
        return parsed.astimezone(UTC)
    except ValueError:
        return None


def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    records = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return records


def in_window(record: dict) -> bool:
    ts = parse_ts(str(record.get("created_at") or record.get("timestamp") or record.get("generated_at") or ""))
    return ts is None or ts >= cutoff


outcomes = [r for r in read_jsonl(outcome_path) if in_window(r)]
traces = [r for r in read_jsonl(trace_path) if in_window(r)]
benchmarks = [r for r in read_jsonl(benchmark_path) if in_window(r)]

success_statuses = {"success"}
failure_statuses = {"failure", "timeout", "rejected", "degraded"}

success_count = sum(1 for r in outcomes if r.get("outcome_status") in success_statuses)
failure_count = sum(1 for r in outcomes if r.get("outcome_status") in failure_statuses)
total_outcomes = success_count + failure_count
success_rate = (success_count / total_outcomes) if total_outcomes else None

latencies = [int(r.get("latency_ms", 0)) for r in outcomes if isinstance(r.get("latency_ms", 0), int)]
avg_latency = int(mean(latencies)) if latencies else 0
low_confidence_successes = [
    r for r in outcomes
    if r.get("outcome_status") == "success" and float(r.get("confidence_at_routing", 1.0)) < 0.6
]

approval_required = sum(1 for r in traces if r.get("approval_required") is True)
approval_not_required = sum(1 for r in traces if r.get("approval_required") is False)

benchmark_recalls: list[float] = []
for record in benchmarks:
    summaries = record.get("summaries")
    if isinstance(summaries, list):
        for summary in summaries:
            if isinstance(summary, dict) and isinstance(summary.get("recall_at_k"), (int, float)):
                benchmark_recalls.append(float(summary["recall_at_k"]))
    elif isinstance(record.get("recall_at_k"), (int, float)):
        benchmark_recalls.append(float(record["recall_at_k"]))

benchmark_recall = mean(benchmark_recalls) if benchmark_recalls else None

if success_rate is None and benchmark_recall is None:
    quality_score = None
elif success_rate is None:
    quality_score = benchmark_recall
elif benchmark_recall is None:
    quality_score = success_rate
else:
    quality_score = (0.7 * success_rate) + (0.3 * benchmark_recall)

print("=== Merlin Quality Score ===")
print(f"window_days: {days}")
print("backend: jsonl")
print("langfuse_enabled: false")
print("external_telemetry: false")
print(f"outcomes_read: {len(outcomes)}")
print(f"route_traces_read: {len(traces)}")
print(f"benchmark_records_read: {len(benchmarks)}")
print(f"success_rate: {success_rate:.3f}" if success_rate is not None else "success_rate: n/a")
print(f"benchmark_recall: {benchmark_recall:.3f}" if benchmark_recall is not None else "benchmark_recall: n/a")
print(f"quality_score: {quality_score:.3f}" if quality_score is not None else "quality_score: n/a")
print(f"avg_latency_ms: {avg_latency}")
print(f"low_confidence_successes: {len(low_confidence_successes)}")
print(f"approval_required_traces: {approval_required}")
print(f"approval_not_required_traces: {approval_not_required}")
print(f"outcome_log: {outcome_path}")
print(f"trace_log: {trace_path}")
print(f"benchmark_log: {benchmark_path}")
PY
