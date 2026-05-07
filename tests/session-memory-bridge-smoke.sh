#!/usr/bin/env bash
# Static smoke test for the n8n Merlin session memory bridge workflow.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${STACK_DIR}/n8n-workflows/06-session-memory-bridge.json"

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

[[ -f "$WORKFLOW" ]] || fail "missing session memory bridge workflow"
jq empty "$WORKFLOW" >/dev/null || fail "invalid session memory bridge JSON"

require_grep '"path": "merlin/session-memory"' "$WORKFLOW" "workflow webhook path missing"
require_grep 'merlin_session' "$WORKFLOW" "workflow must target merlin_session collection"
require_grep 'nomic-embed-text' "$WORKFLOW" "workflow must use local nomic embeddings"
require_grep 'expected_dimensions: 768' "$WORKFLOW" "workflow must declare 768 dimension expectation"
require_grep 'memory_write_approved' "$WORKFLOW" "workflow must require explicit memory approval flag"
require_grep 'approval_id' "$WORKFLOW" "workflow must carry approval_id"
require_grep 'memory_write approval required' "$WORKFLOW" "denied writes must explain approval requirement"
require_grep 'expires_at' "$WORKFLOW" "workflow must write TTL/expiry metadata"
require_grep 'ttl_kind' "$WORKFLOW" "workflow must support working/episodic TTL kinds"
require_grep 'Qdrant or Ollama unavailable; session continued without memory write' "$WORKFLOW" "write degraded warning missing"
require_grep 'Qdrant or Ollama unavailable; session continued without recall' "$WORKFLOW" "recall degraded warning missing"
require_grep '"continueOnFail": true' "$WORKFLOW" "Qdrant/Ollama calls must degrade gracefully"
require_grep 'context_prefix' "$WORKFLOW" "workflow must return recall context prefix"

if grep -q 'documents' "$WORKFLOW"; then
  fail "session bridge must not write to legacy 1536d documents collection"
fi

python3 - "$WORKFLOW" <<'PY'
import json
import sys

workflow = json.load(open(sys.argv[1], encoding="utf-8"))
nodes = {node["name"]: node for node in workflow.get("nodes", [])}
required_nodes = {
    "Session Memory Webhook",
    "Prepare Session Request",
    "memory_write Approved?",
    "Embed Approved Session Text",
    "Write merlin_session Point",
    "Format Write Result",
    "Embed Session Query",
    "Search merlin_session",
    "Format Recall Result",
    "Return Session Memory Result",
}
missing = sorted(required_nodes - set(nodes))
if missing:
    raise SystemExit(f"missing required nodes: {missing}")

for name in [
    "Embed Approved Session Text",
    "Write merlin_session Point",
    "Embed Session Query",
    "Search merlin_session",
]:
    if nodes[name].get("continueOnFail") is not True:
        raise SystemExit(f"{name} must set continueOnFail=true")

write_url = nodes["Write merlin_session Point"]["parameters"]["url"]
search_url = nodes["Search merlin_session"]["parameters"]["url"]
if "/collections/merlin_session/points" not in write_url:
    raise SystemExit("write URL must target merlin_session points")
if "/collections/merlin_session/points/search" not in search_url:
    raise SystemExit("search URL must target merlin_session points/search")
PY

echo "PASS: Merlin session memory bridge workflow is approval-gated and dimension-safe"
