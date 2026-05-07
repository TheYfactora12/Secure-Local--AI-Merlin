#!/usr/bin/env bash
# Static smoke test for v1.1 mobile/LAN access planning.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN="${ROOT_DIR}/docs/MOBILE_ACCESS_PLAN.md"
SECURITY="${ROOT_DIR}/docs/security/SECURITY_MODEL.md"
COMPOSE="${ROOT_DIR}/docker-compose.yml"
ENV_EXAMPLE="${ROOT_DIR}/.env.example"
DOCTOR="${ROOT_DIR}/scripts/doctor.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$PLAN" ]] || fail "missing docs/MOBILE_ACCESS_PLAN.md"

grep -q "localhost-only by default" "$PLAN" \
  || fail "mobile plan must state localhost-only default"
grep -q "explicitly enabled" "$PLAN" \
  || fail "mobile plan must require explicit enablement"
grep -q "127.0.0.1" "$PLAN" \
  || fail "mobile plan must reference localhost bind"
grep -q "0.0.0.0" "$PLAN" \
  || fail "mobile plan must document LAN bind risk"
grep -q "No cloud calls occur" "$PLAN" \
  || fail "mobile plan must keep cloud behavior off by default"
grep -q "Do not expose these services directly" "$PLAN" \
  || fail "mobile plan must define direct exposure denylist"

for service in Qdrant Ollama LiteLLM n8n OpenHands; do
  grep -q "$service" "$PLAN" || fail "mobile plan missing $service exposure rule"
done

for gate in external_network service_start api_key_use memory_write secret_access cloud_model_call; do
  grep -q "$gate" "$PLAN" || fail "mobile plan missing $gate gate mapping"
done

grep -q "docs/MOBILE_ACCESS_PLAN.md" "$SECURITY" \
  || fail "security model must link the mobile access plan"
grep -q "Bind defaults stay on 127.0.0.1" "$ENV_EXAMPLE" \
  || fail ".env.example must preserve localhost bind guidance"
grep -q "Change \\*_BIND to 0.0.0.0 only when you intentionally want LAN access" "$ENV_EXAMPLE" \
  || fail ".env.example must mark LAN access as intentional"

grep -q 'DASHBOARD_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "dashboard must default to localhost bind"
grep -q 'OPEN_WEBUI_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "Open WebUI must default to localhost bind"
grep -q 'LITELLM_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "LiteLLM must default to localhost bind"
grep -q 'QDRANT_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "Qdrant must default to localhost bind"
grep -q 'N8N_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "n8n must default to localhost bind"
grep -q 'OLLAMA_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "Ollama must default to localhost bind"
grep -q 'OPENHANDS_BIND:-127.0.0.1' "$COMPOSE" \
  || fail "OpenHands must default to localhost bind"

grep -q 'fail "$key=0.0.0.0 exposes a service beyond localhost"' "$DOCTOR" \
  || fail "doctor must fail on insecure 0.0.0.0 binds"

if grep -qi "default.*0.0.0.0" "$PLAN"; then
  fail "mobile plan must not describe 0.0.0.0 as a default"
fi

echo "PASS: mobile access plan preserves local-first opt-in boundaries"
