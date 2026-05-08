#!/usr/bin/env bash
# Static smoke test for Wizard HQ Chat home product clarity.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -q 'class="chat-home tab-page active"' "$DASHBOARD_FILE" \
  || fail "Chat tab must be the primary product home"
grep -q "Merlin AI core face" "$DASHBOARD_FILE" \
  || fail "Chat home missing centered Merlin face"
grep -q ">Ask Merlin<" "$DASHBOARD_FILE" \
  || fail "Chat home missing Ask Merlin heading/button"
grep -q "placeholder=\"Ask Merlin...\"" "$DASHBOARD_FILE" \
  || fail "Chat home missing clean Ask Merlin input"
grep -q "Talk to Merlin first" "$DASHBOARD_FILE" \
  || fail "Chat home missing Merlin-first explanation"
grep -q "Qwen is a current local model engine" "$DASHBOARD_FILE" \
  || fail "Brains tab does not explain Qwen as a model engine"
grep -q "Merlin can grow toward its own tuned local model later" "$DASHBOARD_FILE" \
  || fail "Brains tab missing honest future Merlin model language"
grep -q "External provider setup is deferred" "$DASHBOARD_FILE" \
  || fail "Settings tab missing safe setup default language"
grep -q "bash launchd/install-launchd.sh" "$DASHBOARD_FILE" \
  || fail "dashboard missing persistent launchd command"
grep -q "bash scripts/merlin-task-api.sh start" "$DASHBOARD_FILE" \
  || fail "dashboard missing manual task API command"
grep -q "35-40 seconds" "$DASHBOARD_FILE" \
  || fail "dashboard missing launchd warmup language"

if grep -qiE '<input|type="password"|api[_-]?key|token[[:space:]]*[:=]|password[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not expose secret-like fields"
fi

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"
grep -q 'fetch(`${TASK_API}/task`' "$DASHBOARD_FILE" \
  || fail "dashboard POST must route only through Merlin Task API /task"

if grep -q "api/generate\\|/api/chat\\|/v1/chat/completions\\|localhost:4000/v1" "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not call model backends directly"
fi

if grep -qiE '<button[^>]*>[^<]*(download|pull|approve|run|write|configure)|downloadModel|pullModel|runShell|writeMemory|configureProvider' "$DASHBOARD_FILE"; then
  fail "dashboard first-run must not imply unsafe setup actions are available"
fi

echo "PASS: Wizard HQ Chat home product clarity is safe and read-only"
