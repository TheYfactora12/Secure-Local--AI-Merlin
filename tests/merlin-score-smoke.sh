#!/usr/bin/env bash
# Offline smoke test for wizard score / JSONL observability baseline.
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

cat > "${TMP}/merlin-outcomes.jsonl" <<'JSONL'
{"created_at":"2099-01-01T00:00:00+00:00","task_hash":"hash1","route_id":"general","staff_mode":"operator","agent_target":"litellm","confidence_at_routing":0.9,"outcome_status":"success","latency_ms":100,"keyword_matches":["explain"],"hardware_tier":"low","user_feedback":"none"}
{"created_at":"2099-01-01T00:00:01+00:00","task_hash":"hash2","route_id":"code","staff_mode":"software_engineer","agent_target":"openhands","confidence_at_routing":0.4,"outcome_status":"success","latency_ms":200,"keyword_matches":["code"],"hardware_tier":"low","user_feedback":"positive"}
{"created_at":"2099-01-01T00:00:02+00:00","task_hash":"hash3","route_id":"automation","staff_mode":"operator","agent_target":"n8n","confidence_at_routing":0.8,"outcome_status":"failure","latency_ms":300,"keyword_matches":["workflow"],"hardware_tier":"low","user_feedback":"negative"}
JSONL

cat > "${TMP}/merlin-route-decisions.jsonl" <<'JSONL'
{"timestamp":"2099-01-01T00:00:00+00:00","trace_id":"t1","approval_required":false,"user_goal_hash":"sha256:a","redaction_applied":true}
{"timestamp":"2099-01-01T00:00:01+00:00","trace_id":"t2","approval_required":true,"user_goal_hash":"sha256:b","redaction_applied":true}
JSONL

cat > "${TMP}/merlin-benchmarks.jsonl" <<'JSONL'
{"generated_at":"2099-01-01T00:00:00+00:00","summaries":[{"suite":"epbench","recall_at_k":1.0},{"suite":"memoryarena","recall_at_k":0.5}]}
JSONL

OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-score.sh" --days 7 --log-dir "$TMP")"

echo "$OUTPUT" | grep -q '^backend: jsonl$' || fail "score must use jsonl backend"
echo "$OUTPUT" | grep -q '^langfuse_enabled: false$' || fail "score must not require Langfuse"
echo "$OUTPUT" | grep -q '^external_telemetry: false$' || fail "score must not use external telemetry"
echo "$OUTPUT" | grep -q '^outcomes_read: 3$' || fail "score did not read expected outcomes"
echo "$OUTPUT" | grep -q '^route_traces_read: 2$' || fail "score did not read expected traces"
echo "$OUTPUT" | grep -q '^benchmark_records_read: 1$' || fail "score did not read expected benchmark record"
echo "$OUTPUT" | grep -q '^success_rate: 0.667$' || fail "unexpected success rate"
echo "$OUTPUT" | grep -q '^benchmark_recall: 0.750$' || fail "unexpected benchmark recall"
echo "$OUTPUT" | grep -q '^low_confidence_successes: 1$' || fail "low-confidence success count missing"
echo "$OUTPUT" | grep -q '^approval_required_traces: 1$' || fail "approval-required trace count missing"

WIZARD_OUTPUT="$(bash "${ROOT_DIR}/cli/wizard" score --days 7 --log-dir "$TMP")"
echo "$WIZARD_OUTPUT" | grep -q '^backend: jsonl$' || fail "wizard score must call JSONL scorer"

grep -q 'score)' "${ROOT_DIR}/cli/wizard" || fail "wizard score command missing"
grep -q 'merlin-score.sh' "${ROOT_DIR}/cli/wizard" || fail "wizard score must call scripts/merlin-score.sh"

echo "PASS: wizard score reads local JSONL observability baseline"
