#!/usr/bin/env bash
# Static smoke test for native Merlin Chat in Wizard HQ.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q "Merlin Chat" "$DASHBOARD_FILE" \
  || fail "dashboard missing native Merlin Chat heading"
grep -q "Merlin AI core face" "$DASHBOARD_FILE" \
  || fail "dashboard missing centered Merlin AI core face"
grep -q "merlin-face" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin face visual"
grep -q "Talk to Merlin first" "$DASHBOARD_FILE" \
  || fail "dashboard missing clean Merlin-first chat copy"
grep -q 'id="merlin-chat-input"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat input"
grep -q 'id="merlin-chat-submit"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat submit button"
grep -q "function submitMerlinChat" "$DASHBOARD_FILE" \
  || fail "dashboard missing Merlin Chat submit handler"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE" \
  || fail "Merlin Chat must call only Merlin Task API /task"
grep -q "method: 'POST'" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing Task API POST"
grep -q "selected_model_alias" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must display selected model alias"
grep -q "staff_mode" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must display staff mode"
grep -q "approval required" "$DASHBOARD_FILE" \
  || fail "Merlin Chat must handle approval-required routes"
grep -q "Task API is classifying the request and checking policy gates" "$DASHBOARD_FILE" \
  || fail "Merlin Chat missing policy-gate routing copy"

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"

if grep -q "api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  fail "native chat must not call model backends directly"
fi

if grep -qiE 'approveGate|denyGate|data-action="approve"|data-action="deny"|writeMemory|runShell|downloadModel|pullModel' "$DASHBOARD_FILE"; then
  fail "native chat must not expose unsafe browser controls"
fi

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "native chat must not expose secret-like values"
fi

echo "PASS: Wizard HQ native Merlin Chat is policy-gated through Task API"
