#!/usr/bin/env bash
# Merlin AI uninstaller.
#
# Safe defaults:
# - stops Merlin AI services
# - removes launchd agents
# - backs up .env before deleting files
# - keeps Docker Desktop, Homebrew, and Ollama models
# - removes Docker volumes only with --remove-data
# - removes Merlin-managed downloads only with explicit purge options
set -euo pipefail

INSTALL_DIR="${HOME}/merlin-ai"
SYSTEM_DIR="/usr/local/merlin-ai"
PKG_ID="com.merlin.ai"
LEGACY_PKG_IDS=(
  "com.homeai.elite"
)
MODEL_TIERS_FILE="${INSTALL_DIR}/configs/merlin/model-tiers.env"
FALLBACK_MODEL_TIERS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/configs/merlin/model-tiers.env"
MERLIN_STATE_DIR="${HOME}/.merlin"
INSTALL_MANIFEST="${MERLIN_STATE_DIR}/install-manifest.json"

YES=false
DRY_RUN=false
REMOVE_DATA=false
REMOVE_FILES=true
FORGET_RECEIPT=true
PURGE_IMAGES=false
PURGE_OLLAMA_MODELS=false
PURGE_DEPENDENCIES=false
FORCE_PURGE_DEPENDENCIES=false

usage() {
  cat <<'USAGE'
Usage: bash pkg/scripts/uninstall.sh [options]

Options:
  --yes             Do not prompt for confirmation.
  --dry-run         Print what would be removed without changing anything.
  --remove-data     Remove Docker volumes/data for the stack.
  --purge-images    Remove Docker images used by the stack.
  --purge-models    Remove Merlin-recommended Ollama models.
  --purge-all       Remove app files, Docker data/images, and Merlin models.
  --purge-dependencies
                    Also remove dependencies Merlin installed itself.
                    Requires --i-understand-shared-tools unless dry-run.
  --i-understand-shared-tools
                    Confirm dependency removal may affect other apps.
  --keep-files      Stop services and agents, but keep install directories.
  --keep-receipt    Do not forget the macOS pkgutil receipt.
  -h, --help        Show this help.

Default behavior removes Merlin AI app files after confirmation, but keeps
Docker Desktop, Homebrew, Ollama, and Ollama models. Docker volumes are kept
unless --remove-data is provided.

Use --purge-all when preparing a truly clean reinstall. This removes Merlin
Docker volumes/images and the known Merlin-recommended Ollama models, but it
does not uninstall Docker Desktop, Homebrew, or the Ollama app/binary itself.
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
    --purge-images)
      PURGE_IMAGES=true
      ;;
    --purge-models)
      PURGE_OLLAMA_MODELS=true
      ;;
    --purge-all)
      REMOVE_DATA=true
      PURGE_IMAGES=true
      PURGE_OLLAMA_MODELS=true
      ;;
    --purge-dependencies)
      PURGE_DEPENDENCIES=true
      REMOVE_DATA=true
      PURGE_IMAGES=true
      PURGE_OLLAMA_MODELS=true
      ;;
    --i-understand-shared-tools)
      FORCE_PURGE_DEPENDENCIES=true
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

sudo_noninteractive_available() {
  [[ "$(id -u)" == "0" ]] && return 0
  command -v sudo >/dev/null 2>&1 || return 1
  sudo -n true >/dev/null 2>&1
}

json_manifest_bool() {
  local key="$1"
  [[ -f "$INSTALL_MANIFEST" ]] || return 1
  python3 - "$INSTALL_MANIFEST" "$key" <<'PY' 2>/dev/null
import json
import sys

path, dotted = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as handle:
    data = json.load(handle)
node = data
for part in dotted.split("."):
    node = node[part]
if node is True:
    print("true")
else:
    print("false")
PY
}

manifest_dependency_installed_by_merlin() {
  local dependency="$1"
  [[ "$(json_manifest_bool "dependencies.${dependency}.installed_by_merlin" 2>/dev/null || true)" == "true" ]]
}

