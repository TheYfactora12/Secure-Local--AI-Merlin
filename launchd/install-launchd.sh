#!/usr/bin/env bash
# =============================================================================
# install-launchd.sh — Install or uninstall macOS launchd auto-start agents
#
# Usage:
#   bash ~/home-ai-elite/launchd/install-launchd.sh            # install
#   bash ~/home-ai-elite/launchd/install-launchd.sh --uninstall
#
# What this does:
#   1. Copies .plist files to ~/Library/LaunchAgents/
#   2. Patches WorkingDirectory to match actual install path
#   3. Bootstraps each agent into the current login session
#   4. Verifies agents appear in launchctl list
#
# The stack agent intentionally starts only the laptop-safe core profile through
# `wizard start core`, which also starts the read-only Merlin status API.
# Optional profiles must be started explicitly.
#
# Reference:
#   https://gist.github.com/johndturn/09a5c055e6a56ab61212204607940fa0
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
UID_NUM=$(id -u)

COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

log()  { echo -e "${COLOR_GREEN}[launchd]${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}[launchd]${COLOR_RESET} $*"; }
fail() { echo -e "${COLOR_RED}[launchd]${COLOR_RESET} $*" >&2; exit 1; }

PLISTS=(
  "com.homeai.docker.plist"
  "com.homeai.stack.plist"
)

uninstall() {
  log "Uninstalling home-ai-elite launchd agents..."
  for plist in "${PLISTS[@]}"; do
    local label="${plist%.plist}"
    local dest="${LAUNCH_AGENTS_DIR}/${plist}"
    if launchctl list "$label" &>/dev/null; then
      launchctl bootout "gui/${UID_NUM}/${label}" 2>/dev/null || \
      launchctl unload "${dest}" 2>/dev/null || true
      log "  Unloaded: $label"
    fi
    if [[ -f "$dest" ]]; then
      rm -f "$dest"
      log "  Removed: $dest"
    fi
  done
  log "✅ Agents uninstalled. Services will NOT auto-start on next login."
  exit 0
}

# Handle --uninstall flag
[[ "${1:-}" == "--uninstall" ]] && uninstall

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
preflight() {
  if [[ "$(uname)" != "Darwin" ]]; then
    fail "This script is macOS only. Detected: $(uname)"
  fi

  if [[ ! -d "$INSTALL_DIR" ]]; then
    fail "Install directory not found: $INSTALL_DIR"
  fi

  # Check Docker Desktop is installed
  if [[ ! -d "/Applications/Docker.app" ]]; then
    warn "Docker Desktop not found at /Applications/Docker.app"
    warn "Install it from: https://www.docker.com/products/docker-desktop/"
    warn "Continuing anyway — fix the path in com.homeai.docker.plist if needed."
  fi

  mkdir -p "$LAUNCH_AGENTS_DIR"
}

# ---------------------------------------------------------------------------
# Install one plist
# ---------------------------------------------------------------------------
install_plist() {
  local plist="$1"
  local src="${SCRIPT_DIR}/${plist}"
  local dest="${LAUNCH_AGENTS_DIR}/${plist}"
  local label="${plist%.plist}"

  if [[ ! -f "$src" ]]; then
    warn "  Source not found: $src — skipping"
    return
  fi

  # Patch the install path into the stack plist
  if [[ "$plist" == "com.homeai.stack.plist" ]]; then
    sed "s|\$HOME/home-ai-elite|${INSTALL_DIR}|g" "$src" > "$dest"
    # Also fix the ProgramArguments path
    sed -i '' "s|cd \"\$HOME/home-ai-elite\"|cd \"${INSTALL_DIR}\"|g" "$dest" 2>/dev/null || true
  else
    cp "$src" "$dest"
  fi

  chmod 644 "$dest"

  # Unload first if already registered (idempotent)
  if launchctl list "$label" &>/dev/null; then
    launchctl bootout "gui/${UID_NUM}/${label}" 2>/dev/null || \
    launchctl unload "${dest}" 2>/dev/null || true
    warn "  Re-registering: $label"
  fi

  # Bootstrap into current session
  if launchctl bootstrap "gui/${UID_NUM}" "${dest}"; then
    log "  ✅ Registered: $label"
  else
    # Fallback for older macOS
    launchctl load -w "${dest}" && log "  ✅ Loaded (legacy): $label" || \
      warn "  ⚠️  Could not load $label — may need manual: launchctl load $dest"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  log "Installing home-ai-elite launchd agents..."
  log "  Install dir:  $INSTALL_DIR"
  log "  LaunchAgents: $LAUNCH_AGENTS_DIR"
  log ""

  preflight

  for plist in "${PLISTS[@]}"; do
    install_plist "$plist"
  done

  log ""
  log "✅ Auto-start agents installed."
  log "   On your next macOS login:"
  log "   1. Docker Desktop will open automatically (5s after login)"
  log "   2. The laptop-safe core profile and read-only Merlin status API will start automatically (30s after login)"
  log ""
  log "Verify:"
  log "   launchctl list | grep homeai"
  log "   tail -f /tmp/homeai-stack.log"
  log "   wizard merlin status-api status"
  log ""
  log "To uninstall:"
  log "   bash ${SCRIPT_DIR}/install-launchd.sh --uninstall"
}

main "$@"
