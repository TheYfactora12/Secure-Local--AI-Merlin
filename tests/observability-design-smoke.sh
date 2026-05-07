#!/usr/bin/env bash
# Static v1.6 observability design gate.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDE="${ROOT_DIR}/docs/observability-guide.md"
TRACE="${ROOT_DIR}/configs/merlin/trace.yaml"
LITELLM="${ROOT_DIR}/configs/litellm/config.yaml"
COMPOSE="${ROOT_DIR}/docker-compose.yml"
ROADMAP="${ROOT_DIR}/docs/MERLIN_IMPLEMENTATION_ROADMAP.md"
CONTEXT="${ROOT_DIR}/docs/MASTER_CONTEXT.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  grep -Eiq -- "$pattern" "$file" || fail "$label"
}

[[ -f "$GUIDE" ]] || fail "docs/observability-guide.md missing"
[[ -f "$TRACE" ]] || fail "configs/merlin/trace.yaml missing"
[[ -f "$LITELLM" ]] || fail "LiteLLM config missing"
[[ -f "$COMPOSE" ]] || fail "docker-compose.yml missing"

require_grep 'logs/merlin-route-decisions\.jsonl' "$GUIDE" "guide missing route JSONL baseline"
require_grep 'logs/merlin-approvals\.jsonl' "$GUIDE" "guide missing approvals JSONL baseline"
require_grep 'No hidden telemetry' "$GUIDE" "guide missing no hidden telemetry contract"
require_grep '8GB Macs are the entry point' "$GUIDE" "guide missing 8GB behavior"
require_grep 'optional' "$GUIDE" "guide missing optional trace UI"
require_grep 'profile-gated' "$GUIDE" "guide missing profile-gated trace UI"
require_grep 'must not start an observability' "$GUIDE" "guide missing low/core no-service default"
require_grep 'not replace JSONL as the baseline' "$GUIDE" "guide missing JSONL baseline preservation"
require_grep 'port `3000`' "$GUIDE" "guide must reserve port 3000 for Open WebUI"

require_grep 'default_sink: local_file' "$TRACE" "trace schema must default to local_file"
require_grep 'redact_before_write: true' "$TRACE" "trace schema must redact before write"
require_grep 'logs/merlin-route-decisions\.jsonl' "$TRACE" "trace schema missing route JSONL path"

require_grep 'telemetry:[[:space:]]*false' "$LITELLM" "LiteLLM telemetry must stay disabled"

if grep -Eiq '^[[:space:]]+langfuse:' "$COMPOSE"; then
  awk '
    /^[[:space:]]+langfuse:/ { in_service=1 }
    in_service && /^[[:space:]]+[A-Za-z0-9_-]+:/ && $1 != "langfuse:" { exit }
    in_service { print }
  ' "$COMPOSE" | grep -Eq 'profiles:.*observability' \
    || fail "Langfuse service must be behind an observability profile"
  awk '
    /^[[:space:]]+langfuse:/ { in_service=1 }
    in_service && /^[[:space:]]+[A-Za-z0-9_-]+:/ && $1 != "langfuse:" { exit }
    in_service { print }
  ' "$COMPOSE" | grep -Eq '3000:' \
    && fail "Langfuse must not bind port 3000; Open WebUI owns 3000"
fi

if grep -Eiq 'LANGFUSE_(HOST|PUBLIC_KEY|SECRET_KEY)=' "${ROOT_DIR}/.env.example"; then
  fail ".env.example must not require Langfuse keys for default installs"
fi

require_grep '#36|Observability design' "$ROADMAP" "roadmap must reference observability design"
require_grep '#8|Langfuse' "$ROADMAP" "roadmap must reference optional Langfuse child"
require_grep 'v1\.6' "$CONTEXT" "master context must mention v1.6"

echo "PASS: observability defaults to local JSONL and optional profile-gated tracing"
