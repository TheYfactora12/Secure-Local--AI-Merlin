#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNINSTALLER="${ROOT_DIR}/pkg/scripts/uninstall.sh"

if [[ ! -f "$UNINSTALLER" ]]; then
  echo "ERROR: missing package uninstaller: ${UNINSTALLER}" >&2
  exit 1
fi

exec bash "$UNINSTALLER" "$@"
