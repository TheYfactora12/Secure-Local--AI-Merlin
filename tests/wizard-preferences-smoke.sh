#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

bash -n "$STACK_DIR/cli/wizard"

grep -q "wizard preferences list" "$STACK_DIR/cli/wizard" \
  || fail "wizard preferences list missing from help"
grep -q "wizard preferences review" "$STACK_DIR/cli/wizard" \
  || fail "wizard preferences review missing from help"
grep -q "wizard preferences approve" "$STACK_DIR/cli/wizard" \
  || fail "wizard preferences approve missing from help"
grep -q "MERLIN_PREF_TEXT" "$STACK_DIR/cli/wizard" \
  || fail "preference approval does not pass text through environment"
grep -q "write_approved_preference" "$STACK_DIR/cli/wizard" \
  || fail "preference approval does not call MemoryManager preference store"

if grep -q "preference_text='\${PREF_TEXT}" "$STACK_DIR/cli/wizard"; then
  fail "unsafe inline preference text interpolation found"
fi

FAKE_PYTHON="$TMP_DIR/fake-python"
cat > "$FAKE_PYTHON" <<'PY'
#!/usr/bin/env bash
set -euo pipefail

[[ "${MERLIN_PREF_TEXT:-}" == "User prefers don't use tabs" ]] \
  || { echo "bad MERLIN_PREF_TEXT: ${MERLIN_PREF_TEXT:-}" >&2; exit 1; }
[[ "${MERLIN_PREF_CATEGORY:-}" == "coding_style" ]] \
  || { echo "bad MERLIN_PREF_CATEGORY: ${MERLIN_PREF_CATEGORY:-}" >&2; exit 1; }
[[ "${MERLIN_PREF_APPROVAL_ID:-}" == "manual-approval-001" ]] \
  || { echo "bad MERLIN_PREF_APPROVAL_ID: ${MERLIN_PREF_APPROVAL_ID:-}" >&2; exit 1; }

SCRIPT="$(cat)"
echo "$SCRIPT" | grep -q "PreferenceCandidate" \
  || { echo "approval Python did not build PreferenceCandidate" >&2; exit 1; }
echo "$SCRIPT" | grep -q "write_approved_preference" \
  || { echo "approval Python did not write approved preference" >&2; exit 1; }

echo "✓ preference approved: fake-point"
PY
chmod +x "$FAKE_PYTHON"

OUTPUT="$(MERLIN_PYTHON="$FAKE_PYTHON" bash "$STACK_DIR/cli/wizard" \
  preferences approve "User prefers don't use tabs" coding_style manual-approval-001)"

echo "$OUTPUT" | grep -q "fake-point" \
  || fail "wizard preferences approve did not execute fake approval path"

echo "PASS: wizard preferences commands are wired safely"
