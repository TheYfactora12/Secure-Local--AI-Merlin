#!/usr/bin/env python3
"""Read-only Merlin status API.

This server exposes status visibility only. It does not approve, deny, execute,
start services, call models, write memory, download models, or use tools.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.error import URLError
from urllib.request import Request, urlopen


STACK_DIR = Path(__file__).resolve().parents[1]
DEFAULT_TRACE_LOG = STACK_DIR / "logs" / "merlin-route-decisions.jsonl"
DEFAULT_APPROVAL_LOG = STACK_DIR / "logs" / "merlin-approvals.jsonl"


def bool_from_env(name: str, default: bool = False) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def detect_ram_gb() -> int:
    try:
        result = subprocess.run(
            ["sysctl", "-n", "hw.memsize"],
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
        raw = result.stdout.strip()
        if raw.isdigit():
            return round(int(raw) / 1024 / 1024 / 1024)
    except (OSError, subprocess.SubprocessError):
        pass

    try:
        pages = os.sysconf("SC_PHYS_PAGES")
        page_size = os.sysconf("SC_PAGE_SIZE")
        if pages > 0 and page_size > 0:
            return round((pages * page_size) / 1024 / 1024 / 1024)
    except (OSError, ValueError, AttributeError):
        pass

    return 0


def hardware_tier_for_ram(ram_gb: int) -> str:
    if ram_gb >= 48:
        return "high"
    if ram_gb >= 24:
        return "mid"
    if ram_gb >= 16:
        return "base"
    if ram_gb > 0:
        return "low"
    return "unknown"


def jsonl_line_count(path: Path) -> int:
    if not path.exists():
        return 0
    count = 0
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                count += 1
    return count


def approval_counts(path: Path) -> dict[str, int]:
    latest: dict[str, dict[str, Any]] = {}
    if path.exists():
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                if not line.strip():
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                request_id = record.get("approval_request_id")
                if request_id:
                    latest[str(request_id)] = record

    counts = {"pending": 0, "approved": 0, "denied": 0}
    for record in latest.values():
        status = record.get("status")
        if status == "required_pending":
            counts["pending"] += 1
        elif status == "approved":
            counts["approved"] += 1
        elif status == "denied":
            counts["denied"] += 1

    counts["total"] = len(latest)
    return counts


def http_status(url: str) -> str:
    try:
        request = Request(url, method="GET")
        with urlopen(request, timeout=2) as response:
            if 100 <= response.status < 500:
                return "running"
    except (OSError, URLError, TimeoutError):
        pass
    return "down"


def merlin_status(trace_log: Path, approval_log: Path) -> dict[str, Any]:
    ram_gb = detect_ram_gb()
    hardware_tier = os.environ.get("MERLIN_HARDWARE_TIER") or hardware_tier_for_ram(ram_gb)
    services = {
        "dashboard": http_status("http://localhost:8888"),
        "open_webui": http_status("http://localhost:3000"),
        "litellm": http_status("http://localhost:4000/health/readiness"),
        "qdrant": http_status("http://localhost:6333/healthz"),
        "ollama": http_status("http://localhost:11434"),
    }

    return {
        "status": "ok",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "active_profile": os.environ.get("HOME_AI_PROFILE", "core"),
        "hardware_tier": hardware_tier,
        "ram_gb": ram_gb,
        "platform": platform.system().lower() or "unknown",
        "privacy_mode": os.environ.get("MERLIN_PRIVACY_MODE", "local_only"),
        "online_mode": bool_from_env("MERLIN_ONLINE_MODE", False),
        "cloud_allowed": bool_from_env("MERLIN_CLOUD_ALLOWED", False),
        "trace_log": str(trace_log),
        "trace_count": jsonl_line_count(trace_log),
        "approval_log": str(approval_log),
        "approvals": approval_counts(approval_log),
        "services": services,
        "side_effects": "none",
        "execution_allowed": False,
    }


class MerlinStatusHandler(BaseHTTPRequestHandler):
    trace_log: Path = DEFAULT_TRACE_LOG
    approval_log: Path = DEFAULT_APPROVAL_LOG

    def log_message(self, format: str, *args: Any) -> None:
        return

    def send_json(self, status_code: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        origin = self.headers.get("Origin", "")
        allowed_origins = {"http://localhost:8888", "http://127.0.0.1:8888"}
        self.send_header(
            "Access-Control-Allow-Origin",
            origin if origin in allowed_origins else "http://localhost:8888",
        )
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:
        self.send_json(200, {"status": "ok", "execution_allowed": False})

    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0]
        if path == "/healthz":
            self.send_json(200, {"status": "ok", "side_effects": "none", "execution_allowed": False})
            return
        if path == "/status":
            self.send_json(200, merlin_status(self.trace_log, self.approval_log))
            return
        self.send_json(404, {"status": "not_found", "execution_allowed": False})

    def do_POST(self) -> None:
        self.send_json(405, {"status": "method_not_allowed", "execution_allowed": False})

    do_PUT = do_POST
    do_PATCH = do_POST
    do_DELETE = do_POST


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only Merlin status API")
    parser.add_argument("--host", default=os.environ.get("MERLIN_STATUS_API_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("MERLIN_STATUS_API_PORT", "8765")))
    parser.add_argument("--trace-log", type=Path, default=Path(os.environ.get("MERLIN_TRACE_LOG", DEFAULT_TRACE_LOG)))
    parser.add_argument("--approval-log", type=Path, default=Path(os.environ.get("MERLIN_APPROVAL_LOG", DEFAULT_APPROVAL_LOG)))
    parser.add_argument("--port-file", type=Path, help="Write the bound port to this file after startup")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    MerlinStatusHandler.trace_log = args.trace_log
    MerlinStatusHandler.approval_log = args.approval_log
    server = ThreadingHTTPServer((args.host, args.port), MerlinStatusHandler)
    if args.port_file:
        args.port_file.write_text(str(server.server_port), encoding="utf-8")
    print(f"Merlin status API listening on http://{args.host}:{server.server_port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
