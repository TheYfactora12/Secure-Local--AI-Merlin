#!/usr/bin/env bash
# Static smoke test for the Merlin AI future ideas parking lot.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${ROOT_DIR}/docs/product/FUTURE_IDEAS.md"
NORTH_STAR="${ROOT_DIR}/docs/product/PRODUCT_NORTH_STAR.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DOC" ]] || fail "missing future ideas doc"

for required in \
  "Parking lot, not v1.0 scope" \
  "Install everything in one shot" \
  "Tell the user it worked" \
  "Keep everything private by default" \
  "Recover gracefully when something breaks" \
  "Uninstall cleanly" \
  "Future Issue Parking Map" \
  "#64" \
  "#92" \
  "#111" \
  "#136, #137, #138"; do
  grep -q "$required" "$DOC" || fail "future ideas doc missing: $required"
done

grep -q "FUTURE_IDEAS.md" "$NORTH_STAR" \
  || fail "north star must point non-v1.0 work to future ideas"

echo "PASS: future ideas are parked outside v1.0 scope"
