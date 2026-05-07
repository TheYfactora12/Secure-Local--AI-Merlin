#!/usr/bin/env bash
# Static policy validation for the n8n AI Router starter workflow.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="${ROOT_DIR}/n8n-workflows/ai-router-starter.json"
WIZARD_FILE="${ROOT_DIR}/cli/wizard"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required for workflow validation"

[[ -f "$WORKFLOW_FILE" ]] || fail "ai-router-starter.json missing"
jq empty "$WORKFLOW_FILE" || fail "ai-router-starter.json is invalid JSON"

[[ "$(jq -r '.active' "$WORKFLOW_FILE")" == "false" ]] \
  || fail "AI router starter must ship inactive"

cloud_url_count="$(
  jq '
    [
      .nodes[]
      | select(.type == "n8n-nodes-base.httpRequest")
      | (.parameters.url // "")
      | select(test("api\\.openai\\.com|api\\.perplexity\\.ai|api\\.anthropic\\.com|generativelanguage\\.googleapis\\.com"))
    ]
    | length
  ' "$WORKFLOW_FILE"
)"
[[ "$cloud_url_count" == "0" ]] \
  || fail "AI router starter must not include executable cloud provider HTTP nodes"

ollama_url_count="$(
  jq '
    [
      .nodes[]
      | select(.type == "n8n-nodes-base.httpRequest")
      | (.parameters.url // "")
      | select(test("host\\.docker\\.internal:11434|ollama:11434|localhost:11434"))
    ]
    | length
  ' "$WORKFLOW_FILE"
)"
(( ollama_url_count >= 1 )) || fail "AI router starter must retain a local Ollama route"

for gate in cloud_model_call external_network api_key_use; do
  jq -e --arg gate "$gate" '
    tostring | contains($gate)
  ' "$WORKFLOW_FILE" >/dev/null \
    || fail "AI router starter missing approval gate: $gate"
done

jq -e '
  .nodes[]
  | select(.name == "Cloud Approval Blocked")
  | tostring
  | contains("approval_required")
' "$WORKFLOW_FILE" >/dev/null \
  || fail "AI router starter must block cloud routes with approval_required metadata"

jq -e '
  .nodes[]
  | select(.name == "Policy Gate + Route Metadata")
  | .parameters.jsCode
  | contains("local_first_no_auto_cloud_escalation")
' "$WORKFLOW_FILE" >/dev/null \
  || fail "AI router starter missing local-first policy contract"

if jq -r '.. | strings?' "$WORKFLOW_FILE" | grep -Eiq '(sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password=|api_key=|token=)'; then
  fail "AI router starter contains a secret-like value"
fi

grep -q 'n8n-model-router-policy-smoke.sh' "$WIZARD_FILE" \
  || fail "wizard test-workflows must run n8n model-router policy smoke test"

echo "PASS: n8n AI Router starter is local-first and approval-gated"
