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

[[ -f "${ROOT_DIR}/.env" ]] && set -a && source "${ROOT_DIR}/.env" && set +a

SKIP_BACKUP=false
DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--skip-backup" ]] && SKIP_BACKUP=true
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

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

BACKUP_DIR="${ROOT_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
GIT_SHA_BEFORE=$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
UP_TO_DATE=false

preflight() {
  banner "Pre-flight Check"
  if ! docker info >/dev/null 2>&1; then
    fail "Docker is not running. Start Docker Desktop first."
    exit 1
  fi
  log "  ✅ Docker is running"
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
  run "docker compose -f '${ROOT_DIR}/docker-compose.yml' pull --quiet"
  log "  ✅ Images updated"
}

compose_up() {
  banner "Restarting Services"
  run "docker compose -f '${ROOT_DIR}/docker-compose.yml' up -d --remove-orphans"
  log "  ✅ Services restarted"
}

health_check() {
  banner "Post-Upgrade Health Check"
  local max_wait=60 interval=5 elapsed=0 all_healthy=true

  declare -A endpoints=(
    ["Open WebUI"]="http://localhost:3000"
    ["n8n"]="http://localhost:5678/healthz"
    ["Qdrant"]="http://localhost:6333/healthz"
    ["SearXNG"]="http://localhost:8080"
  )

  for svc in "${!endpoints[@]}"; do
    local url="${endpoints[$svc]}"
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
  docker compose -f "${ROOT_DIR}/docker-compose.yml" up -d --remove-orphans

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
    health_check || rollback
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
