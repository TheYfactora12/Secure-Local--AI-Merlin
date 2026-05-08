#!/usr/bin/env bash
# Offline smoke test for JSONL-to-Langfuse exporter dry-run.
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
{"timestamp":"2099-01-01T00:00:00+00:00","trace_id":"trace-export","user_goal_hash":"sha256:abc","route_id":"code","task_type":"code","staff_mode":"software_engineer","selected_agent":"openhands","required_profile":"coding","active_profile":"core","hardware_tier":"low","selected_model_alias":"qwen-coder","approval_required":true,"approval_request_id":"approval-export","approval_status":"required_pending","policy_decision":"require_approval","decision_reason":"code route requires gates","redaction_applied":true,"raw_input":"do not export me","api_key":"sk-test-should-not-print"}
JSONL

cat > "${TMP}/merlin-approvals.jsonl" <<'JSONL'
{"approval_request_id":"approval-export","timestamp":"2099-01-01T00:00:01+00:00","status":"required_pending","execution_allowed":false,"user_goal_hash":"sha256:abc","route_id":"code","task_type":"code","selected_agent":"openhands","approval_gates":["file_write","shell_command"],"policy_decision":"require_approval","decision_reason":"approval required","redaction_applied":true,"secret":"do-not-export"}
JSONL

cat > "${TMP}/merlin-outcomes.jsonl" <<'JSONL'
{"created_at":"2099-01-01T00:00:02+00:00","task_hash":"sha256:abc","route_id":"code","staff_mode":"software_engineer","agent_target":"openhands","confidence_at_routing":0.82,"outcome_status":"success","latency_ms":50,"hardware_tier":"low","user_feedback":"positive","skill_domain":"code","outcome_rating":"approved","prompt":"do-not-export"}
JSONL

cat > "${TMP}/merlin-benchmarks.jsonl" <<'JSONL'
{"generated_at":"2099-01-01T00:00:03+00:00","suite":"epbench","profile":"offline","summaries":[{"suite":"epbench","recall_at_k":1.0,"prompt":"do-not-export"}],"recall_at_k":1.0}
JSONL

cat > "${TMP}/merlin-memory-reads.jsonl" <<'JSONL'
{"memory_read_id":"mread-export","timestamp":"2099-01-01T00:00:04+00:00","mode":"search","memory_type":"preference","query_hash":"sha256:query","query_preview":"do-not-export","target_collection":"swarm_memory","adapter":"qdrant_local","embedding_model":"nomic-embed-text","policy_decision":"allow","result_status":"searched","decision_reason":"local read","result_count":2,"result_hashes":["sha256:result"],"redaction_applied":true,"qdrant_read":"search","embedding_calls":"local_ollama","vector_dimension_guard":"passed","cloud_calls":"none","external_network":"none","memory_writes":"none","execution_allowed":false}
JSONL

cat > "${TMP}/merlin-memory-writes.jsonl" <<'JSONL'
{"memory_write_id":"mem-export","timestamp":"2099-01-01T00:00:05+00:00","mode":"simulate","memory_type":"preference","memory_text_hash":"sha256:memory","memory_preview":"do-not-export","raw_memory_stored":false,"approval_request_id":"approval-export","approval_status":"approved","approval_route_id":"memory","target_collection":"swarm_memory","point_id":"point-export","adapter":"jsonl_simulator","embedding_model":"nomic-embed-text","policy_decision":"allow_simulation","result_status":"simulated","decision_reason":"approved simulation","redaction_applied":true,"qdrant_write":"none","embedding_calls":"none","vector_dimension_guard":"not_applicable","model_calls":"none","service_starts":"none","tool_execution":"none","cloud_calls":"none","external_network":"none","memory_writes":"simulated_jsonl_only","execution_allowed":false}
JSONL

OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-observability-export.sh" --dry-run --log-dir "$TMP")"

echo "$OUTPUT" | grep -q '^source_backend: jsonl$' || fail "exporter must use JSONL source"
echo "$OUTPUT" | grep -q '^mode: dry-run$' || fail "exporter must dry-run by default"
echo "$OUTPUT" | grep -q '^export_status: planned$' || fail "dry-run should plan only"
echo "$OUTPUT" | grep -q '^external_telemetry: false$' || fail "exporter must not use external telemetry"
echo "$OUTPUT" | grep -q '^raw_payload_exported: false$' || fail "exporter must not export raw payload"
echo "$OUTPUT" | grep -q '^route_records: 1$' || fail "route record count missing"
echo "$OUTPUT" | grep -q '^approval_records: 1$' || fail "approval record count missing"
echo "$OUTPUT" | grep -q '^outcome_records: 1$' || fail "outcome record count missing"
echo "$OUTPUT" | grep -q '^benchmark_records: 1$' || fail "benchmark record count missing"
echo "$OUTPUT" | grep -q '^memory_read_records: 1$' || fail "memory read record count missing"
echo "$OUTPUT" | grep -q '^memory_write_records: 1$' || fail "memory write record count missing"
echo "$OUTPUT" | grep -q '^planned_events: 6$' || fail "planned event count missing"
echo "$OUTPUT" | grep -q 'do-not-export' && fail "dry-run output must not print raw sensitive fixture values"

WIZARD_OUTPUT="$(bash "${ROOT_DIR}/cli/wizard" observability export --dry-run --log-dir "$TMP")"
echo "$WIZARD_OUTPUT" | grep -q '^mode: dry-run$' || fail "wizard observability export must call exporter"

bash "${ROOT_DIR}/scripts/merlin-observability-export.sh" --dry-run --langfuse-url "https://cloud.langfuse.com" --log-dir "$TMP" >/tmp/merlin-export-cloud.out 2>&1 \
  && fail "exporter should refuse hosted Langfuse URL"
grep -q 'refusing non-local Langfuse URL\|refusing hosted Langfuse URL' /tmp/merlin-export-cloud.out \
  || fail "hosted Langfuse refusal message missing"

LIVE_OUTPUT="$(bash "${ROOT_DIR}/scripts/merlin-observability-export.sh" --live --langfuse-url "http://localhost:9" --public-key pk-test --secret-key sk-test --log-dir "$TMP")"
echo "$LIVE_OUTPUT" | grep -q '^mode: live$' || fail "live mode should be explicit"
echo "$LIVE_OUTPUT" | grep -q '^export_status: skipped$' || fail "unreachable local Langfuse should skip gracefully"
echo "$LIVE_OUTPUT" | grep -q 'Langfuse unavailable' || fail "unreachable warning missing"

grep -q 'observability)' "${ROOT_DIR}/cli/wizard" || fail "wizard observability command missing"
grep -q 'merlin-observability-export.sh' "${ROOT_DIR}/cli/wizard" || fail "wizard observability must call exporter"

echo "PASS: wizard observability export dry-runs local JSONL safely"
