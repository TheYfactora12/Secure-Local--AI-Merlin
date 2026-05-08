#!/usr/bin/env bash
# Static smoke test for Wizard HQ first-run product clarity.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "First Run" "$DASHBOARD_FILE" \
  || fail "dashboard missing first-run panel"
grep -q "Open Merlin Chat Workspace" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin chat workspace action"
grep -q 'id="open-chat-workspace"' "$DASHBOARD_FILE" \
  || fail "dashboard missing stable chat workspace launch link"
grep -q "http://localhost:3000" "$DASHBOARD_FILE" \
  || fail "dashboard missing local chat workspace link"
grep -q "Open WebUI runs the chat engine today; Merlin owns routing, policy, memory, and status around it" "$DASHBOARD_FILE" \
  || fail "dashboard missing honest Merlin/Open WebUI product boundary"
grep -q "Understand the Brain" "$DASHBOARD_FILE" \
  || fail "dashboard missing plain-language Merlin/Qwen explanation"
grep -q "Qwen is a current local model engine" "$DASHBOARD_FILE" \
  || fail "dashboard does not explain Qwen as a model engine"
grep -q "Merlin is the routing, policy, memory, and audit layer" "$DASHBOARD_FILE" \
  || fail "dashboard does not explain Merlin's role"
grep -q "Setup Center" "$DASHBOARD_FILE" \
  || fail "dashboard missing setup center placeholder"
grep -q "External providers, model downloads, memory writes, and agent actions are disabled or approval-gated by default" "$DASHBOARD_FILE" \
  || fail "dashboard missing safe setup default language"
grep -q "Secrets Protected" "$DASHBOARD_FILE" \
  || fail "dashboard missing protected-values status"
grep -q "Current model workspace" "$DASHBOARD_FILE" \
  || fail "dashboard missing local chat command hint"
grep -q "bash launchd/install-launchd.sh" "$DASHBOARD_FILE" \
  || fail "dashboard missing persistent launchd first-run command"
grep -q "bash scripts/merlin-task-api.sh start" "$DASHBOARD_FILE" \
  || fail "dashboard missing manual task API first-run command"
grep -q "35-40 seconds" "$DASHBOARD_FILE" \
  || fail "dashboard missing launchd warmup language"
grep -q "bash scripts/doctor.sh" "$DASHBOARD_FILE" \
  || fail "dashboard missing doctor verification command after API warmup"

if grep -qiE '<input|<textarea|type="password"|api[_-]?key|token[[:space:]]*[:=]|password[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not expose forms or secret-like fields"
fi

if grep -q "method:'POST'\\|method: 'POST'\\|method: \"POST\"\\|fetch(.*POST" "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not introduce POST or execution calls"
fi

if grep -qiE '<button[^>]*>[^<]*(download|pull|approve|run|write|configure)|downloadModel|pullModel|runShell|writeMemory|configureProvider' "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not imply unsafe setup actions are available"
fi

echo "PASS: Wizard HQ first-run product clarity is safe and read-only"
