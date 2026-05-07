#!/usr/bin/env bash
# Offline smoke test for wizard trace / local JSONL trace viewer.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cat > "${TMP}/merlin-route-decisions.jsonl" <<'JSONL'
{"timestamp":"2099-01-01T00:00:00+00:00","trace_id":"trace-abc","user_goal_hash":"sha256:abc","route_id":"code","task_type":"code","staff_mode":"software_engineer","selected_agent":"openhands","required_profile":"coding","active_profile":"core","hardware_tier":"low","selected_model_alias":"qwen-coder","approval_required":true,"approval_request_id":"approval-abc","approval_status":"required_pending","policy_decision":"require_approval","decision_reason":"code route requires gates","redaction_applied":true}
{"timestamp":"2099-01-01T00:01:00+00:00","trace_id":"trace-other","user_goal_hash":"sha256:other","route_id":"general","task_type":"general","approval_required":false,"redaction_applied":true}
JSONL

cat > "${TMP}/merlin-approvals.jsonl" <<'JSONL'
{"approval_request_id":"approval-abc","timestamp":"2099-01-01T00:00:01+00:00","status":"required_pending","execution_allowed":false,"user_goal_hash":"sha256:abc","route_id":"code","task_type":"code","selected_agent":"openhands","approval_gates":["file_write","shell_command"],"policy_decision":"require_approval","decision_reason":"approval required","redaction_applied":true}
JSONL

cat > "${TMP}/merlin-outcomes.jsonl" <<'JSONL'
{"created_at":"2099-01-01T00:00:02+00:00","task_hash":"sha256:abc","route_id":"code","staff_mode":"software_engineer","agent_target":"openhands","confidence_at_routing":0.82,"outcome_status":"rejected","latency_ms":50,"hardware_tier":"low","user_feedback":"negative","skill_domain":"code","outcome_rating":"rejected"}
JSONL

OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-trace-view.sh" trace-abc --log-dir "$TMP")"

echo "$OUTPUT" | grep -q '^backend: jsonl$' || fail "trace viewer must use jsonl backend"
echo "$OUTPUT" | grep -q '^langfuse_enabled: false$' || fail "trace viewer must not require Langfuse"
echo "$OUTPUT" | grep -q '^external_telemetry: false$' || fail "trace viewer must not use external telemetry"
echo "$OUTPUT" | grep -q '^trace_matches: 1$' || fail "trace viewer should find one trace"
echo "$OUTPUT" | grep -q '^approval_matches: 0$' || fail "trace id should not match approval directly"
echo "$OUTPUT" | grep -q '^outcome_matches: 0$' || fail "trace id should not match outcome directly"
echo "$OUTPUT" | grep -q 'route_id: code' || fail "trace details missing route"
echo "$OUTPUT" | grep -q 'user_goal_hash: sha256:abc' || fail "trace details missing hash"
echo "$OUTPUT" | grep -q 'redaction_applied: True' || fail "trace should show redaction flag"

APPROVAL_OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-trace-view.sh" approval-abc --log-dir "$TMP")"
echo "$APPROVAL_OUTPUT" | grep -q '^approval_matches: 1$' || fail "approval lookup should find approval"
echo "$APPROVAL_OUTPUT" | grep -q 'execution_allowed: False' || fail "approval should remain non-executing"
echo "$APPROVAL_OUTPUT" | grep -q 'approval_gates: \["file_write","shell_command"\]' || fail "approval gates missing"

HASH_OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-trace-view.sh" sha256:abc --log-dir "$TMP")"
echo "$HASH_OUTPUT" | grep -q '^trace_matches: 1$' || fail "hash lookup should find trace"
echo "$HASH_OUTPUT" | grep -q '^approval_matches: 1$' || fail "hash lookup should find approval"
echo "$HASH_OUTPUT" | grep -q '^outcome_matches: 1$' || fail "hash lookup should find outcome"
echo "$HASH_OUTPUT" | grep -q 'outcome_status: rejected' || fail "outcome detail missing"

MISSING_OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-trace-view.sh" missing-id --log-dir "$TMP")"
echo "$MISSING_OUTPUT" | grep -q '^trace_matches: 0$' || fail "missing lookup should have zero traces"
echo "$MISSING_OUTPUT" | grep -q 'No matching local JSONL records found.' || fail "missing lookup should be explicit"

WIZARD_OUTPUT="$(bash "${ROOT_DIR}/cli/wizard" trace trace-abc --log-dir "$TMP")"
echo "$WIZARD_OUTPUT" | grep -q '^backend: jsonl$' || fail "wizard trace must call JSONL trace viewer"

grep -q 'trace)' "${ROOT_DIR}/cli/wizard" || fail "wizard trace command missing"
grep -q 'merlin-trace-view.sh' "${ROOT_DIR}/cli/wizard" || fail "wizard trace must call scripts/merlin-trace-view.sh"

echo "PASS: wizard trace reads local JSONL trace records"
