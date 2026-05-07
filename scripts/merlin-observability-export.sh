#!/usr/bin/env bash
# Local JSONL to Langfuse exporter for optional observability profile.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
LOG_DIR="${MERLIN_LOG_DIR:-${STACK_DIR}/logs}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-observability-export.sh [export] [options]

Options:
  --dry-run                 Count planned exports without network calls (default)
  --live                    Send redacted metadata to local self-hosted Langfuse
  --langfuse-url <url>      Local Langfuse base URL, default http://localhost:3010
  --public-key <key>        Langfuse public key, or LANGFUSE_PUBLIC_KEY
  --secret-key <key>        Langfuse secret key, or LANGFUSE_SECRET_KEY
  --log-dir <path>          Logs directory, default $STACK_DIR/logs
  --trace-log <path>        Override route trace JSONL path
  --approval-log <path>     Override approval JSONL path
  --outcome-log <path>      Override outcome JSONL path
  --benchmark-log <path>    Override benchmark JSONL path
  --limit <n>               Max records per source, default 500

Dry-run is fully offline. Live export is explicit, localhost-only, and exports
redacted metadata only. It refuses hosted/cloud Langfuse URLs.
EOF
}

COMMAND="${1:-export}"
if [[ "$COMMAND" == "export" ]]; then
  shift || true
elif [[ "$COMMAND" == --* ]]; then
  COMMAND="export"
elif [[ "$COMMAND" == "--help" || "$COMMAND" == "-h" ]]; then
  usage
  exit 0
else
  echo "ERROR: unknown command: $COMMAND" >&2
  usage >&2
  exit 1
fi

python3 - "$LOG_DIR" "$@" <<'PY'
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

DEFAULT_LANGFUSE_URL = "http://localhost:3010"
LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1"}
CLOUD_HOST_MARKERS = ("cloud.langfuse.com", "us.cloud.langfuse.com", "eu.cloud.langfuse.com")

