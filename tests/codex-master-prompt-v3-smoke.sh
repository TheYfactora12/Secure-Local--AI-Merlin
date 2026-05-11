#!/usr/bin/env bash
# Static smoke test for the Merlin AI Master Reset Prompt v3.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT="${ROOT_DIR}/docs/CODEX_MASTER_PROMPT_V3.md"
DOCS_INDEX="${ROOT_DIR}/docs/README.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$PROMPT" ]] || fail "missing CODEX_MASTER_PROMPT_V3.md"

for required in \
  "Merlin AI Master Reset Prompt v3.0" \
  "Your private AI. On your Mac. Forever." \
  "Install that just works" \
  "Privacy that is architecturally enforced" \
  "Onboarding that removes confusion" \
  "Uninstall that builds trust" \
  "Open source credibility" \
  "docs/product/FUTURE_IDEAS.md" \
  "git diff --check" \
  "bash tests/installer-branding-smoke.sh"; do
  grep -q "$required" "$PROMPT" || fail "master prompt missing: $required"
done

grep -q "CODEX_MASTER_PROMPT_V3.md" "$DOCS_INDEX" \
  || fail "docs index must link CODEX_MASTER_PROMPT_V3.md"

echo "PASS: Merlin AI Master Reset Prompt v3 is focus-aligned"
