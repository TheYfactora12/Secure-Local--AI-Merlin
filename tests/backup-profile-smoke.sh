#!/usr/bin/env bash
# Smoke-test that backup volume selection stays profile-aware and laptop-safe.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

core_output="$(HOME_AI_STACK_DIR="$STACK_DIR" bash "${STACK_DIR}/scripts/backup.sh" --dry-run --profile core)"
echo "$core_output" | grep -q "home-ai-elite_open-webui" \
  || fail "core backup did not include Open WebUI volume"
echo "$core_output" | grep -q "home-ai-elite_qdrant-storage" \
  || fail "core backup did not include Qdrant volume"
if echo "$core_output" | grep -Eq "n8n-data|perplexica-data|ollama"; then
  echo "$core_output" >&2
  fail "core backup included optional/heavy volumes"
fi

workstation_output="$(HOME_AI_STACK_DIR="$STACK_DIR" bash "${STACK_DIR}/scripts/backup.sh" --dry-run --profile workstation)"
echo "$workstation_output" | grep -q "home-ai-elite_perplexica-data" \
  || fail "workstation backup did not include search profile data"
echo "$workstation_output" | grep -q "home-ai-elite_n8n-data" \
  || fail "workstation backup did not include automation profile data"
if echo "$workstation_output" | grep -q "home-ai-elite_ollama"; then
  echo "$workstation_output" >&2
  fail "workstation backup included Docker Ollama without explicit opt-in"
fi

ollama_output="$(HOME_AI_STACK_DIR="$STACK_DIR" bash "${STACK_DIR}/scripts/backup.sh" --dry-run --profile core --include-docker-ollama)"
echo "$ollama_output" | grep -q "home-ai-elite_ollama" \
  || fail "Docker Ollama opt-in did not include Ollama volume"

custom_output="$(HOME_AI_STACK_DIR="$STACK_DIR" bash "${STACK_DIR}/scripts/backup.sh" --dry-run --profile custom --profiles search)"
echo "$custom_output" | grep -q "home-ai-elite_perplexica-data" \
  || fail "custom search backup did not include Perplexica data"
if echo "$custom_output" | grep -q "home-ai-elite_n8n-data"; then
  echo "$custom_output" >&2
  fail "custom search backup included automation data"
fi

echo "PASS: backup volume selection is profile-aware"