SAFE_TRACE_FIELDS = {
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
}
SAFE_APPROVAL_FIELDS = {
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
}
SAFE_OUTCOME_FIELDS = {
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
}
SAFE_BENCHMARK_FIELDS = {
    "generated_at",
    "suite",
    "profile",
    "summaries",
    "recall_at_k",
    "precision_at_k",
    "latency_ms",
}
FORBIDDEN_KEYS = {
    "prompt",
    "completion",
    "input",
    "output",
    "raw_input",
    "raw_prompt",
    "raw_output",
    "text",
    "document",
    "content",
    "api_key",
    "apikey",
    "authorization",
    "cookie",
    "password",
    "secret",
    "token",
    "private_key",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(add_help=False)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--live", action="store_true")
    parser.add_argument("--langfuse-url", default=os.environ.get("LANGFUSE_HOST", DEFAULT_LANGFUSE_URL))
    parser.add_argument("--public-key", default=os.environ.get("LANGFUSE_PUBLIC_KEY", ""))
    parser.add_argument("--secret-key", default=os.environ.get("LANGFUSE_SECRET_KEY", ""))
    parser.add_argument("--log-dir", default=sys.argv[1])
    parser.add_argument("--trace-log", default="")
    parser.add_argument("--approval-log", default="")
    parser.add_argument("--outcome-log", default="")
    parser.add_argument("--benchmark-log", default="")
    parser.add_argument("--limit", type=int, default=500)
    parser.add_argument("--help", "-h", action="store_true")
    args = parser.parse_args(sys.argv[2:])
    if args.help:
        raise SystemExit(2)
    if args.limit <= 0:
        raise SystemExit("ERROR: --limit requires a positive integer")
    return args


def read_jsonl(path: Path, limit: int) -> list[dict[str, Any]]:
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
    return records[-limit:]


def local_url_only(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise SystemExit("ERROR: Langfuse URL must use http or https")
    host = (parsed.hostname or "").lower()
    if host not in LOCAL_HOSTS:
        raise SystemExit("ERROR: refusing non-local Langfuse URL")
    if any(marker in host for marker in CLOUD_HOST_MARKERS):
        raise SystemExit("ERROR: refusing hosted Langfuse URL")
    return url.rstrip("/")


def scrub_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            str(k): scrub_value(v)
            for k, v in value.items()
            if str(k).casefold() not in FORBIDDEN_KEYS
        }
    if isinstance(value, list):
        return [scrub_value(v) for v in value[:20]]
    if isinstance(value, str):
        if len(value) > 240:
            return value[:237] + "..."
        return value
    if isinstance(value, (int, float, bool)) or value is None:
        return value
    return str(value)


def safe_payload(record: dict[str, Any], allowed_fields: set[str]) -> dict[str, Any]:
    return {
        key: scrub_value(record[key])
        for key in sorted(allowed_fields)
        if key in record and key.casefold() not in FORBIDDEN_KEYS
    }


def stable_id(source: str, record: dict[str, Any], fallback_index: int) -> str:
    for key in ("trace_id", "approval_request_id", "task_hash", "id"):
        if record.get(key):
            return f"merlin-{source}-{record[key]}"
    raw = json.dumps(record, sort_keys=True, separators=(",", ":"))
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()[:24]
    return f"merlin-{source}-{fallback_index}-{digest}"


def record_timestamp(record: dict[str, Any]) -> str:
    value = record.get("timestamp") or record.get("created_at") or record.get("generated_at")
    if isinstance(value, str) and value:
        return value
    return datetime.now(UTC).isoformat()


def event_for(source: str, record: dict[str, Any], payload: dict[str, Any], index: int) -> dict[str, Any]:
    trace_id = stable_id(source, record, index)
    route_id = payload.get("route_id", source)
    return {
        "id": f"{trace_id}-event",
        "timestamp": record_timestamp(record),
        "type": "trace-create",
        "body": {
            "id": trace_id,
            "timestamp": record_timestamp(record),
            "name": f"merlin.{source}.{route_id}",
            "metadata": {
                "source": source,
                "origin": "home-ai-elite-jsonl-export",
                "redacted": True,
                "payload": payload,
            },
        },
    }


def build_events(paths: dict[str, Path], limit: int) -> tuple[dict[str, int], list[dict[str, Any]]]:
    specs = {
        "route": ("trace", SAFE_TRACE_FIELDS),
        "approval": ("approval", SAFE_APPROVAL_FIELDS),
        "outcome": ("outcome", SAFE_OUTCOME_FIELDS),
        "benchmark": ("benchmark", SAFE_BENCHMARK_FIELDS),
    }
    counts: dict[str, int] = {}
    events: list[dict[str, Any]] = []
    for source, (path_key, fields) in specs.items():
        records = read_jsonl(paths[path_key], limit)
        counts[source] = len(records)
        for index, record in enumerate(records):
            payload = safe_payload(record, fields)
            events.append(event_for(source, record, payload, index))
    return counts, events


def print_summary(args: argparse.Namespace, paths: dict[str, Path], counts: dict[str, int], events: list[dict[str, Any]], status: str) -> None:
    print("=== Merlin Observability Export ===")
    print("source_backend: jsonl")
    print(f"mode: {'live' if args.live else 'dry-run'}")
    print(f"export_status: {status}")
    print(f"langfuse_url: {args.langfuse_url}")
    print("external_telemetry: false")
    print("raw_payload_exported: false")
    print(f"route_records: {counts.get('route', 0)}")
    print(f"approval_records: {counts.get('approval', 0)}")
    print(f"outcome_records: {counts.get('outcome', 0)}")
    print(f"benchmark_records: {counts.get('benchmark', 0)}")
    print(f"planned_events: {len(events)}")
    print(f"trace_log: {paths['trace']}")
    print(f"approval_log: {paths['approval']}")
    print(f"outcome_log: {paths['outcome']}")
    print(f"benchmark_log: {paths['benchmark']}")


def post_ingestion(base_url: str, public_key: str, secret_key: str, events: list[dict[str, Any]]) -> tuple[str, str]:
    if not public_key or not secret_key:
        raise SystemExit("ERROR: --live requires --public-key/--secret-key or LANGFUSE_PUBLIC_KEY/LANGFUSE_SECRET_KEY")
    endpoint = f"{base_url}/api/public/ingestion"
    body = json.dumps({"batch": events}, separators=(",", ":")).encode("utf-8")
    token = base64.b64encode(f"{public_key}:{secret_key}".encode("utf-8")).decode("ascii")
    request = urllib.request.Request(
        endpoint,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Basic {token}",
            "Content-Type": "application/json",
            "User-Agent": "home-ai-elite-jsonl-exporter",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            payload = response.read().decode("utf-8", errors="replace")[:500]
            return "exported", f"http_status: {response.status} response: {payload}"
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        return "skipped", f"warning: Langfuse unavailable — {exc}"


def main() -> None:
    args = parse_args()
    if not args.dry_run and not args.live:
        args.dry_run = True
    args.langfuse_url = local_url_only(args.langfuse_url)

    log_dir = Path(args.log_dir)
    paths = {
        "trace": Path(args.trace_log or log_dir / "merlin-route-decisions.jsonl"),
        "approval": Path(args.approval_log or log_dir / "merlin-approvals.jsonl"),
        "outcome": Path(args.outcome_log or log_dir / "merlin-outcomes.jsonl"),
        "benchmark": Path(args.benchmark_log or log_dir / "merlin-benchmarks.jsonl"),
    }
    counts, events = build_events(paths, args.limit)

    if args.dry_run:
        print_summary(args, paths, counts, events, "planned")
        return

    status, detail = post_ingestion(args.langfuse_url, args.public_key, args.secret_key, events)
    print_summary(args, paths, counts, events, status)
    print(detail)


try:
    main()
except SystemExit as exc:
    if exc.code == 2:
        print("Use: scripts/merlin-observability-export.sh --help", file=sys.stderr)
    raise
PY
