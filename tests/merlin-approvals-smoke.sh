#!/usr/bin/env bash
# Smoke-test read-only Merlin approval log listing.
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

APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"

EMPTY_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG")"
require_output "$EMPTY_OUTPUT" '^count: 0$' "empty approval log should report zero"
require_output "$EMPTY_OUTPUT" 'No approval requests found' "empty approval log message missing"

TRACE_LOG="${TMP}/trace.jsonl"
HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "debug token sk-test installer" >/dev/null

[[ -s "$APPROVAL_LOG" ]] || fail "dry-run should create approval log for risky route"

LIST_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG")"
require_output "$LIST_OUTPUT" '^count: 1$' "approval list should report one pending request"
require_output "$LIST_OUTPUT" 'id: approval_dryrun_' "approval list should show approval id"
require_output "$LIST_OUTPUT" 'status: required_pending' "approval list should show pending status"
require_output "$LIST_OUTPUT" 'execution_allowed: false' "approval list must not allow execution"
require_output "$LIST_OUTPUT" 'route_id: code' "approval list should show route"
require_output "$LIST_OUTPUT" 'shell_command' "approval list should show shell gate"
require_output "$LIST_OUTPUT" 'user_goal_hash: sha256:' "approval list should show user goal hash"

if echo "$LIST_OUTPUT" | grep -Eq -- 'sk-test|debug token'; then
  fail "approval list must not expose raw goal or secret-like text"
fi

ALL_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" --status all --limit 1)"
require_output "$ALL_OUTPUT" '^status_filter: all$' "approval list should support all status filter"
require_output "$ALL_OUTPUT" '^count: 1$' "approval list all status should include one request"

WIZARD_OUTPUT="$(MERLIN_APPROVAL_LOG="$APPROVAL_LOG" bash "${STACK_DIR}/cli/wizard" merlin approvals list)"
require_output "$WIZARD_OUTPUT" '^count: 1$' "wizard merlin approvals list should call approvals script"
require_output "$WIZARD_OUTPUT" 'execution_allowed: false' "wizard approval list must not allow execution"

APPROVAL_ID="$(echo "$LIST_OUTPUT" | awk '/id: approval_dryrun_/ { print $3; exit }')"
[[ -n "$APPROVAL_ID" ]] || fail "approval id should be parseable"

APPROVE_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" approve "$APPROVAL_ID" --approval-log "$APPROVAL_LOG")"
require_output "$APPROVE_OUTPUT" '^status: approved$' "approve should append approved decision"
require_output "$APPROVE_OUTPUT" '^decision_recorded: true$' "approve should record decision"
require_output "$APPROVE_OUTPUT" '^execution_allowed: false$' "approve must not allow execution"
require_output "$APPROVE_OUTPUT" '^side_effects: none$' "approve must have no side effects"
[[ "$(wc -l < "$APPROVAL_LOG" | tr -d ' ')" == "2" ]] || fail "approve should append one decision line"

PENDING_AFTER_APPROVE="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG")"
require_output "$PENDING_AFTER_APPROVE" '^count: 0$' "approved request should no longer list as pending"

ALL_AFTER_APPROVE="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" --status all)"
require_output "$ALL_AFTER_APPROVE" '^count: 1$' "latest-state all list should show one approval id"
require_output "$ALL_AFTER_APPROVE" 'status: approved' "all list should show approved latest status"
require_output "$ALL_AFTER_APPROVE" 'execution_allowed: false' "approved latest status must not allow execution"

if echo "$ALL_AFTER_APPROVE" | grep -Eq -- 'sk-test|debug token'; then
  fail "approved approval list must not expose raw goal or secret-like text"
fi

TRACE_LOG_2="${TMP}/trace-deny.jsonl"
HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --write-trace \
  --trace-log "$TRACE_LOG_2" \
  --approval-log "$APPROVAL_LOG" \
  "research current installer issue" >/dev/null

DENY_ID="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" | awk '/id: approval_dryrun_/ { print $3; exit }')"
[[ -n "$DENY_ID" ]] || fail "deny approval id should be parseable"

DENY_OUTPUT="$(MERLIN_APPROVAL_LOG="$APPROVAL_LOG" bash "${STACK_DIR}/cli/wizard" merlin approvals deny "$DENY_ID")"
require_output "$DENY_OUTPUT" '^status: denied$' "deny should append denied decision"
require_output "$DENY_OUTPUT" '^decision_recorded: true$' "deny should record decision"
require_output "$DENY_OUTPUT" '^execution_allowed: false$' "deny must not allow execution"

ALL_AFTER_DENY="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" --status all --limit 5)"
require_output "$ALL_AFTER_DENY" 'status: approved' "all list should retain approved decision"
require_output "$ALL_AFTER_DENY" 'status: denied' "all list should show denied decision"

echo "PASS: Merlin approval listing is read-only and redacted"
