#!/usr/bin/env bash
# =============================================================================
# upgrade.sh — Safe upgrade with automatic rollback
# Usage:
#   bash scripts/upgrade.sh
#   bash scripts/upgrade.sh --skip-backup
#   bash scripts/upgrade.sh --dry-run
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROFILE_LIB="${ROOT_DIR}/scripts/profile-lib.sh"

# shellcheck disable=SC1090
source "$PROFILE_LIB"

[[ -f "${ROOT_DIR}/.env" ]] && set -a && source "${ROOT_DIR}/.env" && set +a

SKIP_BACKUP=false
DRY_RUN=false
INSTALL_PROFILE="${HOME_AI_INSTALL_PROFILE:-core}"
CUSTOM_PROFILES="${HOME_AI_PROFILES:-}"

usage() {
  cat <<'USAGE'
Usage: bash scripts/upgrade.sh [options]

Options:
  --skip-backup       Skip local compose/env backup before upgrade.
  --dry-run           Show commands without changing services.
  --profile <name>    Upgrade profile: core, developer, workstation, server, full, custom.
  --profiles <list>   Custom comma-separated capabilities: search,automation,coding,security,ops.
  -h, --help          Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-backup)
      SKIP_BACKUP=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --profile=*)
      INSTALL_PROFILE="${1#*=}"
      shift
      ;;
    --profiles=*)
      CUSTOM_PROFILES="${1#*=}"
      shift
      ;;
    --profile)
      INSTALL_PROFILE="${2:-}"
      shift 2
      ;;
    --profiles)
      CUSTOM_PROFILES="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

normalize_profile_name "$INSTALL_PROFILE" >/dev/null
CAPABILITIES="$(profile_capabilities_for "$INSTALL_PROFILE" "$CUSTOM_PROFILES")"

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"
CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"

log()    { echo -e "${GREEN}[upgrade]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[upgrade]${RESET} $*"; }
fail()   { echo -e "${RED}[upgrade]${RESET} $*" >&2; }
banner() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${RESET}\n"; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[dry-run]${RESET} Would run: $*"
  else
    eval "$*"
  fi
}

BACKUP_ROOT="${HOME_AI_UPGRADE_BACKUP_ROOT:-${ROOT_DIR}/backups}"
BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d_%H%M%S)"
GIT_SHA_BEFORE=$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
UP_TO_DATE=false

preflight() {
  banner "Pre-flight Check"
  if ! docker info >/dev/null 2>&1; then
    fail "Docker is not running. Start Docker Desktop first."
    exit 1
  fi
  log "  ✅ Docker is running"
  log "  Profile: ${INSTALL_PROFILE}${CAPABILITIES:+ (${CAPABILITIES})}"
  log "  Current SHA: ${GIT_SHA_BEFORE:0:8}"
}

backup() {
  if [[ "$SKIP_BACKUP" == true ]]; then
    warn "Skipping backup (--skip-backup)"; return
  fi
  banner "Backup"
  run "mkdir -p '${BACKUP_DIR}'"
  run "echo '${GIT_SHA_BEFORE}' > '${BACKUP_DIR}/git-sha.txt'"
  run "cp '${ROOT_DIR}/docker-compose.yml' '${BACKUP_DIR}/'"
  run "cp '${ROOT_DIR}/.env' '${BACKUP_DIR}/.env.backup' 2>/dev/null || true"
  run "docker compose -f '${ROOT_DIR}/docker-compose.yml' images --format json > '${BACKUP_DIR}/image-digests.json' 2>/dev/null || true"
  log "  ✅ Backup saved: $BACKUP_DIR"
}

git_pull() {
  banner "Pulling Latest Changes"
  if ! git -C "$ROOT_DIR" diff --quiet 2>/dev/null; then
    warn "Local changes detected — stashing..."
    run "git -C '${ROOT_DIR}' stash push -m 'upgrade-stash-$(date +%Y%m%d_%H%M%S)'"
  fi
  run "git -C '${ROOT_DIR}' pull --rebase origin main"
  local SHA_AFTER
  SHA_AFTER=$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
  log "  Updated: ${GIT_SHA_BEFORE:0:8} → ${SHA_AFTER:0:8}"
  [[ "$GIT_SHA_BEFORE" == "$SHA_AFTER" ]] && UP_TO_DATE=true || UP_TO_DATE=false
}

