#!/usr/bin/env bash
# Smoke test the v0 Merlin policy-gated execution boundary.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"
TRACE_LOG="${TMP}/merlin-route-decisions.jsonl"
EXECUTION_LOG="${TMP}/merlin-executions.jsonl"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_output() {
  local output="$1"
  local pattern="$2"
  local message="$3"
  echo "$output" | grep -qE "$pattern" || fail "$message"
}

PLAN_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-execute.sh" plan \
  --action merlin_status \
  --approval-log "$APPROVAL_LOG" \
  --execution-log "$EXECUTION_LOG")"

require_output "$PLAN_OUTPUT" '^mode: plan$' "plan mode missing"
require_output "$PLAN_OUTPUT" '^action: merlin_status$' "merlin_status action missing"
require_output "$PLAN_OUTPUT" '^policy_decision: allow$' "read-only status should be allowed"
require_output "$PLAN_OUTPUT" '^execution_allowed: true$' "read-only status should be executable"
require_output "$PLAN_OUTPUT" '^execution_performed: false$' "plan must not execute"
[[ ! -f "$EXECUTION_LOG" ]] || fail "plan mode must not write execution log"

EXECUTE_OUTPUT="$(MERLIN_HARDWARE_TIER=low HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-execute.sh" execute \
  --action merlin_status \
  --approval-log "$APPROVAL_LOG" \
  --execution-log "$EXECUTION_LOG")"

require_output "$EXECUTE_OUTPUT" '^mode: execute$' "execute mode missing"
require_output "$EXECUTE_OUTPUT" '^execution_performed: true$' "safe action should execute"
require_output "$EXECUTE_OUTPUT" '^result_status: completed$' "safe action should complete"
require_output "$EXECUTE_OUTPUT" '^side_effects: audit_log_only$' "safe action should only write audit log"
require_output "$EXECUTE_OUTPUT" '^Merlin status$' "execute should print read-only Merlin status"
[[ -f "$EXECUTION_LOG" ]] || fail "execute should write audit log"
grep -q '"action":"merlin_status"' "$EXECUTION_LOG" || fail "execution log missing action"
grep -q '"execution_allowed":true' "$EXECUTION_LOG" || fail "execution log should allow merlin_status"
grep -q '"tool_execution":"none"' "$EXECUTION_LOG" || fail "execution log must not report tool execution"

if bash "${STACK_DIR}/scripts/merlin-execute.sh" execute \
  --action shell_command \
  --approval-log "$APPROVAL_LOG" \
  --execution-log "$EXECUTION_LOG" >"${TMP}/merlin-execute-denied.out" 2>&1; then
  fail "shell_command should be denied"
fi
DENIED_OUTPUT="$(cat "${TMP}/merlin-execute-denied.out")"
require_output "$DENIED_OUTPUT" '^policy_decision: deny$' "shell command should be denied"
require_output "$DENIED_OUTPUT" '^execution_allowed: false$' "denied action must not be executable"
require_output "$DENIED_OUTPUT" '^execution_performed: false$' "denied action must not execute"
grep -q '"action":"shell_command"' "$EXECUTION_LOG" || fail "denied execution should be audited"
grep -q '"result_status":"denied"' "$EXECUTION_LOG" || fail "denial should be logged"

bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --task-type code \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "debug a repo script" >/dev/null

APPROVAL_ID="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" | awk '/id: approval_dryrun_/ { print $3; exit }')"
[[ -n "$APPROVAL_ID" ]] || fail "approval id should be created by risky dry-run"
bash "${STACK_DIR}/scripts/merlin-approvals.sh" approve "$APPROVAL_ID" --approval-log "$APPROVAL_LOG" >/dev/null

if bash "${STACK_DIR}/scripts/merlin-execute.sh" execute \
  --action shell_command \
  --approval-id "$APPROVAL_ID" \
  --approval-log "$APPROVAL_LOG" \
  --execution-log "$EXECUTION_LOG" >"${TMP}/merlin-execute-approved-denied.out" 2>&1; then
  fail "approved shell_command should still be denied in v0"
fi
APPROVED_DENIED_OUTPUT="$(cat "${TMP}/merlin-execute-approved-denied.out")"
require_output "$APPROVED_DENIED_OUTPUT" '^approval_status: approved$' "approval status should be checked"
require_output "$APPROVED_DENIED_OUTPUT" '^policy_decision: deny$' "approval alone must not bypass v0 action block"
require_output "$APPROVED_DENIED_OUTPUT" 'future scoped adapter' "denial reason should explain adapter boundary"

WIZARD_OUTPUT="$(bash "${STACK_DIR}/cli/wizard" merlin execute plan \
  --action merlin_status \
  --approval-log "$APPROVAL_LOG" \
  --execution-log "$EXECUTION_LOG")"
require_output "$WIZARD_OUTPUT" '^Merlin execution boundary$' "wizard should route merlin execute"

echo "PASS: Merlin v0 execution boundary is policy-gated"
