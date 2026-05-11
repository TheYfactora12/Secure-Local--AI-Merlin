#!/usr/bin/env bash
# Merlin AI — profile-aware backup of persistent Docker volumes.
# Backups go to: ~/merlin-ai-backups/<timestamp>/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
PROFILE_LIB="${STACK_DIR}/scripts/profile-lib.sh"
BACKUP_DIR="${HOME_AI_BACKUP_DIR:-$HOME/merlin-ai-backups}"
DATESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="${BACKUP_DIR}/${DATESTAMP}"
INSTALL_PROFILE="${HOME_AI_PROFILE:-${HOME_AI_INSTALL_PROFILE:-core}}"
CUSTOM_PROFILES="${HOME_AI_PROFILES:-}"
DRY_RUN=false
INCLUDE_DOCKER_OLLAMA="${HOME_AI_BACKUP_DOCKER_OLLAMA:-false}"

usage() {
  cat <<'USAGE'
Usage: bash scripts/backup.sh [options]

Options:
  --profile <name>          Backup profile: core, developer, workstation, server, full, custom.
  --profiles <list>         Custom comma-separated capabilities: search,automation,coding,security,ops.
  --include-docker-ollama   Include the Docker Ollama volume. macOS native Ollama models are not Docker volumes.
  --dry-run                 Print selected volumes without creating archives.
  -h, --help                Show this help.

Default behavior is laptop-safe: core backs up Open WebUI and Qdrant only.
Optional profile data is included only when that profile is selected.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      INSTALL_PROFILE="${2:-}"
      shift 2
      ;;
    --profile=*)
      INSTALL_PROFILE="${1#*=}"
      shift
      ;;
    --profiles)
      CUSTOM_PROFILES="${2:-}"
      shift 2
      ;;
    --profiles=*)
      CUSTOM_PROFILES="${1#*=}"
      shift
      ;;
    --include-docker-ollama)
      INCLUDE_DOCKER_OLLAMA=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

ensure_docker_cli() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  fi

  local docker_app_cli="/Applications/Docker.app/Contents/Resources/bin"
  if [[ -x "${docker_app_cli}/docker" ]]; then
    export PATH="${docker_app_cli}:$PATH"
    return 0
  fi

  return 1
}

compose_project_name() {
  if [[ -n "${COMPOSE_PROJECT_NAME:-}" ]]; then
    echo "$COMPOSE_PROJECT_NAME"
    return 0
  fi

  echo "merlin-ai"
}

volume_name_for() {
  local volume="$1"
  echo "$(compose_project_name)_${volume}"
}

selected_volumes() {
  local capabilities="$1"
  local volumes=(open-webui qdrant-storage)
  local capability

  for capability in $capabilities; do
    case "$capability" in
      search)
        volumes+=(perplexica-data)
        ;;
      automation)
        volumes+=(n8n-data)
        ;;
      coding|security|ops|"")
        ;;
      *)
        echo "Unknown capability in profile list: ${capability}" >&2
        return 1
        ;;
    esac
  done

  if [[ "$INCLUDE_DOCKER_OLLAMA" == true ]]; then
    volumes+=(ollama)
  fi

  printf '%s\n' "${volumes[@]}" | awk '!seen[$0]++'
}

[[ -f "$PROFILE_LIB" ]] || {
  echo "Missing profile helper library: ${PROFILE_LIB}" >&2
  exit 1
}
# shellcheck disable=SC1090
source "$PROFILE_LIB"
normalize_profile_name "$INSTALL_PROFILE" >/dev/null
CAPABILITIES="$(profile_capabilities_for "$INSTALL_PROFILE" "$CUSTOM_PROFILES")"

VOLUMES=()
while IFS= read -r volume; do
  [[ -n "$volume" ]] && VOLUMES+=("$volume")
done < <(selected_volumes "$CAPABILITIES")

echo "Merlin AI backup"
echo "Stack: ${STACK_DIR}"
echo "Profile: ${INSTALL_PROFILE}; capabilities: ${CAPABILITIES:-none}"
echo "Backup path: ${BACKUP_PATH}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run selected Docker volumes:"
  for vol in "${VOLUMES[@]}"; do
    echo "  - $(volume_name_for "$vol") (${vol})"
  done
  exit 0
fi

ensure_docker_cli || {
  echo "Docker CLI not found. Install Docker Desktop first." >&2
  exit 1
}
docker info >/dev/null 2>&1 || {
  echo "Docker engine not running. Open Docker Desktop first." >&2
  exit 1
}

mkdir -p "$BACKUP_PATH"
echo "Backing up selected Docker volumes..."

for vol in "${VOLUMES[@]}"; do
  actual_volume="$(volume_name_for "$vol")"
  echo "  Backing up: ${actual_volume}"
  if docker volume inspect "$actual_volume" >/dev/null 2>&1; then
    docker run --rm \
      -v "${actual_volume}:/source:ro" \
      -v "${BACKUP_PATH}:/backup" \
      alpine tar czf "/backup/${vol}.tar.gz" -C /source . >/dev/null
    echo "    ✓ ${vol}.tar.gz"
  else
    echo "    ! ${actual_volume} not found — skipping"
  fi
done

echo ""
echo "Backup complete: $BACKUP_PATH"
ls -lh "$BACKUP_PATH"
