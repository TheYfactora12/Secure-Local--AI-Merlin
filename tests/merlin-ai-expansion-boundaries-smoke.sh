#!/usr/bin/env bash
# Static smoke test for Merlin AI product focus and expansion boundaries.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/product/MERLIN_AI_EXPANSION_BOUNDARIES.md"
CANONICAL="${ROOT_DIR}/docs/CANONICAL_PROJECT_STATE.md"
ROADMAP="${ROOT_DIR}/docs/MERLIN_IMPLEMENTATION_ROADMAP.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing Merlin AI expansion boundaries doc"

for required in \
  "Merlin AI is private AI on your Mac. Merlin is the assistant inside it." \
  "Current Product Wedge" \
  "The first-use loop must stay narrow" \
  "What Exists Today" \
  "What Still Must Improve" \
  "Do Not Sell Or Build Yet" \
  "Deferred Expansion Order" \
  "Release Claims Rule" \
  "Investor Sentence"; do
  grep -q "$required" "$DOC" || fail "expansion boundaries doc missing: $required"
done

grep -q "an enterprise security platform" "$DOC" \
  || fail "expansion boundaries doc must block enterprise overclaiming"
grep -q "Public Beta ready" "$DOC" \
  || fail "expansion boundaries doc must block premature Public Beta claims"
grep -q "Cloud-free in every optional configuration" "$DOC" \
  || fail "expansion boundaries doc must prevent cloud overclaims"
grep -q "local Merlin AI product earns trust" "$DOC" \
  || fail "expansion boundaries doc must require trust before expansion"

grep -q "MERLIN_AI_EXPANSION_BOUNDARIES.md" "$CANONICAL" \
  || fail "canonical state must link the Merlin AI expansion boundaries"
grep -q "Deferred Work" "$ROADMAP" \
  || fail "roadmap must include deferred work boundary"
grep -q "enterprise governance suite" "$ROADMAP" \
  || fail "roadmap must prevent active enterprise-positioning drift"

if grep -q "MERLIN_CONTROL_PLANE_STRATEGY" "$CANONICAL" "$ROADMAP"; then
  fail "canonical/roadmap still reference removed control-plane strategy doc"
fi

echo "PASS: Merlin AI expansion boundaries are focus-aligned"