docker_pull() {
  banner "Pulling New Docker Images"
  local compose_args services pull_cmd
  compose_args="$(compose_profile_args)"
  services="$(compose_services)"
  pull_cmd="docker compose -f '${ROOT_DIR}/docker-compose.yml' ${compose_args} pull --quiet ${services}"
  run "$pull_cmd"
  log "  ✅ Images updated"
}

compose_up() {
  banner "Restarting Services"
  local compose_args services up_cmd
  compose_args="$(compose_profile_args)"
  services="$(compose_services)"
  up_cmd="docker compose -f '${ROOT_DIR}/docker-compose.yml' ${compose_args} up -d --remove-orphans ${services}"
  run "$up_cmd"
  log "  ✅ Services restarted"
}

compose_services() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    profile_services_for_darwin "$CAPABILITIES" | xargs
  else
    profile_services_for_linux "$CAPABILITIES" | xargs
  fi
}

compose_profile_args() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    return 0
  fi
  compose_profiles_for_linux "$CAPABILITIES" | awk '{printf "--profile %s ", $0}'
}

health_check() {
  banner "Post-Upgrade Health Check"
  local max_wait="${HOME_AI_UPGRADE_HEALTH_MAX_WAIT:-60}"
  local interval="${HOME_AI_UPGRADE_HEALTH_INTERVAL:-5}"
  local elapsed=0 all_healthy=true
  local labels=("Open WebUI" "Qdrant")
  local urls=("http://localhost:3000" "http://localhost:6333/healthz")

  if [[ " ${CAPABILITIES} " == *" search "* ]]; then
    labels+=("SearXNG")
    urls+=("http://localhost:8080")
  fi
  if [[ " ${CAPABILITIES} " == *" automation "* ]]; then
    labels+=("n8n")
    urls+=("http://localhost:5678/healthz")
  fi

  local i svc url
  for i in "${!labels[@]}"; do
    svc="${labels[$i]}"
    url="${urls[$i]}"
    elapsed=0
    until curl -sf "$url" >/dev/null 2>&1; do
      sleep "$interval"
      elapsed=$((elapsed + interval))
      if [[ $elapsed -ge $max_wait ]]; then
        warn "  ⚠️  $svc did not respond (${max_wait}s)"
        all_healthy=false
        break
      fi
    done
    [[ "$all_healthy" == true ]] && log "  ✅ $svc healthy"
  done

  [[ "$all_healthy" == true ]]
}

rollback() {
  banner "⚠️  ROLLING BACK"
  warn "Health check failed — reverting to ${GIT_SHA_BEFORE:0:8}..."

  if [[ ! -f "${BACKUP_DIR}/git-sha.txt" ]]; then
    fail "No backup found. Manual rollback: git reset --hard $GIT_SHA_BEFORE"
    exit 1
  fi

  git -C "$ROOT_DIR" reset --hard "$GIT_SHA_BEFORE"
  cp "${BACKUP_DIR}/docker-compose.yml" "${ROOT_DIR}/docker-compose.yml"
  local compose_args services
  compose_args="$(compose_profile_args)"
  services="$(compose_services)"
  # shellcheck disable=SC2086
  docker compose -f "${ROOT_DIR}/docker-compose.yml" ${compose_args} up -d --remove-orphans ${services}

  fail "Rollback complete. Check logs: docker compose logs --tail=50"
  fail "Backup preserved at: $BACKUP_DIR"
  exit 1
}

main() {
  [[ "$DRY_RUN" == true ]] && warn "DRY RUN — no changes will be made"
  preflight
  backup
  git_pull

  if [[ "$UP_TO_DATE" == false ]]; then
    docker_pull
    compose_up
    if [[ "$DRY_RUN" == true ]]; then
      log "Dry-run complete — skipping live health check and rollback."
    else
      health_check || rollback
    fi
  else
    log "Already up to date — nothing to do."
  fi

  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║   ✅ Upgrade complete!                   ║"
  echo "  ╠══════════════════════════════════════════╣"
  echo "  ║  Open WebUI  → http://localhost:3000     ║"
  echo "  ║  n8n         → http://localhost:5678     ║"
  echo "  ║  Qdrant      → http://localhost:6333     ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"
}

main "$@"
