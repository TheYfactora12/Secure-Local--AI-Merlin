#!/usr/bin/env bash
# Static smoke test for the Merlin orchestration decision.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ORCH_FILE="${STACK_DIR}/config/merlin/orchestration.yaml"

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

[[ -f "$ORCH_FILE" ]] || fail "missing Merlin orchestration decision file"

require_grep '^decision: hybrid' "$ORCH_FILE" "orchestration decision should be hybrid"
require_grep 'implementation_target: lightweight_local_controller' "$ORCH_FILE" "control plane should be lightweight/local"

for service in litellm ollama open-webui qdrant swarm-dashboard; do
  require_grep "${service}" "$ORCH_FILE" "missing core service: ${service}"
done

for responsibility in evaluate_policy select_route produce_route_decision_trace request_user_approval call_litellm_for_model_requests call_qdrant_for_memory_after_approval; do
  require_grep "- ${responsibility}" "$ORCH_FILE" "missing control-plane responsibility: ${responsibility}"
done

for forbidden in replace_install_sh replace_open_webui replace_litellm replace_qdrant make_cloud_calls_by_default auto_start_heavy_profiles; do
  require_grep "- ${forbidden}" "$ORCH_FILE" "missing control-plane non-action: ${forbidden}"
done

search_block="$(awk '/^  search:/,/^  automation:/' "$ORCH_FILE")"
echo "$search_block" | grep -q 'starts_by_default: false' || fail "search should not start by default"
echo "$search_block" | grep -q 'requires_approval: true' || fail "search should require approval"

automation_block="$(awk '/^  automation:/,/^  coding:/' "$ORCH_FILE")"
echo "$automation_block" | grep -q 'starts_by_default: false' || fail "automation should not start by default"
echo "$automation_block" | grep -q 'requires_approval: true' || fail "automation should require approval"

coding_block="$(awk '/^  coding:/,/^  mcp:/' "$ORCH_FILE")"
echo "$coding_block" | grep -q 'starts_by_default: false' || fail "coding should not start by default"
echo "$coding_block" | grep -q 'requires_approval: true' || fail "coding should require approval"
echo "$coding_block" | grep -q 'risk: critical' || fail "coding should stay critical risk"

require_grep 'langgraph:' "$ORCH_FILE" "LangGraph framework position missing"
require_grep 'status: optional_future' "$ORCH_FILE" "heavy frameworks should be optional future"
require_grep 'n8n:' "$ORCH_FILE" "n8n framework position missing"
require_grep 'status: optional_workflow_engine' "$ORCH_FILE" "n8n should be optional workflow engine"
require_grep 'mandatory_langchain_or_langgraph_dependency' "$ORCH_FILE" "mandatory graph framework should be v1 non-goal"
require_grep 'mandatory_n8n_for_basic_chat' "$ORCH_FILE" "mandatory n8n should be v1 non-goal"
require_grep 'autonomous_openhands_without_approval' "$ORCH_FILE" "autonomous OpenHands should be v1 non-goal"

echo "PASS: Merlin orchestration decision is hybrid and conservative"
