#!/usr/bin/env bash
# Static smoke test for Merlin AI / Merlin mythology brand boundaries.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/product/MERLIN_MYTHOLOGY_BRAND_SYSTEM.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "mythology brand doc missing"

for required in \
  "Merlin AI / Merlin Mythology Brand System" \
  "Merlin AI is the product the user installs" \
  "Merlin is the visible assistant" \
  "internal brain inside it" \
  "Round Table" \
  "Excalibur represents powerful action" \
  "The Vault" \
  "stores what matters" \
  "Plain-Language Support Text" \
  "Excalibur must be reserved for high-risk execution authority" \
  "Brand direction: Merlin AI product"; do
  grep -Fq "$required" "$DOC" || fail "mythology brand doc missing: $required"
done

if grep -Fq "#131 — Rename product/repo to Merlin AI" "$DOC"; then
  fail "mythology brand doc still references stale Merlin AI rename issue"
fi

echo "PASS: mythology brand system matches Merlin AI / Merlin direction"
