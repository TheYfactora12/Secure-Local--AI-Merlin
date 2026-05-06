#!/usr/bin/env bash
# Static smoke test for the optional automation profile.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  grep -Eq "$pattern" "$file" || fail "$label"
}

require_grep 'automation\)' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing automation capability"
require_grep 'services\+=\(n8n\)' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing n8n service mapping"

require_grep 'bash "\$\{SCRIPT_DIR\}/start-core\.sh"' "${STACK_DIR}/scripts/start-automation.sh" "start-automation does not start core first"
require_grep 'ensure_docker_cli' "${STACK_DIR}/scripts/start-automation.sh" "start-automation does not verify Docker CLI"
require_grep 'docker info >/dev/null 2>&1' "${STACK_DIR}/scripts/start-automation.sh" "start-automation does not verify Docker engine"
require_grep 'docker compose up -d n8n' "${STACK_DIR}/scripts/start-automation.sh" "start-automation starts the wrong services"

require_grep 'n8nio/n8n:1\.87\.1' "${STACK_DIR}/docker-compose.yml" "n8n image should be version-pinned"
require_grep '127\.0\.0\.1.*N8N_PORT' "${STACK_DIR}/docker-compose.yml" "n8n is not localhost-bound by default"
require_grep 'N8N_BASIC_AUTH_ACTIVE=true' "${STACK_DIR}/docker-compose.yml" "n8n basic auth is not enabled"
require_grep 'N8N_BASIC_AUTH_PASSWORD=.*REQUIRED_CHANGE_ME' "${STACK_DIR}/docker-compose.yml" "n8n password fallback is not guarded"
require_grep 'N8N_ENCRYPTION_KEY=.*REQUIRED_CHANGE_ME' "${STACK_DIR}/docker-compose.yml" "n8n encryption key fallback is not guarded"
require_grep 'N8N_SECURE_COOKIE=.*false' "${STACK_DIR}/docker-compose.yml" "n8n secure cookie local default missing"
require_grep 'memory: 1g' "${STACK_DIR}/docker-compose.yml" "n8n memory limit missing"
require_grep 'http://127\.0\.0\.1:5678/healthz' "${STACK_DIR}/docker-compose.yml" "n8n healthcheck missing"

require_grep 'N8N_API_KEY is not set' "${STACK_DIR}/scripts/import-n8n-workflows.sh" "workflow import should skip without API key"
require_grep 'X-N8N-API-KEY' "${STACK_DIR}/scripts/import-n8n-workflows.sh" "workflow import does not use n8n API key header"
require_grep '/api/v1/workflows' "${STACK_DIR}/scripts/import-n8n-workflows.sh" "workflow import does not use n8n workflow API"
if grep -q 'mapfile' "${STACK_DIR}/scripts/import-n8n-workflows.sh"; then
  fail "workflow import uses mapfile, which is not portable to macOS default Bash"
fi

workflow_count="$(find "${STACK_DIR}/n8n-workflows" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')"
[[ "$workflow_count" -gt 0 ]] || fail "expected starter n8n workflow JSON files"

for workflow in "${STACK_DIR}"/n8n-workflows/*.json; do
  jq empty "$workflow" >/dev/null || fail "invalid workflow JSON: $workflow"
done

echo "PASS: automation profile static configuration is safe"
