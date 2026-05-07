#!/usr/bin/env bash
# Offline smoke test for the Merlin memory benchmark harness.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="${ROOT_DIR}/scripts/run-benchmarks.sh"
CONFIG="${ROOT_DIR}/configs/benchmarks/wizard.yaml"
WIZARD="${ROOT_DIR}/cli/wizard"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -x "$RUNNER" ]] || fail "scripts/run-benchmarks.sh must be executable"
[[ -f "$CONFIG" ]] || fail "configs/benchmarks/wizard.yaml missing"

for path in \
  tests/benchmarks/schema.py \
  tests/benchmarks/metrics.py \
  tests/benchmarks/layer_aware.py \
  tests/benchmarks/epbench/adapter.py \
  tests/benchmarks/memoryarena/adapter.py \
  tests/benchmarks/amabench/adapter.py; do
  [[ -f "${ROOT_DIR}/${path}" ]] || fail "missing benchmark file: ${path}"
done

OUTPUT="$(cd "$ROOT_DIR" && bash "$RUNNER" --suite all --profile offline)"
echo "$OUTPUT" | grep -q '"suite": "epbench"' || fail "epbench summary missing"
echo "$OUTPUT" | grep -q '"suite": "memoryarena"' || fail "memoryarena summary missing"
echo "$OUTPUT" | grep -q '"suite": "amabench"' || fail "amabench summary missing"
echo "$OUTPUT" | grep -q '"recall_at_k": 1.0' || fail "expected deterministic recall_at_k 1.0"

grep -q 'benchmark)' "$WIZARD" || fail "wizard benchmark command missing"
grep -q 'run-benchmarks.sh' "$WIZARD" || fail "wizard benchmark must call scripts/run-benchmarks.sh"

echo "PASS: Merlin offline memory benchmark harness is valid"
