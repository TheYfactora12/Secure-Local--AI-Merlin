#!/usr/bin/env bash
# Smoke test the approved memory-write simulator.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TRACE_LOG="${TMP}/merlin-route-decisions.jsonl"
APPROVAL_LOG="${TMP}/merlin-approvals.jsonl"
MEMORY_LOG="${TMP}/merlin-memory-writes.jsonl"
MEMORY_TEXT="I prefer local-only models for private work"

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

PLAN_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-memory-write.sh" plan \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG")"

require_output "$PLAN_OUTPUT" '^Merlin memory write boundary$' "memory boundary heading missing"
require_output "$PLAN_OUTPUT" '^mode: plan$' "plan mode missing"
require_output "$PLAN_OUTPUT" '^memory_type: preference$' "memory type missing"
require_output "$PLAN_OUTPUT" '^approval_required: true$' "memory writes should require approval"
require_output "$PLAN_OUTPUT" '^raw_memory_stored: false$' "raw memory should not be stored in plan"
require_output "$PLAN_OUTPUT" '^qdrant_write: none$' "plan must not write Qdrant"
require_output "$PLAN_OUTPUT" '^embedding_calls: none$' "plan must not call embeddings"
require_output "$PLAN_OUTPUT" '^memory_writes: none$' "plan must not write memory"
[[ ! -f "$MEMORY_LOG" ]] || fail "plan mode must not write memory log"

if bash "${STACK_DIR}/scripts/merlin-memory-write.sh" simulate \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-id missing \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG" >"${TMP}/denied.out" 2>&1; then
  fail "simulate without approved approval should fail"
fi
DENIED_OUTPUT="$(cat "${TMP}/denied.out")"
require_output "$DENIED_OUTPUT" '^policy_decision: deny$' "missing approval should deny"
require_output "$DENIED_OUTPUT" '^simulation_allowed: false$' "missing approval should not simulate"
[[ ! -f "$MEMORY_LOG" ]] || fail "denied simulation must not write memory log"

bash "${STACK_DIR}/scripts/merlin-dry-run.sh" \
  --task-type memory \
  --write-trace \
  --trace-log "$TRACE_LOG" \
  --approval-log "$APPROVAL_LOG" \
  "remember my local-only model preference" >/dev/null

APPROVAL_ID="$(bash "${STACK_DIR}/scripts/merlin-approvals.sh" list --approval-log "$APPROVAL_LOG" | awk '/id: approval_dryrun_/ { print $3; exit }')"
[[ -n "$APPROVAL_ID" ]] || fail "memory dry-run should create approval id"
bash "${STACK_DIR}/scripts/merlin-approvals.sh" approve "$APPROVAL_ID" --approval-log "$APPROVAL_LOG" >/dev/null

SIM_OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-memory-write.sh" simulate \
  --memory-type preference \
  --text "$MEMORY_TEXT" \
  --approval-id "$APPROVAL_ID" \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG")"

require_output "$SIM_OUTPUT" '^mode: simulate$' "simulate mode missing"
require_output "$SIM_OUTPUT" '^approval_status: approved$' "approved status should be detected"
require_output "$SIM_OUTPUT" '^approval_has_memory_write_gate: true$' "memory_write gate should be required"
require_output "$SIM_OUTPUT" '^policy_decision: allow_simulation$' "approved memory write should allow simulation"
require_output "$SIM_OUTPUT" '^simulation_allowed: true$' "simulation should be allowed"
require_output "$SIM_OUTPUT" '^memory_writes: simulated_jsonl_only$' "simulation should only write JSONL"
require_output "$SIM_OUTPUT" '^qdrant_write: none$' "simulation must not write Qdrant"
[[ -f "$MEMORY_LOG" ]] || fail "approved simulation should write memory audit log"
grep -q '"adapter":"jsonl_simulator"' "$MEMORY_LOG" || fail "memory log should use simulator adapter"
grep -q '"target_collection":"merlin_user"' "$MEMORY_LOG" || fail "preference should target merlin_user"
grep -q '"raw_memory_stored":false' "$MEMORY_LOG" || fail "memory log should not store raw text flag"
grep -q '"qdrant_write":"none"' "$MEMORY_LOG" || fail "memory log must not claim Qdrant write"
if grep -q "$MEMORY_TEXT" "$MEMORY_LOG"; then
  fail "memory log must not store raw memory text"
fi

WIZARD_OUTPUT="$(bash "${STACK_DIR}/cli/wizard" merlin memory plan \
  --memory-type tool_result \
  --text "Tool found local-only result" \
  --approval-log "$APPROVAL_LOG" \
  --memory-log "$MEMORY_LOG")"
require_output "$WIZARD_OUTPUT" '^target_collection: merlin_tools$' "tool_result should target merlin_tools"

echo "PASS: Merlin memory-write simulator is approval-gated"
