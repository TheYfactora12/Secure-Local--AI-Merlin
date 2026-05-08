#!/usr/bin/env bash
# Local redacted audit viewer for Merlin route, approval, memory, outcome, and Magic records.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
LOG_DIR="${MERLIN_LOG_DIR:-${STACK_DIR}/logs}"
LIMIT=20
EVENT_TYPE="all"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-audit-view.sh list [--log-dir <path>] [--type <type>] [--limit <n>]

Types:
  all, route, approval, magic, memory_read, memory_write, outcome

Reads local redacted JSONL only. It never calls Docker, Ollama, LiteLLM, Qdrant,
n8n, Langfuse, cloud APIs, or external network services.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] || { usage; exit 1; }
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-dir)
      LOG_DIR="${2:-}"
      [[ -n "$LOG_DIR" ]] || fail "--log-dir requires a path"
      shift 2
      ;;
    --type)
      EVENT_TYPE="${2:-}"
      [[ -n "$EVENT_TYPE" ]] || fail "--type requires a value"
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
      fail "unexpected argument: $1"
      ;;
  esac
done

[[ "$COMMAND" == "list" ]] || { usage; exit 1; }

case "$EVENT_TYPE" in
  all|route|approval|magic|memory_read|memory_write|outcome) ;;
  *) fail "unknown audit type: $EVENT_TYPE" ;;
esac

python3 - "$LOG_DIR" "$EVENT_TYPE" "$LIMIT" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

log_dir = Path(sys.argv[1])
event_type_filter = sys.argv[2]
limit = int(sys.argv[3])

sources = {
    "route": log_dir / "merlin-route-decisions.jsonl",
    "approval": log_dir / "merlin-approvals.jsonl",
    "magic": log_dir / "merlin-magic-plans.jsonl",
    "memory_read": log_dir / "merlin-memory-reads.jsonl",
    "memory_write": log_dir / "merlin-memory-writes.jsonl",
    "outcome": log_dir / "merlin-outcomes.jsonl",
}

secret_patterns = [
    (re.compile(r"AKIA[0-9A-Z]{16}"), "[REDACTED-AWS-KEY]"),
    (re.compile(r"eyJ[A-Za-z0-9_/+=-]{20,}"), "[REDACTED-JWT]"),
    (re.compile(r"sk-ant-[A-Za-z0-9_-]{20,}"), "[REDACTED-API-KEY]"),
    (re.compile(r"sk-[A-Za-z0-9]{20,}"), "[REDACTED-API-KEY]"),
    (re.compile(r"(?i)(password|secret|token|api_key|apikey|credential|private)(\s*=\s*)\S+"), r"\1\2[REDACTED]"),
]


def redact(value: Any) -> str:
    text = json.dumps(value, separators=(",", ":")) if isinstance(value, (dict, list)) else str(value)
    text = text.replace(str(Path.home()), "[REDACTED-PATH]")
    for pattern, replacement in secret_patterns:
        text = pattern.sub(replacement, text)
    return text if len(text) <= 180 else text[:177] + "..."


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
                parsed = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(parsed, dict):
                records.append(parsed)
    return records


def event_id(kind: str, record: dict[str, Any]) -> str:
    keys = {
        "route": "trace_id",
        "approval": "approval_request_id",
        "magic": "plan_id",
        "memory_read": "memory_read_id",
        "memory_write": "memory_write_id",
        "outcome": "task_hash",
    }
    return str(record.get(keys[kind]) or record.get("id") or "unknown")


def status_for(kind: str, record: dict[str, Any]) -> str:
    for key in ("status", "plan_status", "approval_status", "result_status", "outcome_status", "policy_decision"):
        if key in record and record[key] not in (None, ""):
            return str(record[key])
    return "unknown"


def hash_for(record: dict[str, Any]) -> str:
    for key in ("user_goal_hash", "task_hash", "input_hash", "query_hash", "memory_text_hash"):
        value = record.get(key)
        if value:
            return str(value)
    return "none"


def gates_for(record: dict[str, Any]) -> str:
    gates = record.get("approval_gates")
    if isinstance(gates, list):
        return ",".join(str(gate) for gate in gates) or "none"
    if isinstance(gates, str):
        return gates or "none"
    return "none"


events: list[tuple[str, dict[str, Any]]] = []
for kind, path in sources.items():
    if event_type_filter not in {"all", kind}:
        continue
    for record in read_jsonl(path):
        events.append((kind, record))

events.sort(key=lambda item: str(item[1].get("timestamp") or item[1].get("created_at") or ""))
events = events[-limit:]

print("Merlin audit viewer")
print("backend: local_jsonl")
print("external_telemetry: false")
print("execution_allowed: false")
print(f"log_dir: {log_dir}")
print(f"type_filter: {event_type_filter}")
print(f"count: {len(events)}")
print("")

if not events:
    print("No audit records found.")
    raise SystemExit(0)

for kind, record in events:
    print(f"- type: {kind}")
    print(f"  id: {redact(event_id(kind, record))}")
    print(f"  timestamp: {redact(record.get('timestamp') or record.get('created_at') or 'unknown')}")
    print(f"  status: {redact(status_for(kind, record))}")
    print(f"  route_id: {redact(record.get('route_id', 'none'))}")
    print(f"  hash: {redact(hash_for(record))}")
    print(f"  approval_gates: {redact(gates_for(record))}")
    print(f"  execution_allowed: {str(bool(record.get('execution_allowed', False))).lower()}")
    print(f"  redaction_applied: {str(bool(record.get('redaction_applied', True))).lower()}")
PY
