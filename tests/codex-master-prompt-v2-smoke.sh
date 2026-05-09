#!/usr/bin/env bash
# Static smoke test for Merlin AI Coding Master Prompt v2.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT="${ROOT_DIR}/docs/CODEX_MASTER_PROMPT_V2.md"
DOCS_INDEX="${ROOT_DIR}/docs/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$PROMPT" ]] || fail "missing CODEX_MASTER_PROMPT_V2.md"

for required in \
  "Merlin AI Coding Master Prompt v2" \
  "Product Soul" \
  "Architecture Constraints" \
  "Current Issue Priorities" \
  "#122 Product Focus Cut" \
  "#123 Offline Local Brain" \
  "#134 Product Value Checkpoint" \
  "#135 Merlin Rooms" \
  "8765 is read-only" \
  "8766 is execution-aware and policy-gated" \
  "No silent memory writes" \
  "No secret display" \
  "Sovereignty Indicator" \
  "Round Table Approval Card" \
  "First-Run Flow To Build Toward" \
  "Next Concrete Build Steps"; do
  grep -q "$required" "$PROMPT" || fail "v2 prompt missing: $required"
done

grep -q "ClosClaw/web browsing before Merlin Chat, Rooms, and memory review are useful" "$PROMPT" \
  || fail "v2 prompt must defer web browsing until core loop is useful"
grep -q "Providers, models, web comprehension, agents, and automation are supporting" "$PROMPT" \
  || fail "v2 prompt must keep peripheral systems subordinate"
grep -q "CODEX_MASTER_PROMPT_V2.md" "$DOCS_INDEX" \
  || fail "docs index must link CODEX_MASTER_PROMPT_V2.md"

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$PROMPT"; then
  fail "v2 prompt must not contain secret-like values"
fi

echo "PASS: Merlin AI Coding Master Prompt v2 is focus-aligned"
