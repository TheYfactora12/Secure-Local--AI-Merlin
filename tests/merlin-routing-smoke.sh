#!/usr/bin/env bash
# Static smoke test for Merlin Magic Mode routing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTES_FILE="${STACK_DIR}/configs/merlin/routes.yaml"
POLICY_FILE="${STACK_DIR}/configs/merlin/policy.yaml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  grep -Eq -- "$pattern" "$file" || fail "$label"
}

[[ -f "$ROUTES_FILE" ]] || fail "missing Merlin routes file"

require_grep 'backend_preference: local' "$ROUTES_FILE" "routes should prefer local backend"
require_grep 'cloud_allowed: false' "$ROUTES_FILE" "routes should disable cloud by default"
require_grep 'route_logging_required: true' "$ROUTES_FILE" "route logging should be required"
require_grep 'approval_summary_required: true' "$ROUTES_FILE" "approval summary should be required"

for route in general search code automation memory; do
  require_grep "^  ${route}:" "$ROUTES_FILE" "missing route: ${route}"
done

require_grep 'required_profile: core' "$ROUTES_FILE" "core route missing"
require_grep 'required_profile: search' "$ROUTES_FILE" "search route missing required profile"
require_grep 'required_profile: coding' "$ROUTES_FILE" "code route missing required profile"
require_grep 'required_profile: automation' "$ROUTES_FILE" "automation route missing required profile"

search_block="$(awk '/^  search:/,/^  code:/' "$ROUTES_FILE")"
echo "$search_block" | grep -q 'service_start' || fail "search route should require service_start approval"
echo "$search_block" | grep -q 'external_network' || fail "search route should require external_network approval"

code_block="$(awk '/^  code:/,/^  automation:/' "$ROUTES_FILE")"
echo "$code_block" | grep -q 'default_risk: critical' || fail "code route should be critical risk"
echo "$code_block" | grep -q 'openhands_task' || fail "code route should gate OpenHands tasks"
echo "$code_block" | grep -q 'shell_command' || fail "code route should gate shell commands"
echo "$code_block" | grep -q 'file_write' || fail "code route should gate file writes"
echo "$code_block" | grep -q 'git_operation' || fail "code route should gate git operations"

automation_block="$(awk '/^  automation:/,/^  memory:/' "$ROUTES_FILE")"
echo "$automation_block" | grep -q 'api_key_use' || fail "automation route should gate API key use"
echo "$automation_block" | grep -q 'memory_write' || fail "automation route should gate memory writes"

memory_block="$(awk '/^  memory:/,/^trace:/' "$ROUTES_FILE")"
echo "$memory_block" | grep -q 'memory_write' || fail "memory route should gate memory writes"
echo "$memory_block" | grep -q 'file_delete' || fail "memory route should gate deletion"

for field in route_id task_type selected_agent required_profile selected_model_alias privacy_mode online_mode approval_gates decision_reason; do
  require_grep "- ${field}" "$ROUTES_FILE" "missing route trace field: ${field}"
done

require_grep 'never_auto_start: true' "$ROUTES_FILE" "missing never-auto-start fallback"
require_grep 'disable_parallel_agents: true' "$ROUTES_FILE" "missing low-memory parallel agent fallback"
require_grep 'default: deny' "$ROUTES_FILE" "cloud fallback should deny by default"

for gate in service_start external_network file_write shell_command git_operation openhands_task api_key_use memory_write file_delete; do
  require_grep "^  ${gate}:" "$POLICY_FILE" "route references missing policy gate: ${gate}"
done

echo "PASS: Merlin task routing is local-first and approval-gated"
