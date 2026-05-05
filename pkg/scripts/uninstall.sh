#!/usr/bin/env bash
# Home AI Elite uninstaller.
#
# Safe defaults:
# - stops Home AI Elite services
# - removes launchd agents
# - backs up .env before deleting files
# - keeps Docker Desktop, Homebrew, and Ollama models
# - removes Docker volumes only with --remove-data
set -euo pipefail

INSTALL_DIR="${HOME}/home-ai-elite"
SYSTEM_DIR="/usr/local/home-ai-elite"
PKG_ID="com.homeai.elite"

YES=false
DRY_RUN=false
REMOVE_DATA=false
REMOVE_FILES=true
FORGET_RECEIPT=true

usage() {
  cat <<'USAGE'
Usage: bash pkg/scripts/uninstall.sh [options]

Options:
  --yes             Do not prompt for confirmation.
  --dry-run         Print what would be removed without changing anything.
  --remove-data     Remove Docker volumes/data for the stack.
  --keep-files      Stop services and agents, but keep install directories.
  --keep-receipt    Do not forget the macOS pkgutil receipt.
  -h, --help        Show this help.

Default behavior removes Home AI Elite app files after confirmation, but keeps
Docker Desktop, Homebrew, Ollama, and Ollama models. Docker volumes are kept
unless --remove-data is provided.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      YES=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --remove-data)
      REMOVE_DATA=true
      ;;
    --keep-files)
      REMOVE_FILES=false
      ;;
    --keep-receipt)
      FORGET_RECEIPT=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

log() { printf '[uninstall] %s\n' "$*"; }
warn() { printf '[uninstall] WARNING: %s\n' "$*" >&2; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

confirm() {
  [[ "$YES" == true || "$DRY_RUN" == true ]] && return 0

  echo "This will uninstall Home AI Elite from this Mac."
  echo "Kept: Docker Desktop, Homebrew, Ollama, Ollama models."
  if [[ "$REMOVE_DATA" == true ]]; then
    echo "Removed: app files, launchd agents, Docker containers, Docker volumes."
  else
    echo "Removed: app files, launchd agents, Docker containers."
    echo "Kept: Docker volumes/data. Use --remove-data for a clean reset."
  fi
  echo ""
  read -r -p "Type YES to continue: " answer
  [[ "$answer" == "YES" ]] || { echo "Cancelled."; exit 0; }
}

compose_down() {
  local compose_file="${INSTALL_DIR}/docker-compose.yml"
  [[ -f "$compose_file" ]] || compose_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docker-compose.yml"

  if [[ ! -f "$compose_file" ]]; then
    warn "docker-compose.yml not found; skipping Docker cleanup"
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ "$REMOVE_DATA" == true ]]; then
      log "Stopping services and removing Docker volumes"
      run docker compose -f "$compose_file" down --volumes --remove-orphans
    else
      log "Stopping services without removing Docker volumes"
      run docker compose -f "$compose_file" down --remove-orphans
    fi
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker CLI not found; skipping Docker cleanup"
    return 0
  fi

  if ! docker info >/dev/null 2>&1; then
    warn "Docker engine not running; skipping Docker cleanup"
    return 0
  fi

  if [[ "$REMOVE_DATA" == true ]]; then
    log "Stopping services and removing Docker volumes"
    run docker compose -f "$compose_file" down --volumes --remove-orphans
  else
    log "Stopping services without removing Docker volumes"
    run docker compose -f "$compose_file" down --remove-orphans
  fi
}

remove_launchd_agents() {
  local uid
  uid="$(id -u)"
  local labels=(
    com.homeai.docker
    com.homeai.stack
    com.homeai.backup
  )

  log "Removing launchd agents"
  for label in "${labels[@]}"; do
    run launchctl bootout "gui/${uid}/${label}" 2>/dev/null || true
    run rm -f "${HOME}/Library/LaunchAgents/${label}.plist"
  done
}

backup_env() {
  [[ -f "${INSTALL_DIR}/.env" ]] || return 0
  local backup_path
  backup_path="${HOME}/home-ai-elite-env-backup-$(date +%Y%m%d_%H%M%S).env"
  log "Backing up .env to ${backup_path}"
  run cp "${INSTALL_DIR}/.env" "$backup_path"
  run chmod 600 "$backup_path" 2>/dev/null || true
}

remove_files() {
  [[ "$REMOVE_FILES" == true ]] || { log "Keeping install directories because --keep-files was set"; return 0; }

  if [[ -d "$INSTALL_DIR" ]]; then
    log "Removing ${INSTALL_DIR}"
    run rm -rf "$INSTALL_DIR"
  fi

  if [[ -d "$SYSTEM_DIR" ]]; then
    log "Removing ${SYSTEM_DIR}"
    if [[ "$DRY_RUN" == true ]]; then
      printf '[dry-run] sudo rm -rf %s\n' "$SYSTEM_DIR"
    else
      sudo rm -rf "$SYSTEM_DIR"
    fi
  fi
}

forget_receipt() {
  [[ "$FORGET_RECEIPT" == true ]] || { log "Keeping pkgutil receipt because --keep-receipt was set"; return 0; }

  if ! command -v pkgutil >/dev/null 2>&1; then
    warn "pkgutil not found; skipping receipt cleanup"
    return 0
  fi

  log "Forgetting package receipt ${PKG_ID}"
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] sudo pkgutil --forget %s\n' "$PKG_ID"
  else
    sudo pkgutil --forget "$PKG_ID" >/dev/null 2>&1 || warn "No package receipt found for ${PKG_ID}"
  fi
}

confirm
compose_down
remove_launchd_agents
backup_env
remove_files
forget_receipt

log "Uninstall complete"
log "Docker Desktop, Homebrew, Ollama, and Ollama models were not removed"
