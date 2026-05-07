#!/usr/bin/env bash
# Static retry/timeout validation for n8n Ollama HTTP Request nodes.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_DIR="${ROOT_DIR}/n8n-workflows"
WIZARD_FILE="${ROOT_DIR}/cli/wizard"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required for workflow validation"

workflow_count="$(find "$WORKFLOW_DIR" -maxdepth 1 -name "*.json" -print | wc -l | tr -d ' ')"
[[ "$workflow_count" == "5" ]] || fail "expected 5 n8n workflow JSON files, found $workflow_count"

ollama_count=0
while IFS= read -r workflow; do
  jq empty "$workflow" || fail "invalid JSON: $workflow"

  while IFS=$'\t' read -r node_id node_name timeout retry max_tries wait_between continue_on_fail; do
    [[ -n "$node_id" ]] || continue
    ollama_count=$((ollama_count + 1))
    [[ "$timeout" =~ ^[0-9]+$ ]] || fail "$workflow $node_name missing numeric timeout"
    (( timeout >= 90000 )) || fail "$workflow $node_name timeout must be >= 90000ms"
    [[ "$retry" == "true" ]] || fail "$workflow $node_name retryOnFail must be true"
    [[ "$max_tries" == "3" ]] || fail "$workflow $node_name maxTries must be 3"
    [[ "$wait_between" =~ ^[0-9]+$ ]] || fail "$workflow $node_name waitBetweenTries missing"
    (( wait_between > 0 )) || fail "$workflow $node_name waitBetweenTries must be > 0"
    [[ "$continue_on_fail" == "true" ]] || fail "$workflow $node_name continueOnFail must be true"
  done < <(
    jq -r '
      .nodes[]
      | select(.type == "n8n-nodes-base.httpRequest")
      | select((.parameters.url // "") | test("ollama:11434|host\\.docker\\.internal:11434"))
      | [
          .id,
          .name,
          (.parameters.options.timeout // ""),
          (.retryOnFail // false),
          (.maxTries // ""),
          (.waitBetweenTries // ""),
          (.continueOnFail // false)
        ]
      | @tsv
    ' "$workflow"
  )
done < <(find "$WORKFLOW_DIR" -maxdepth 1 -name "*.json" -print | sort)

(( ollama_count > 0 )) || fail "no Ollama HTTP Request nodes found"

grep -q 'test-workflows)' "$WIZARD_FILE" \
  || fail "wizard test-workflows command missing"
grep -q 'n8n-ollama-retry-smoke.sh' "$WIZARD_FILE" \
  || fail "wizard test-workflows must run n8n retry smoke test"

echo "PASS: n8n Ollama HTTP nodes have timeout and retry contracts"
