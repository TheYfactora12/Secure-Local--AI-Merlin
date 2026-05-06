#!/usr/bin/env bash
# Smoke-test Merlin read-only dry-run route decisions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

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

GENERAL_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" "plan a local install")"
require_output "$GENERAL_OUTPUT" '^route_id: general$' "general task should route to general"
require_output "$GENERAL_OUTPUT" '^required_profile: core$' "general task should require core"
require_output "$GENERAL_OUTPUT" '^policy_decision: allow$' "general route should be allowed in dry-run"
require_output "$GENERAL_OUTPUT" '^side_effects: none$' "dry-run should have no side effects"
require_output "$GENERAL_OUTPUT" '^model_calls: none$' "dry-run should not call models"
require_output "$GENERAL_OUTPUT" '^memory_writes: none$' "dry-run should not write memory"
require_output "$GENERAL_OUTPUT" '^service_starts: none$' "dry-run should not start services"
require_output "$GENERAL_OUTPUT" '^tool_execution: none$' "dry-run should not execute tools"
require_output "$GENERAL_OUTPUT" '^cloud_allowed: false$' "dry-run should keep cloud disabled"

CODE_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/scripts/merlin-dry-run.sh" "debug the installer code")"
require_output "$CODE_OUTPUT" '^route_id: code$' "code task should route to code"
require_output "$CODE_OUTPUT" '^selected_agent: coding$' "code task should select coding agent"
require_output "$CODE_OUTPUT" '^required_profile: coding$' "code task should require coding profile"
require_output "$CODE_OUTPUT" '^approval_status: required_pending$' "code task should require pending approval"
require_output "$CODE_OUTPUT" '^policy_decision: ask_to_start_profile$' "code route should not auto-start optional profile"
require_output "$CODE_OUTPUT" 'shell_command' "code route should include shell approval gate"
require_output "$CODE_OUTPUT" 'openhands_task' "code route should include OpenHands approval gate"

FULL_CODE_OUTPUT="$(HOME_AI_PROFILE=full bash "${STACK_DIR}/scripts/merlin-dry-run.sh" --task-type code "review repo")"
require_output "$FULL_CODE_OUTPUT" '^route_id: code$' "forced code task should route to code"
require_output "$FULL_CODE_OUTPUT" '^active_profile: full$' "forced code route should report active profile"
require_output "$FULL_CODE_OUTPUT" '^policy_decision: require_approval$' "coding route in full profile still needs approval"
require_output "$FULL_CODE_OUTPUT" '^approval_status: required_pending$' "coding route should remain approval-gated"

SEARCH_OUTPUT="$(HOME_AI_PROFILE=developer bash "${STACK_DIR}/scripts/merlin-dry-run.sh" "research current local AI tools")"
require_output "$SEARCH_OUTPUT" '^route_id: search$' "search task should route to search"
require_output "$SEARCH_OUTPUT" '^active_profile: developer$' "search route should report developer profile"
require_output "$SEARCH_OUTPUT" '^policy_decision: require_approval$' "search route should require network/service approval"
require_output "$SEARCH_OUTPUT" 'external_network' "search route should include external network approval"

WIZARD_OUTPUT="$(HOME_AI_PROFILE=core bash "${STACK_DIR}/cli/wizard" merlin dry-run "remember this approved note")"
require_output "$WIZARD_OUTPUT" '^route_id: memory$' "wizard merlin dry-run should call dry-run script"
require_output "$WIZARD_OUTPUT" '^policy_decision: require_approval$' "memory route should require approval"

echo "PASS: Merlin dry-run control plane is read-only and approval-gated"
