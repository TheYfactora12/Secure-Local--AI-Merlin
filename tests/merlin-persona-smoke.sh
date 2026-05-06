#!/usr/bin/env bash
# Static smoke test for Merlin persona and operating principles.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PERSONA_FILE="${STACK_DIR}/config/merlin/persona.yaml"

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

[[ -f "$PERSONA_FILE" ]] || fail "missing Merlin persona file"

require_grep 'name: Merlin' "$PERSONA_FILE" "persona name missing"
require_grep 'local_first: true' "$PERSONA_FILE" "local-first default missing"
require_grep 'cloud_by_default: false' "$PERSONA_FILE" "cloud-disabled default missing"
require_grep 'memory_writes_require_approval: true' "$PERSONA_FILE" "memory approval default missing"
require_grep 'risky_actions_require_approval: true' "$PERSONA_FILE" "risky action approval default missing"
require_grep 'protect_working_installer: true' "$PERSONA_FILE" "installer protection principle missing"
require_grep 'ai_engineer:' "$PERSONA_FILE" "AI engineer team mode missing"
require_grep 'security_reviewer:' "$PERSONA_FILE" "security reviewer team mode missing"
require_grep 'Do not download large models' "$PERSONA_FILE" "large model approval rule missing"
require_grep 'Do not run cloud/API calls' "$PERSONA_FILE" "cloud approval rule missing"

echo "PASS: Merlin persona keeps local-first approval principles"