manual_admin_cleanup_hint() {
  local target="$1"
  local command_text="$2"
  warn "Skipped ${target}; admin privileges are required."
  warn "Run manually if needed: ${command_text}"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

confirm() {
  [[ "$YES" == true || "$DRY_RUN" == true ]] && return 0

  echo "This will uninstall Merlin AI from this Mac."
  echo "Kept: Docker Desktop, Homebrew, and the Ollama app/binary."
  if [[ "$REMOVE_DATA" == true ]]; then
    echo "Removed: app files, launchd agents, Docker containers, Docker volumes."
  else
    echo "Removed: app files, launchd agents, Docker containers."
    echo "Kept: Docker volumes/data. Use --remove-data for a clean reset."
  fi
  if [[ "$PURGE_IMAGES" == true ]]; then
    echo "Removed: Docker images used by the stack."
  else
    echo "Kept: Docker images. Use --purge-images to remove downloaded stack images."
  fi
  if [[ "$PURGE_OLLAMA_MODELS" == true ]]; then
    echo "Removed: known Merlin-recommended Ollama models."
  else
    echo "Kept: Ollama models. Use --purge-models or --purge-all to remove Merlin models."
  fi
  if [[ "$PURGE_DEPENDENCIES" == true ]]; then
    echo "Dependency purge requested."
    echo "Merlin will only remove shared tools marked installed_by_merlin in:"
    echo "  ${INSTALL_MANIFEST}"
    echo "This can affect other local AI or developer tools."
  fi
  echo ""
  read -r -p "Type YES to continue: " answer
  [[ "$answer" == "YES" ]] || { echo "Cancelled."; exit 0; }
}

validate_dependency_purge_confirmation() {
  [[ "$PURGE_DEPENDENCIES" == true ]] || return 0
  [[ "$DRY_RUN" == true ]] && return 0
  if [[ "$FORCE_PURGE_DEPENDENCIES" != true ]]; then
    warn "Dependency purge was requested but not confirmed."
    warn "Re-run with --i-understand-shared-tools after reviewing ${INSTALL_MANIFEST}."
    exit 2
  fi
}

compose_down() {
  local compose_file="${INSTALL_DIR}/docker-compose.yml"
  [[ -f "$compose_file" ]] || compose_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docker-compose.yml"

  if [[ ! -f "$compose_file" ]]; then
    warn "docker-compose.yml not found; skipping Docker cleanup"
    return 0
  fi

  local cleanup_command
  if [[ "$REMOVE_DATA" == true && "$PURGE_IMAGES" == true ]]; then
    cleanup_command="docker compose -f ${compose_file} down --volumes --rmi all --remove-orphans"
  elif [[ "$REMOVE_DATA" == true ]]; then
    cleanup_command="docker compose -f ${compose_file} down --volumes --remove-orphans"
  elif [[ "$PURGE_IMAGES" == true ]]; then
    cleanup_command="docker compose -f ${compose_file} down --rmi all --remove-orphans"
  else
    cleanup_command="docker compose -f ${compose_file} down --remove-orphans"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ "$REMOVE_DATA" == true && "$PURGE_IMAGES" == true ]]; then
      log "Stopping services and removing Docker volumes and stack images"
      run docker compose -f "$compose_file" down --volumes --rmi all --remove-orphans
    elif [[ "$REMOVE_DATA" == true ]]; then
      log "Stopping services and removing Docker volumes"
      run docker compose -f "$compose_file" down --volumes --remove-orphans
    elif [[ "$PURGE_IMAGES" == true ]]; then
      log "Stopping services and removing stack images"
      run docker compose -f "$compose_file" down --rmi all --remove-orphans
    else
      log "Stopping services without removing Docker volumes"
      run docker compose -f "$compose_file" down --remove-orphans
    fi
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker CLI not found; skipping Docker cleanup"
    warn "Run manually if needed: ${cleanup_command}"
    return 0
  fi

  if ! docker info >/dev/null 2>&1; then
    warn "Docker engine not running; skipping Docker cleanup"
    warn "Run manually if needed after Docker starts: ${cleanup_command}"
    return 0
  fi

  if [[ "$REMOVE_DATA" == true && "$PURGE_IMAGES" == true ]]; then
    log "Stopping services and removing Docker volumes and stack images"
    run docker compose -f "$compose_file" down --volumes --rmi all --remove-orphans
  elif [[ "$REMOVE_DATA" == true ]]; then
    log "Stopping services and removing Docker volumes"
    run docker compose -f "$compose_file" down --volumes --remove-orphans
  elif [[ "$PURGE_IMAGES" == true ]]; then
    log "Stopping services and removing stack images"
    run docker compose -f "$compose_file" down --rmi all --remove-orphans
  else
    log "Stopping services without removing Docker volumes"
    run docker compose -f "$compose_file" down --remove-orphans
  fi
}

