#!/usr/bin/env bash
# Static smoke test for Merlin route-decision trace schema.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TRACE_FILE="${STACK_DIR}/configs/merlin/trace.yaml"
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

[[ -f "$TRACE_FILE" ]] || fail "missing Merlin trace schema"

require_grep 'default_sink: local_file' "$TRACE_FILE" "trace should default to local file"
require_grep 'logs/merlin-route-decisions\.jsonl' "$TRACE_FILE" "trace log path missing"
require_grep 'future_memory_collection: merlin_audit' "$TRACE_FILE" "future audit collection missing"
require_grep 'append_only: true' "$TRACE_FILE" "trace storage should be append-only"
require_grep 'redact_before_write: true' "$TRACE_FILE" "trace must redact before write"

for field in trace_id timestamp user_goal_hash route_id task_type selected_agent required_profile active_profile hardware_tier privacy_mode online_mode cloud_allowed selected_model_alias provider approval_gates approval_status policy_decision decision_reason redaction_applied; do
  require_grep "- ${field}" "$TRACE_FILE" "missing trace required field: ${field}"
done

for status in not_required required_pending approved denied expired; do
  require_grep "- ${status}" "$TRACE_FILE" "missing approval status value: ${status}"
done

for decision in allow deny require_approval ask_to_start_profile ask_to_enable_online_mode ask_to_download_model; do
  require_grep "- ${decision}" "$TRACE_FILE" "missing policy decision value: ${decision}"
done

require_grep 'enabled: true' "$TRACE_FILE" "trace redaction should be enabled"
require_grep 'replacement: "\[REDACTED\]"' "$TRACE_FILE" "trace redaction replacement missing"
for secret_name in api_key token password secret authorization cookie private_key; do
  require_grep "- ${secret_name}" "$TRACE_FILE" "missing redacted field name: ${secret_name}"
done

require_grep 'Never log raw API keys' "$TRACE_FILE" "no-secret guarantee for API keys missing"
require_grep 'Never log full user documents' "$TRACE_FILE" "no-secret guarantee for documents missing"
require_grep 'Store user goal hash' "$TRACE_FILE" "user goal hash requirement missing"
require_grep 'redaction_applied: true' "$TRACE_FILE" "example should show redaction applied"
require_grep 'cloud_allowed: false' "$TRACE_FILE" "example should be cloud-disabled"
require_grep 'approval_status: "required_pending"' "$TRACE_FILE" "example should show pending approval"

for route_field in route_id task_type selected_agent required_profile selected_model_alias privacy_mode online_mode approval_gates decision_reason; do
  require_grep "- ${route_field}" "$ROUTES_FILE" "routes trace section missing field also required by trace schema: ${route_field}"
done

require_grep 'log_route_decisions: true' "$POLICY_FILE" "policy should require route decision logging"
require_grep 'redact_secrets: true' "$POLICY_FILE" "policy should require secret redaction"

echo "PASS: Merlin trace schema is auditable and redacted"
