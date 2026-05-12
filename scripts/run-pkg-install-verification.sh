#!/usr/bin/env bash
# Guided local .pkg install verification for Merlin AI.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_PATH="${1:-${ROOT_DIR}/merlin-ai-0.8.6.pkg}"
TIMEOUT_SECONDS="${MERLIN_PKG_VERIFY_TIMEOUT_SECONDS:-360}"
INTERVAL_SECONDS="${MERLIN_PKG_VERIFY_INTERVAL_SECONDS:-15}"
EVIDENCE_DIR="${MERLIN_PKG_VERIFY_EVIDENCE_DIR:-${ROOT_DIR}/docs/release/evidence/local}"
STAMP="$(date -u +%Y-%m-%d-%H%M%SZ)"
EVIDENCE_LOG="${EVIDENCE_DIR}/pkg-install-verification-${STAMP}.log"

usage() {
  cat <<'USAGE'
Usage: bash scripts/run-pkg-install-verification.sh [path/to/merlin-ai.pkg]

Runs the local Merlin AI package installer, then waits for postinstall services
and verifies package receipt, files, launchd agents, install log, and localhost
health endpoints.

This command requires an interactive Terminal because macOS needs your admin
password for package installation. Merlin does not store the password.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

log() {
  printf '%s\n' "$*"
  printf '%s\n' "$*" >> "$EVIDENCE_LOG"
}

run_and_log() {
  log ""
  log "$ $*"
  "$@" 2>&1 | tee -a "$EVIDENCE_LOG"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Merlin AI package verification is macOS only." >&2
  exit 1
fi

if [[ ! -t 0 ]]; then
  echo "Cannot run package install verification without an interactive Terminal." >&2
  echo "Open Terminal and run: bash scripts/run-pkg-install-verification.sh" >&2
  exit 1
fi

if [[ ! -f "$PKG_PATH" ]]; then
  echo "Merlin AI package not found: $PKG_PATH" >&2
  echo "Build it first with: bash pkg/build-pkg.sh" >&2
  exit 1
fi

mkdir -p "$EVIDENCE_DIR"

log "Merlin AI package install verification"
log "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Package: $PKG_PATH"
log "Evidence log: $EVIDENCE_LOG"
log ""
log "Step 1: install package. macOS may ask for your administrator password."

run_and_log bash "${ROOT_DIR}/scripts/install-pkg-local.sh" "$PKG_PATH"

log ""
log "Step 2: wait for postinstall, Docker, launchd, and local services."
deadline=$((SECONDS + TIMEOUT_SECONDS))
attempt=1

while true; do
  log ""
  log "Verification attempt ${attempt}"
  if bash "${ROOT_DIR}/scripts/verify-pkg-install.sh" 2>&1 | tee -a "$EVIDENCE_LOG"; then
    log ""
    log "Merlin AI package install verification passed."
    log "Finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    exit 0
  fi

  if (( SECONDS >= deadline )); then
    log ""
    log "Merlin AI package install verification timed out after ${TIMEOUT_SECONDS}s."
    log "Useful next checks:"
    log "  tail -n 120 /tmp/merlin-ai-install.log"
    log "  cd ~/merlin-ai && bash scripts/doctor.sh"
    exit 1
  fi

  log "Waiting ${INTERVAL_SECONDS}s before retry..."
  sleep "$INTERVAL_SECONDS"
  attempt=$((attempt + 1))
done

