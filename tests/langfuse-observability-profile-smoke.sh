#!/usr/bin/env bash
# Static smoke test for optional Langfuse observability profile.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_COMPOSE="${ROOT_DIR}/docker-compose.yml"
OBS_COMPOSE="${ROOT_DIR}/docker-compose.observability.yml"
CONFIG_EXAMPLE="${ROOT_DIR}/configs/langfuse/langfuse.env.example"
START_SCRIPT="${ROOT_DIR}/scripts/start-observability.sh"
HEALTHCHECK="${ROOT_DIR}/scripts/healthcheck.sh"
WIZARD="${ROOT_DIR}/cli/wizard"
GUIDE="${ROOT_DIR}/docs/observability-guide.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  grep -Eq -- "$pattern" "$file" || fail "$label"
}

[[ -f "$OBS_COMPOSE" ]] || fail "docker-compose.observability.yml missing"
[[ -f "$CONFIG_EXAMPLE" ]] || fail "Langfuse config example missing"
[[ -x "$START_SCRIPT" ]] || fail "start-observability.sh not executable"

if grep -Eq '^[[:space:]]+langfuse-' "$DEFAULT_COMPOSE"; then
  fail "default docker-compose.yml must not define Langfuse services"
fi

OBS_COMPOSE="$OBS_COMPOSE" python3 - <<'PY' || fail "observability compose profile validation failed"
from __future__ import annotations

import os
import re
from pathlib import Path

text = Path(os.environ["OBS_COMPOSE"]).read_text(encoding="utf-8")
services = [
    "langfuse-worker",
    "langfuse-web",
    "langfuse-clickhouse",
    "langfuse-minio",
    "langfuse-redis",
    "langfuse-postgres",
]

for service in services:
    match = re.search(rf"^  {re.escape(service)}:\n(?P<body>.*?)(?=^  [A-Za-z0-9_-]+:|\Z)", text, re.M | re.S)
    if not match:
        raise SystemExit(f"missing service: {service}")
    body = match.group("body")
    if 'profiles: ["observability"]' not in body:
        raise SystemExit(f"{service} is not observability-profile gated")
    if "127.0.0.1" not in body and "ports:" in body:
        raise SystemExit(f"{service} publishes a port without localhost bind")

if ":3000:3000" in text or "- 3000:3000" in text:
    raise SystemExit("Langfuse must not claim Open WebUI host port 3000")
if "${LANGFUSE_PORT:-3010}:3000" not in text:
    raise SystemExit("Langfuse web must bind host port 3010 by default")
if "cloud.langfuse.com" in text or "us.cloud.langfuse.com" in text or "eu.cloud.langfuse.com" in text:
    raise SystemExit("observability compose must not point at hosted Langfuse")
if 'TELEMETRY_ENABLED: "${LANGFUSE_TELEMETRY_ENABLED:-false}"' not in text:
    raise SystemExit("Langfuse telemetry must default false")
PY

require_grep '^LANGFUSE_BIND=127\.0\.0\.1$' "$CONFIG_EXAMPLE" "Langfuse bind must default localhost"
require_grep '^LANGFUSE_PORT=3010$' "$CONFIG_EXAMPLE" "Langfuse host port must default 3010"
require_grep '^LANGFUSE_TELEMETRY_ENABLED=false$' "$CONFIG_EXAMPLE" "Langfuse telemetry must default false"

if grep -Eq '^[A-Z0-9_]*(SECRET|PASSWORD|KEY|AUTH)=.{24,}$' "$CONFIG_EXAMPLE"; then
  fail "Langfuse example must not contain long secret-like values"
fi

require_grep 'RAM_GB < 16' "$START_SCRIPT" "observability start must guard low RAM"
require_grep 'HOME_AI_ALLOW_LOW_TIER_OBSERVABILITY' "$START_SCRIPT" "low-tier override must be explicit"
require_grep 'docker-compose\.observability\.yml' "$START_SCRIPT" "start script must use optional compose override"
require_grep 'profile observability' "$START_SCRIPT" "start script must enable observability profile"

require_grep 'start observability' "$WIZARD" "wizard help missing observability start"
require_grep 'start-observability\.sh' "$WIZARD" "wizard start observability not wired"

require_grep 'HOME_AI_OBSERVABILITY_PROFILE_ACTIVE' "$HEALTHCHECK" "healthcheck must gate Langfuse"
require_grep 'Langfuse observability disabled; skipping health check' "$HEALTHCHECK" "healthcheck must skip Langfuse by default"

require_grep 'wizard start observability' "$GUIDE" "guide missing explicit observability start"
require_grep 'http://localhost:3010' "$GUIDE" "guide missing local Langfuse URL"

echo "PASS: optional Langfuse observability profile is gated and local-only"
