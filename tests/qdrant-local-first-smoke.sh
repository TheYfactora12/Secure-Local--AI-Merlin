#!/usr/bin/env bash
# Smoke-test Qdrant local-first privacy defaults without requiring live Qdrant.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="${ROOT_DIR}/docker-compose.yml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$COMPOSE" ]] || fail "Missing docker-compose.yml"

grep -q 'QDRANT__TELEMETRY_DISABLED=true' "$COMPOSE" \
  || fail "Qdrant telemetry must be disabled by default"

grep -q '"${QDRANT_BIND:-127.0.0.1}:${QDRANT_REST_PORT:-6333}:6333"' "$COMPOSE" \
  || fail "Qdrant REST API must bind to localhost by default"

if grep -q '6334:6334' "$COMPOSE"; then
  fail "Qdrant gRPC port must not be exposed by default"
fi

echo "PASS: Qdrant local-first privacy defaults are enforced"
