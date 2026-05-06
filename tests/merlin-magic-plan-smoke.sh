#!/usr/bin/env bash
# Smoke test the plan-only Magic Mode step runner.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PLAN_LOG="${TMP}/merlin-magic-plans.jsonl"
TRACE_LOG="${TMP}/merlin-route-decisions.jsonl"
APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"

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

PLAN_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-magic-plan.sh" \
  --write-plan \
  --plan-log "$PLAN_LOG" \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  --task-type code \
  "debug install.sh and push fixes")"

require_output "$PLAN_OUTPUT" '^Merlin Magic Mode plan$' "plan heading missing"
require_output "$PLAN_OUTPUT" '^route_id: code$' "code route expected"
require_output "$PLAN_OUTPUT" '^approval_required: true$' "code route should require approval"
require_output "$PLAN_OUTPUT" '^plan_status: blocked_pending_approval$' "risky route should be blocked"
require_output "$PLAN_OUTPUT" '^execution_allowed: false$' "Magic plan must not allow execution"
require_output "$PLAN_OUTPUT" '^model_calls: none$' "plan must not call models"
require_output "$PLAN_OUTPUT" '^memory_writes: none$' "plan must not write memory"
require_output "$PLAN_OUTPUT" '^service_starts: none$' "plan must not start services"
require_output "$PLAN_OUTPUT" '^tool_execution: none$' "plan must not execute tools"
require_output "$PLAN_OUTPUT" '^cloud_calls: none$' "plan must not call cloud"
require_output "$PLAN_OUTPUT" '^external_network: none$' "plan must not use external network"
require_output "$PLAN_OUTPUT" 'Request approval before file, shell, git, or OpenHands action' "code approval step missing"
[[ -f "$PLAN_LOG" ]] || fail "plan log should be written"
[[ -f "$TRACE_LOG" ]] || fail "route trace should be written when --write-plan is used"
[[ -f "$APPROVAL_LOG" ]] || fail "approval log should be written for risky route"

grep -q '"route_id":"code"' "$PLAN_LOG" || fail "plan log missing route id"
grep -q '"execution_allowed":false' "$PLAN_LOG" || fail "plan log must deny execution"
grep -q '"raw_goal_logged":false' "$PLAN_LOG" || fail "plan log must not store raw goal"
grep -q '"tool_execution":"none"' "$PLAN_LOG" || fail "plan log must not execute tools"
if grep -q 'debug install.sh and push fixes' "$PLAN_LOG"; then
  fail "plan log must not contain raw user goal"
fi

GENERAL_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-magic-plan.sh" \
  --plan-log "$PLAN_LOG" \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  --task-type general \
  "explain this local AI stack")"

require_output "$GENERAL_OUTPUT" '^route_id: general$' "general route expected"
require_output "$GENERAL_OUTPUT" '^approval_required: false$' "general route should not require approval"
require_output "$GENERAL_OUTPUT" '^plan_status: ready_plan_only$' "general route should be ready but plan-only"
require_output "$GENERAL_OUTPUT" '^plan_written: false$' "plan should not write unless requested"

WIZARD_OUTPUT="$(bash "${STACK_DIR}/cli/wizard" merlin magic plan \
  --plan-log "$PLAN_LOG" \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  --task-type memory \
  "remember my preference")"
require_output "$WIZARD_OUTPUT" '^Merlin Magic Mode plan$' "wizard should route magic plan"
require_output "$WIZARD_OUTPUT" '^route_id: memory$' "wizard memory route expected"
require_output "$WIZARD_OUTPUT" '^execution_allowed: false$' "wizard magic plan must remain plan-only"

echo "PASS: Merlin Magic Mode plan runner is plan-only and auditable"
