#!/usr/bin/env bash
# Smoke-test the Phase 2A Merlin config validator.
set -euo pipefail

STACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

OUTPUT="$(python3 "${STACK_DIR}/scripts/merlin-config-validate.py")"
echo "$OUTPUT" | grep -q '^PASS: Merlin config validation passed$' \
  || fail "config validator did not pass current configs"
echo "$OUTPUT" | grep -q '^yaml_files_validated: 8$' \
  || fail "config validator should validate all Merlin YAML files"
echo "$OUTPUT" | grep -q '^route_policy_crosscheck: true$' \
  || fail "config validator should cross-check routes against policy"
echo "$OUTPUT" | grep -q '^memory_dimensions_checked: true$' \
  || fail "config validator should check memory dimension contract"

WIZARD_OUTPUT="$(bash "${STACK_DIR}/cli/wizard" merlin config validate)"
echo "$WIZARD_OUTPUT" | grep -q '^PASS: Merlin config validation passed$' \
  || fail "wizard should route merlin config validate"

mkdir -p "${TMP}/configs/merlin"
cp "${STACK_DIR}/configs/merlin/"*.yaml "${TMP}/configs/merlin/"
sed -i.bak '/memory_write:/,/reason:/d' "${TMP}/configs/merlin/policy.yaml"
if (
  cd "$TMP"
  python3 "${STACK_DIR}/scripts/merlin-config-validate.py"
) >"${TMP}/bad-policy.out" 2>&1; then
  fail "validator should fail when policy gate is missing"
fi
grep -q 'policy.yaml: missing approval gate(s): memory_write' "${TMP}/bad-policy.out" \
  || fail "validator should report missing memory_write gate"

rm -rf "${TMP}/configs/merlin"
LEGACY_ROOT="${TMP}/con""fig/merlin"
mkdir -p "$LEGACY_ROOT"
cp "${STACK_DIR}/configs/merlin/"*.yaml "$LEGACY_ROOT/"
if (
  cd "$TMP"
  python3 "${STACK_DIR}/scripts/merlin-config-validate.py" --config-dir con"fig/merlin"
) >"${TMP}/legacy-root.out" 2>&1; then
  fail "validator should reject legacy root config directory"
fi
grep -q 'config dir must be configs/merlin' "${TMP}/legacy-root.out" \
  || fail "validator should enforce configs/merlin"
grep -q 'legacy root config/ directory must not exist' "${TMP}/legacy-root.out" \
  || fail "validator should reject root config/"

echo "PASS: Merlin config validator enforces Phase 2A contracts"
