#!/usr/bin/env bash
# =============================================================================
# uninstall.sh — Completely remove home-ai-elite from this Mac
#
# What it removes:
#   - All running Docker containers (stack services)
#   - Docker volumes created by the stack
#   - launchd auto-start agents
#   - The install directory (~/ home-ai-elite)
#   - The system payload (/usr/local/home-ai-elite)
#   - pkgutil receipt (so macOS knows it's uninstalled)
#
# What it KEEPS:
#   - Docker Desktop itself
#   - Homebrew
#   - Ollama models (large, expensive to re-download)
#   - Your .env file (backed up before removal)
# =============================================================================
set -euo pipefail

INSTALL_DIR="${HOME}/home-ai-elite"
SYSTEM_DIR="/usr/local/home-ai-elite"
PKG_ID="com.homeai.elite"

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"
CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"

log()    { echo -e "${GREEN}[uninstall]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[uninstall]${RESET} $*"; }
danger() { echo -e "${RED}[uninstall]${RESET} $*"; }
banner() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${RESET}\n"; }

# ---------------------------------------------------------------------------
# Confirmation prompt
# ---------------------------------------------------------------------------
banner "home-ai-elite Uninstaller"
danger "This will remove all home-ai-elite services, containers, and files."
danger "Ollama models and Docker Desktop will NOT be removed."
echo ""
read -r -p "  Are you sure? Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && echo "Cancelled." && exit 0

# ---------------------------------------------------------------------------
# 1. Stop and remove Docker containers + volumes
# ---------------------------------------------------------------------------
banner "Step 1/5: Stopping Services"
if [[ -f "${INSTALL_DIR}/docker-compose.yml" ]] && docker info >/dev/null 2>&1; then
  docker compose -f "${INSTALL_DIR}/docker-compose.yml" down --volumes --remove-orphans 2>/dev/null \
    && log "  ✅ Services stopped and volumes removed" \
    || warn "  Could not stop services (may already be down)"
else
  warn "  Docker not running or stack not found — skipping"
fi

# ---------------------------------------------------------------------------
# 2. Remove launchd agents
# ---------------------------------------------------------------------------
banner "Step 2/5: Removing Auto-Start Agents"
if [[ -f "${INSTALL_DIR}/launchd/install-launchd.sh" ]]; then
  bash "${INSTALL_DIR}/launchd/install-launchd.sh" --uninstall 2>/dev/null \
    && log "  ✅ launchd agents removed" \
    || warn "  Could not remove launchd agents (may already be gone)"
else
  # Manual removal fallback
  for label in com.homeai.docker com.homeai.stack; do
    launchctl bootout "gui/$(id -u)/${label}" 2>/dev/null || true
    rm -f "${HOME}/Library/LaunchAgents/${label}.plist"
  done
  log "  ✅ launchd agents removed (manual)"
fi

# ---------------------------------------------------------------------------
# 3. Backup .env before deletion
# ---------------------------------------------------------------------------
banner "Step 3/5: Backing Up Config"
if [[ -f "${INSTALL_DIR}/.env" ]]; then
  BACKUP_PATH="${HOME}/home-ai-elite-env-backup-$(date +%Y%m%d_%H%M%S).env"
  cp "${INSTALL_DIR}/.env" "$BACKUP_PATH"
  log "  ✅ .env backed up to: $BACKUP_PATH"
fi

# ---------------------------------------------------------------------------
# 4. Remove install directories
# ---------------------------------------------------------------------------
banner "Step 4/5: Removing Files"
rm -rf "$INSTALL_DIR" && log "  ✅ Removed: $INSTALL_DIR"
sudo rm -rf "$SYSTEM_DIR" 2>/dev/null && log "  ✅ Removed: $SYSTEM_DIR" || \
  warn "  Could not remove $SYSTEM_DIR (run with sudo if needed)"

# ---------------------------------------------------------------------------
# 5. Remove pkgutil receipt
# ---------------------------------------------------------------------------
banner "Step 5/5: Removing Package Receipt"
sudo pkgutil --forget "$PKG_ID" 2>/dev/null \
  && log "  ✅ Package receipt removed" \
  || warn "  No receipt found for $PKG_ID (may not have been installed via .pkg)"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   ✅ Uninstall complete!                ║"
echo "  ╠══════════════════════════════════════════╣"
echo "  ║  Docker Desktop: NOT removed           ║"
echo "  ║  Ollama models:  NOT removed           ║"
echo "  ║  Homebrew:       NOT removed           ║"
[[ -n "${BACKUP_PATH:-}" ]] && \
echo "  ║  .env backup: $BACKUP_PATH"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
