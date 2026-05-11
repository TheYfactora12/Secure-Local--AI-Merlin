#!/usr/bin/env bash
# Static smoke test for the Merlin AI v1.0 product north star.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/product/PRODUCT_NORTH_STAR.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing product north star doc"

for required in \
  "Download one file, run it, and in 30 minutes" \
  "Merlin AI" \
  "Merlin is the visible assistant" \
  "v1.0 Must Do Only Five Things" \
  "Install Everything In One Shot" \
  "Tell The User It Worked" \
  "Keep Everything Private" \
  "Recover Gracefully When Something Breaks" \
  "Uninstall Cleanly" \
  "What v1.0 Is Not" \
  "Current Priority Order" \
  "Investor Framing"; do
  grep -q "$required" "$DOC" || fail "north star missing: $required"
done

if grep -q "The Six Core Promises\\|Promise 6\\|MERLIN_CONTROL_PLANE_STRATEGY" "$DOC"; then
  fail "north star still contains old product-scope language"
fi

echo "PASS: Merlin AI north star is focused on the five v1.0 jobs"
