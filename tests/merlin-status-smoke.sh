#!/usr/bin/env bash
# Smoke-test read-only Merlin status summary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_output() {
  local output="$1"
  local pattern="$2"
  local label="$3"
  echo "$output" | grep -Eq -- "$pattern" || fail "$label"
}

TRACE_LOG="${TMP}/merlin-route-decisions.jsonl"
APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"

HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "debug token sk-test installer" >/dev/null

APPROVAL_ID="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" | awk '/id: approval_dryrun_/ { print $3; exit }')"
[[ -n "$APPROVAL_ID" ]] || fail "approval id should be parseable"
bash "${STACK_DIR}/scripts/merlin-approvals.sh" approve "$APPROVAL_ID" --approval-log "$APPROVAL_LOG" >/dev/null

HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "research current installer issue" >/dev/null

STATUS_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-status.sh" --trace-log "$TRACE_LOG" --approval-log "$APPROVAL_LOG")"
require_output "$STATUS_OUTPUT" '^Merlin status$' "status heading missing"
require_output "$STATUS_OUTPUT" '^active_profile: core$' "active profile missing"
require_output "$STATUS_OUTPUT" '^privacy_mode: local_only$' "privacy mode should be local only"
require_output "$STATUS_OUTPUT" '^online_mode: false$' "online mode should default false"
require_output "$STATUS_OUTPUT" '^cloud_allowed: false$' "cloud should default false"
require_output "$STATUS_OUTPUT" "^trace_log: ${TRACE_LOG}$" "trace log path missing"
require_output "$STATUS_OUTPUT" '^trace_count: 2$' "trace count should include two route decisions"
require_output "$STATUS_OUTPUT" "^approval_log: ${APPROVAL_LOG}$" "approval log path missing"
require_output "$STATUS_OUTPUT" '^approval_total: 2$' "approval total should use latest approval ids"
require_output "$STATUS_OUTPUT" '^approval_pending: 1$' "approval pending count missing"
require_output "$STATUS_OUTPUT" '^approval_approved: 1$' "approval approved count missing"
require_output "$STATUS_OUTPUT" '^approval_denied: 0$' "approval denied count missing"
require_output "$STATUS_OUTPUT" '^service_open_webui: (running|down)$' "service status missing"
require_output "$STATUS_OUTPUT" '^side_effects: none$' "status should have no side effects"
require_output "$STATUS_OUTPUT" '^execution_allowed: false$' "status must not allow execution"

if echo "$STATUS_OUTPUT" | grep -Eq -- 'sk-test|debug token'; then
  fail "status must not expose raw goal or secret-like text"
fi

WIZARD_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/cli/wizard" merlin status --trace-log "$TRACE_LOG" --approval-log "$APPROVAL_LOG")"
require_output "$WIZARD_OUTPUT" '^Merlin status$' "wizard merlin status should call status script"
require_output "$WIZARD_OUTPUT" '^approval_pending: 1$' "wizard status should include approval counts"

echo "PASS: Merlin status is read-only and local-first"