merlin_model_names() {
  local tiers_file="$MODEL_TIERS_FILE"
  [[ -f "$tiers_file" ]] || tiers_file="$FALLBACK_MODEL_TIERS_FILE"
  [[ -f "$tiers_file" ]] || return 0

  awk '
    /^[[:space:]]*"/ {
      gsub(/[",]/, "", $1)
      if ($1 != "") print $1
    }
  ' "$tiers_file" | sort -u
}

ollama_model_is_installed() {
  local model="$1"
  local installed="$2"
  local model_latest="${model}:latest"

  printf '%s\n' "$installed" | awk '{print $1}' | grep -qx "$model" && return 0
  if [[ "$model" != *:* ]]; then
    printf '%s\n' "$installed" | awk '{print $1}' | grep -qx "$model_latest" && return 0
  fi
  return 1
}

remove_ollama_models() {
  [[ "$PURGE_OLLAMA_MODELS" == true ]] || return 0

  if [[ "$DRY_RUN" != true ]] && ! command -v ollama >/dev/null 2>&1; then
    warn "Ollama CLI not found; skipping model purge"
    return 0
  fi

  local models=()
  while IFS= read -r model; do
    [[ -n "$model" ]] && models+=("$model")
  done < <(merlin_model_names)

  if [[ "${#models[@]}" -eq 0 ]]; then
    warn "No Merlin model manifest found; skipping model purge"
    return 0
  fi

  log "Removing Merlin-recommended Ollama models"
  local installed_models=""
  if [[ "$DRY_RUN" != true ]]; then
    installed_models="$(ollama list 2>/dev/null || true)"
  fi

  for model in "${models[@]}"; do
    if [[ "$DRY_RUN" == true ]]; then
      run ollama rm "$model"
    elif ollama_model_is_installed "$model" "$installed_models"; then
      run ollama rm "$model" >/dev/null 2>&1 || warn "Could not remove Ollama model ${model}"
    fi
  done
}

remove_launchd_agents() {
  local uid
  uid="$(id -u)"
  local labels=(
    com.homeai.docker
    com.homeai.stack
    com.homeai.merlin-status-api
    com.homeai.merlin-task-api
    com.homeai.backup
  )

  log "Removing launchd agents"
  for label in "${labels[@]}"; do
    if launchctl print "gui/${uid}/${label}" >/dev/null 2>&1; then
      if [[ "$DRY_RUN" == true ]]; then
        run launchctl bootout "gui/${uid}/${label}"
      elif ! launchctl bootout "gui/${uid}/${label}" 2>/dev/null; then
        warn "Could not unload launchd agent ${label}"
        warn "Run manually if needed: launchctl bootout gui/${uid}/${label}"
      fi
    fi
    run rm -f "${HOME}/Library/LaunchAgents/${label}.plist"
  done
}

backup_env() {
  [[ -f "${INSTALL_DIR}/.env" ]] || return 0
  local backup_path
  backup_path="${HOME}/merlin-ai-env-backup-$(date +%Y%m%d_%H%M%S).env"
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
    elif sudo_noninteractive_available; then
      sudo rm -rf "$SYSTEM_DIR"
    else
      manual_admin_cleanup_hint "$SYSTEM_DIR" "sudo rm -rf ${SYSTEM_DIR}"
    fi
  fi
}

remove_dependencies() {
  [[ "$PURGE_DEPENDENCIES" == true ]] || return 0

  log "Evaluating dependency purge from ${INSTALL_MANIFEST}"
  if [[ ! -f "$INSTALL_MANIFEST" ]]; then
    warn "Install manifest not found; refusing to remove shared dependencies"
    warn "Run manually only if you are sure Docker, Ollama, or Homebrew are not used by other apps."
    return 0
  fi

  if manifest_dependency_installed_by_merlin "ollama"; then
    log "Removing Ollama because manifest says Merlin installed it"
    if [[ "$DRY_RUN" == true ]]; then
      printf '[dry-run] brew uninstall ollama\n'
    elif command -v brew >/dev/null 2>&1; then
      brew uninstall ollama || warn "Could not uninstall Ollama"
    else
      warn "Homebrew not found; cannot uninstall Ollama automatically"
    fi
  else
    log "Keeping Ollama app/binary; manifest does not mark it installed by Merlin"
  fi

  if manifest_dependency_installed_by_merlin "docker_desktop"; then
    log "Removing Docker Desktop because manifest says Merlin installed it"
    if [[ "$DRY_RUN" == true ]]; then
      printf '[dry-run] brew uninstall --cask docker\n'
    elif command -v brew >/dev/null 2>&1; then
      brew uninstall --cask docker || warn "Could not uninstall Docker Desktop"
    else
      warn "Homebrew not found; cannot uninstall Docker Desktop automatically"
    fi
  else
    log "Keeping Docker Desktop; manifest does not mark it installed by Merlin"
  fi

  if manifest_dependency_installed_by_merlin "homebrew"; then
    warn "Homebrew was marked installed by Merlin, but automatic Homebrew removal is not implemented."
    warn "Homebrew is frequently shared by other apps. Remove it manually only if you are certain."
  else
    log "Keeping Homebrew; manifest does not mark it installed by Merlin"
  fi
}

forget_receipt() {
  [[ "$FORGET_RECEIPT" == true ]] || { log "Keeping pkgutil receipt because --keep-receipt was set"; return 0; }

  if ! command -v pkgutil >/dev/null 2>&1; then
    warn "pkgutil not found; skipping receipt cleanup"
    return 0
  fi

  local receipt_id
  local receipt_ids=("$PKG_ID" "${LEGACY_PKG_IDS[@]}")
  for receipt_id in "${receipt_ids[@]}"; do
    log "Forgetting package receipt ${receipt_id}"
    if [[ "$DRY_RUN" == true ]]; then
      printf '[dry-run] sudo pkgutil --forget %s\n' "$receipt_id"
    elif sudo_noninteractive_available; then
      sudo pkgutil --forget "$receipt_id" >/dev/null 2>&1 || warn "No package receipt found for ${receipt_id}"
    else
      manual_admin_cleanup_hint "package receipt ${receipt_id}" "sudo pkgutil --forget ${receipt_id}"
    fi
  done
}

confirm
validate_dependency_purge_confirmation
compose_down
remove_launchd_agents
backup_env
remove_ollama_models
remove_files
forget_receipt
remove_dependencies

log "Uninstall complete"
if [[ "$PURGE_OLLAMA_MODELS" == true ]]; then
  log "Merlin-recommended Ollama models were removed when present"
else
  log "Ollama models were not removed"
fi
if [[ "$PURGE_IMAGES" == true ]]; then
  log "Docker stack images were removed when Docker was available"
else
  log "Docker stack images were not removed"
fi
if [[ "$PURGE_DEPENDENCIES" == true ]]; then
  log "Shared dependencies were evaluated using the Merlin install manifest"
else
  log "Docker Desktop, Homebrew, and the Ollama app/binary were not removed"
fi
