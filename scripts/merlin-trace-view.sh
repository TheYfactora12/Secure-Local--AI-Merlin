#!/usr/bin/env bash
# Local JSONL trace viewer for Merlin observability.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
LOG_DIR="${MERLIN_LOG_DIR:-${STACK_DIR}/logs}"
TRACE_LOG=""
APPROVAL_LOG=""
OUTCOME_LOG=""
LIMIT=20

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-trace-view.sh <trace_id|session_id|hash> [options]

Options:
  --log-dir <path>       Logs directory, default $STACK_DIR/logs
  --trace-log <path>     Override route trace JSONL path
  --approval-log <path>  Override approval JSONL path
  --outcome-log <path>   Override outcome JSONL path
  --limit <n>            Maximum matching records per section, default 20

Reads local redacted JSONL only. No Langfuse, Docker, Qdrant, Ollama, LiteLLM,
n8n, cloud, or network access is required.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

LOOKUP_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-dir)
      LOG_DIR="${2:-}"
      [[ -n "$LOG_DIR" ]] || fail "--log-dir requires a path"
      shift 2
      ;;
    --trace-log)
      TRACE_LOG="${2:-}"
      [[ -n "$TRACE_LOG" ]] || fail "--trace-log requires a path"
      shift 2
      ;;
    --approval-log)
      APPROVAL_LOG="${2:-}"
      [[ -n "$APPROVAL_LOG" ]] || fail "--approval-log requires a path"
      shift 2
      ;;
    --outcome-log)
      OUTCOME_LOG="${2:-}"
      [[ -n "$OUTCOME_LOG" ]] || fail "--outcome-log requires a path"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      [[ "$LIMIT" =~ ^[0-9]+$ && "$LIMIT" -gt 0 ]] || fail "--limit requires a positive integer"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      fail "unknown option: $1"
      ;;
    *)
      if [[ -z "$LOOKUP_ID" ]]; then
        LOOKUP_ID="$1"
        shift
      else
        fail "unexpected argument: $1"
      fi
      ;;
  esac
done

[[ -n "$LOOKUP_ID" ]] || { usage; exit 1; }

TRACE_LOG="${TRACE_LOG:-${LOG_DIR}/merlin-route-decisions.jsonl}"
APPROVAL_LOG="${APPROVAL_LOG:-${LOG_DIR}/merlin-approvals.jsonl}"
OUTCOME_LOG="${OUTCOME_LOG:-${LOG_DIR}/merlin-outcomes.jsonl}"

python3 - "$LOOKUP_ID" "$LIMIT" "$TRACE_LOG" "$APPROVAL_LOG" "$OUTCOME_LOG" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

lookup = sys.argv[1]
limit = int(sys.argv[2])
trace_path = Path(sys.argv[3])
approval_path = Path(sys.argv[4])
outcome_path = Path(sys.argv[5])


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    records: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(record, dict):
                records.append(record)
    return records


def values_for(record: dict[str, Any]) -> set[str]:
    keys = {
        "trace_id",
        "session_id",
        "approval_request_id",
        "task_hash",
        "user_goal_hash",
        "input_hash",
    }
    values = set()
    for key in keys:
        value = record.get(key)
        if value is not None:
            values.add(str(value))
    return values


def matches(record: dict[str, Any]) -> bool:
    values = values_for(record)
    return lookup in values or any(value.endswith(lookup) for value in values)


def clipped(value: Any, max_len: int = 160) -> str:
    text = json.dumps(value, separators=(",", ":")) if isinstance(value, (dict, list)) else str(value)
    return text if len(text) <= max_len else text[: max_len - 3] + "..."


def print_record(record: dict[str, Any], fields: list[str]) -> None:
    for field in fields:
        if field in record:
            print(f"  {field}: {clipped(record[field])}")


traces = [record for record in read_jsonl(trace_path) if matches(record)][-limit:]
approvals = [record for record in read_jsonl(approval_path) if matches(record)][-limit:]
outcomes = [record for record in read_jsonl(outcome_path) if matches(record)][-limit:]

print("=== Merlin Trace ===")
print("backend: jsonl")
print("langfuse_enabled: false")
print("external_telemetry: false")
print(f"lookup_id: {lookup}")
print(f"trace_matches: {len(traces)}")
print(f"approval_matches: {len(approvals)}")
print(f"outcome_matches: {len(outcomes)}")
print(f"trace_log: {trace_path}")
print(f"approval_log: {approval_path}")
print(f"outcome_log: {outcome_path}")
print("")

if not traces and not approvals and not outcomes:
    print("No matching local JSONL records found.")
    raise SystemExit(0)

if traces:
    print("Route traces:")
    for record in traces:
        print("- trace")
        print_record(
            record,
            [
                "trace_id",
                "timestamp",
                "user_goal_hash",
                "route_id",
                "task_type",
                "staff_mode",
                "selected_agent",
                "required_profile",
                "active_profile",
                "hardware_tier",
                "selected_model_alias",
                "approval_required",
                "approval_request_id",
                "approval_status",
                "policy_decision",
                "decision_reason",
                "redaction_applied",
            ],
        )
    print("")

if approvals:
    print("Approvals:")
    for record in approvals:
        print("- approval")
        print_record(
            record,
            [
                "approval_request_id",
                "timestamp",
                "status",
                "execution_allowed",
                "user_goal_hash",
                "route_id",
                "task_type",
                "selected_agent",
                "approval_gates",
                "policy_decision",
                "decision_reason",
                "redaction_applied",
            ],
        )
    print("")

if outcomes:
    print("Outcomes:")
    for record in outcomes:
        print("- outcome")
        print_record(
            record,
            [
                "created_at",
                "task_hash",
                "route_id",
                "staff_mode",
                "agent_target",
                "confidence_at_routing",
                "outcome_status",
                "latency_ms",
                "hardware_tier",
                "user_feedback",
                "skill_domain",
                "outcome_rating",
            ],
        )
PY
