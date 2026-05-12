#!/usr/bin/env bash
# Merlin AI — compatibility wrapper for the rollback-aware upgrade path.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPGRADE_SCRIPT="${SCRIPT_DIR}/upgrade.sh"

usage() {
  cat <<'USAGE'
Usage: bash scripts/update.sh [options]

Compatibility wrapper for:
  bash scripts/upgrade.sh

Options are passed through to upgrade.sh, including:
  --dry-run
  --profile <name>
  --profiles <list>
  -h, --help

Merlin updates use the rollback-aware upgrade path. This backs up local config,
the install manifest, and image digests before applying updates.
USAGE
}

if [[ ! -f "$UPGRADE_SCRIPT" ]]; then
  echo "Missing rollback-aware upgrade script: ${UPGRADE_SCRIPT}" >&2
  exit 1
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "Merlin update uses the rollback-aware upgrade path."
exec bash "$UPGRADE_SCRIPT" "$@"
