#!/usr/bin/env bash
# Local helper for testing the unsigned Merlin AI .pkg from Terminal.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_PATH="${1:-${ROOT_DIR}/merlin-ai-0.8.6.pkg}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: bash scripts/install-pkg-local.sh [path/to/merlin-ai.pkg]

Installs the local Merlin AI macOS package with a clear administrator password
prompt. For the most consumer-friendly path, double-click the .pkg in Finder.
USAGE
  exit 0
fi

if [[ ! -f "$PKG_PATH" ]]; then
  echo "Merlin AI package not found: $PKG_PATH" >&2
  echo "Build it first with: bash pkg/build-pkg.sh" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Merlin AI .pkg install is macOS only." >&2
  exit 1
fi

echo "Merlin AI needs your Mac administrator password to install system files."
echo "macOS may ask for your password now. Merlin does not store it."
echo ""

if [[ "$(id -u)" != "0" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Cannot ask for a password because this is not an interactive Terminal." >&2
    echo "Open Terminal and run: bash scripts/install-pkg-local.sh" >&2
    echo "Or double-click: $PKG_PATH" >&2
    exit 1
  fi
  sudo -p "Merlin AI admin password: " -v
fi

sudo installer -pkg "$PKG_PATH" -target /
