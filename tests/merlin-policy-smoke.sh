#!/usr/bin/env bash
# Static smoke test for Merlin policy and approval gates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
POLICY_FILE="${STACK_DIR}/config/merlin/policy.yaml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  grep -Eq "$pattern" "$file" || fail "$label"
}

[[ -f "$POLICY_FILE" ]] || fail "missing Merlin policy file"

require_grep 'magic_mode_enabled: false' "$POLICY_FILE" "Magic Mode should be disabled by default"
require_grep 'online_mode_enabled: false' "$POLICY_FILE" "online mode should be disabled by default"
require_grep 'cloud_fallback_enabled: false' "$POLICY_FILE" "cloud fallback should be disabled by default"
require_grep 'memory_auto_write: false' "$POLICY_FILE" "memory auto-write should be disabled by default"
require_grep 'shell_enabled_for_agents: false' "$POLICY_FILE" "agent shell should be disabled by default"
require_grep 'heavy_profiles_auto_start: false' "$POLICY_FILE" "heavy profiles should not auto-start"

for gate in shell_command file_read file_write file_delete git_operation external_network cloud_model_call api_key_use memory_write service_start service_stop model_download openhands_task; do
  require_grep "^  ${gate}:" "$POLICY_FILE" "missing approval gate: ${gate}"
done

for task in general search code automation memory; do
  require_grep "^  ${task}:" "$POLICY_FILE" "missing task routing class: ${task}"
done

critical_block="$(awk '/openhands_task:/,/^[^ ]/' "$POLICY_FILE")"
echo "$critical_block" | grep -q 'risk: critical' || fail "OpenHands task should be critical risk"
echo "$critical_block" | grep -q 'requires_approval: true' || fail "OpenHands task should require approval"

for gate in shell_command file_write file_delete git_operation external_network cloud_model_call api_key_use memory_write model_download; do
  block="$(awk "/${gate}:/,/^[^ ]/" "$POLICY_FILE")"
  echo "$block" | grep -q 'requires_approval: true' || fail "${gate} should require approval"
  echo "$block" | grep -Eq 'default: deny|default: deny_' || fail "${gate} should deny by default"
done

require_grep 'log_route_decisions: true' "$POLICY_FILE" "route decision audit missing"
require_grep 'log_policy_decisions: true' "$POLICY_FILE" "policy decision audit missing"
require_grep 'redact_secrets: true' "$POLICY_FILE" "secret redaction audit missing"
require_grep 'disable_magic_mode_by_default: true' "$POLICY_FILE" "low-memory Magic Mode default missing"
require_grep 'deny_parallel_agents_by_default: true' "$POLICY_FILE" "low-memory parallel agent default missing"

echo "PASS: Merlin policy approval gates are conservative"
