#!/usr/bin/env bash
# Install optional local browser QA dependencies for Merlin Dashboard screenshots.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-${ROOT_DIR}/.venv-test/bin/python}"

if [[ ! -x "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python3 || true)"
fi

if [[ -z "${PYTHON_BIN}" || ! -x "$PYTHON_BIN" ]]; then
  echo "FAIL: python3 not found and .venv-test/bin/python is unavailable" >&2
  exit 1
fi

"$PYTHON_BIN" -m pip install "playwright>=1.44,<2"
"$PYTHON_BIN" -m playwright install chromium

echo "PASS: browser QA dependencies installed"
echo "Run: $PYTHON_BIN scripts/dashboard-browser-qa.py"
