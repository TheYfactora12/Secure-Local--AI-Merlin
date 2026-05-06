#!/usr/bin/env bash
# Static smoke test for the optional high-risk coding profile.
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

require_grep 'coding\)' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing coding capability"
require_grep 'services\+=\(openhands\)' "${STACK_DIR}/scripts/profile-lib.sh" "profile-lib missing OpenHands service mapping"

require_grep 'risk: high' "${STACK_DIR}/config/merlin/profiles.yaml" "coding profile is not marked high risk"
require_grep 'Docker socket access' "${STACK_DIR}/config/merlin/profiles.yaml" "coding profile risk reason missing"
require_grep 'starts_by_default: false' "${STACK_DIR}/config/merlin/profiles.yaml" "coding profile should not start by default"

require_grep 'bash "\$\{SCRIPT_DIR\}/start-core\.sh"' "${STACK_DIR}/scripts/start-coding.sh" "start-coding does not start core first"
require_grep 'ensure_docker_cli' "${STACK_DIR}/scripts/start-coding.sh" "start-coding does not verify Docker CLI"
require_grep 'docker info >/dev/null 2>&1' "${STACK_DIR}/scripts/start-coding.sh" "start-coding does not verify Docker engine"
require_grep 'Docker socket access' "${STACK_DIR}/scripts/start-coding.sh" "start-coding does not warn about Docker socket access"
require_grep 'Start OpenHands coding profile\? \[y/N\]' "${STACK_DIR}/scripts/start-coding.sh" "start-coding confirmation prompt missing"
require_grep 'Low-memory warning' "${STACK_DIR}/scripts/start-coding.sh" "start-coding low-memory warning missing"
require_grep 'docker compose up -d openhands' "${STACK_DIR}/scripts/start-coding.sh" "start-coding starts the wrong service set"

require_grep 'ghcr\.io/all-hands-ai/openhands:main' "${STACK_DIR}/docker-compose.yml" "OpenHands image missing"
require_grep '127\.0\.0\.1.*OPENHANDS_PORT' "${STACK_DIR}/docker-compose.yml" "OpenHands is not localhost-bound by default"
require_grep '/var/run/docker\.sock:/var/run/docker\.sock' "${STACK_DIR}/docker-compose.yml" "OpenHands Docker socket mount missing from risk test"
require_grep 'LLM_BASE_URL=http://litellm:4000' "${STACK_DIR}/docker-compose.yml" "OpenHands is not routed through LiteLLM"
require_grep 'LLM_API_KEY=.*LITELLM_MASTER_KEY' "${STACK_DIR}/docker-compose.yml" "OpenHands does not use LiteLLM master key env"
require_grep 'LLM_MODEL=.*OPENHANDS_MODEL' "${STACK_DIR}/docker-compose.yml" "OpenHands model env missing"
require_grep 'memory: 2g' "${STACK_DIR}/docker-compose.yml" "OpenHands memory limit missing"
require_grep 'OPENHANDS_MODEL=ollama/qwen2\.5-coder:7b' "${STACK_DIR}/.env.example" "OpenHands example model should be low-tier safe"

core_services="$(bash -c "source '${STACK_DIR}/scripts/profile-lib.sh'; profile_services_for_darwin ''" | tr '\n' ' ')"
if echo "$core_services" | grep -q 'openhands'; then
  fail "core macOS services include OpenHands"
fi

developer_services="$(bash -c "source '${STACK_DIR}/scripts/profile-lib.sh'; profile_services_for_darwin 'search'" | tr '\n' ' ')"
if echo "$developer_services" | grep -q 'openhands'; then
  fail "developer/search services include OpenHands"
fi

echo "PASS: coding profile static configuration is guarded"
