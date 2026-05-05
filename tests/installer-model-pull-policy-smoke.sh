#!/usr/bin/env bash
# Smoke-test installer model-pull policy without running the installer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALLER="${STACK_DIR}/install.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$INSTALLER" ]] || fail "Missing install.sh"

HELP="$(bash "$INSTALLER" --help)"

echo "$HELP" | grep -q "HOME_AI_PULL_RECOMMENDED_MODELS=true" \
  || fail "Installer help does not document model pull opt-in env"

grep -q 'PULL_RECOMMENDED_MODELS="${HOME_AI_PULL_RECOMMENDED_MODELS:-false}"' "$INSTALLER" \
  || fail "Installer does not default recommended model pulls to false"

grep -q 'Non-interactive install defaults to no model pulls' "$INSTALLER" \
  || fail "Installer does not force no-pull default for non-interactive installs"

grep -Fq 'Pull recommended Ollama models now? [y/N]' "$INSTALLER" \
  || fail "Installer does not prompt before interactive model pulls"

grep -q 'HOME_AI_SKIP_MODEL_PULLS="${SKIP_MODEL_PULLS}"' "$INSTALLER" \
  || fail "Installer does not pass model-pull decision into bootstrap"

echo "PASS: installer model-pull policy is conservative"
