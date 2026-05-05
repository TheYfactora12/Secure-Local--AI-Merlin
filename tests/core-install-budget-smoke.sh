#!/usr/bin/env bash
# Live timing smoke test for the laptop-safe core installer path.
#
# This test is intentionally conservative:
# - core profile only
# - non-interactive
# - model pulls disabled
# - validates the running core afterward
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
BUDGET_SECONDS="${HOME_AI_CORE_INSTALL_BUDGET_SECONDS:-600}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ "$BUDGET_SECONDS" =~ ^[0-9]+$ ]] || fail "HOME_AI_CORE_INSTALL_BUDGET_SECONDS must be numeric"
[[ -f "${STACK_DIR}/install.sh" ]] || fail "Missing install.sh"
[[ -x "${SCRIPT_DIR}/core-live-smoke.sh" ]] || fail "Missing executable tests/core-live-smoke.sh"

echo "Home AI Elite core install budget smoke test"
echo "Budget: ${BUDGET_SECONDS}s"
echo ""

start_epoch="$(date +%s)"

HOME_AI_NON_INTERACTIVE=true \
HOME_AI_SKIP_MODEL_PULLS=true \
bash "${STACK_DIR}/install.sh" --profile core --skip-model-pulls --non-interactive

end_epoch="$(date +%s)"
elapsed=$((end_epoch - start_epoch))

echo ""
echo "Core install elapsed: ${elapsed}s"

if (( elapsed > BUDGET_SECONDS )); then
  fail "Core install exceeded budget: ${elapsed}s > ${BUDGET_SECONDS}s"
fi

bash "${SCRIPT_DIR}/core-live-smoke.sh"

echo ""
echo "PASS: core install completed within ${BUDGET_SECONDS}s and live core smoke passed"
