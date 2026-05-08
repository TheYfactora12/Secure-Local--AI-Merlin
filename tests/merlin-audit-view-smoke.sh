#!/usr/bin/env bash
# Smoke-test the local redacted Merlin audit viewer.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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

cat > "${TMP}/merlin-route-decisions.jsonl" <<'JSONL'
{"trace_id":"dryrun_test","timestamp":"2026-05-08T01:00:00Z","user_goal_hash":"sha256:routehash","route_id":"code","task_type":"code","approval_required":true,"approval_request_id":"approval_test","approval_gates":["file_write","shell_command"],"approval_status":"required_pending","policy_decision":"require_approval","redaction_applied":true,"execution_allowed":false}
JSONL

cat > "${TMP}/merlin-approvals.jsonl" <<'JSONL'
{"approval_request_id":"approval_test","timestamp":"2026-05-08T01:01:00Z","status":"required_pending","execution_allowed":false,"user_goal_hash":"sha256:routehash","route_id":"code","approval_gates":["file_write","shell_command"],"redaction_applied":true}
JSONL

cat > "${TMP}/merlin-magic-plans.jsonl" <<'JSONL'
{"plan_id":"magic_test","timestamp":"2026-05-08T01:02:00Z","user_goal_hash":"sha256:magichash","route_id":"code","plan_status":"blocked_pending_approval","approval_gates":["file_write"],"execution_allowed":false,"redaction_applied":true,"raw_goal_logged":false,"decision_reason":"token=sk-test12345678901234567890"}
JSONL

cat > "${TMP}/merlin-memory-reads.jsonl" <<'JSONL'
{"memory_read_id":"mread_test","timestamp":"2026-05-08T01:03:00Z","query_hash":"sha256:queryhash","memory_type":"preference","result_status":"searched","route_id":"memory","execution_allowed":false,"redaction_applied":true,"query_preview":"password=supersecret123"}
JSONL

cat > "${TMP}/merlin-memory-writes.jsonl" <<'JSONL'
{"memory_write_id":"mem_test","timestamp":"2026-05-08T01:04:00Z","memory_text_hash":"sha256:memoryhash","memory_type":"preference","result_status":"simulated","route_id":"memory","approval_gates":["memory_write"],"execution_allowed":false,"redaction_applied":true,"memory_preview":"AKIAIOSFODNN7EXAMPLE"}
JSONL

cat > "${TMP}/merlin-outcomes.jsonl" <<'JSONL'
{"task_hash":"sha256:taskhash","created_at":"2026-05-08T01:05:00Z","route_id":"general","outcome_status":"success","approval_id":"approval_test","execution_allowed":false,"redaction_applied":true}
JSONL

OUTPUT="$(bash "${STACK_DIR}/scripts/merlin-audit-view.sh" list --log-dir "$TMP" --limit 10)"
require_output "$OUTPUT" '^Merlin audit viewer$' "audit heading missing"
require_output "$OUTPUT" '^backend: local_jsonl$' "audit viewer should use local JSONL"
require_output "$OUTPUT" '^external_telemetry: false$' "audit viewer must not use external telemetry"
require_output "$OUTPUT" '^execution_allowed: false$' "audit viewer must not allow execution"
require_output "$OUTPUT" '^count: 6$' "audit viewer should show six records"
require_output "$OUTPUT" 'type: route' "route record missing"
require_output "$OUTPUT" 'type: approval' "approval record missing"
require_output "$OUTPUT" 'type: magic' "magic record missing"
require_output "$OUTPUT" 'type: memory_read' "memory read record missing"
require_output "$OUTPUT" 'type: memory_write' "memory write record missing"
require_output "$OUTPUT" 'type: outcome' "outcome record missing"
require_output "$OUTPUT" 'id: magic_test' "magic id missing"
require_output "$OUTPUT" 'hash: sha256:magichash' "magic hash missing"

if echo "$OUTPUT" | grep -Eq -- 'supersecret123|AKIAIOSFODNN7EXAMPLE|sk-test'; then
  fail "audit viewer must not print raw secret-like values"
fi

MAGIC_ONLY="$(bash "${STACK_DIR}/cli/wizard" merlin audit list --log-dir "$TMP" --type magic --limit 5)"
require_output "$MAGIC_ONLY" '^count: 1$' "wizard audit type filter should show one magic record"
require_output "$MAGIC_ONLY" 'type: magic' "wizard audit should include magic record"
if echo "$MAGIC_ONLY" | grep -Eq -- 'supersecret123|AKIAIOSFODNN7EXAMPLE|sk-test'; then
  fail "wizard audit viewer must not print raw secret-like values"
fi

echo "PASS: Merlin audit viewer summarizes local redacted JSONL records"
