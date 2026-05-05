#!/usr/bin/env bash
# Home AI Elite backup: Qdrant memory, n8n workflows, and local config snapshot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
BACKUP_DIR="${HOME_AI_BACKUP_DIR:-$HOME/wizard-backups}"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
OUT="${BACKUP_DIR}/wizard_backup_${TIMESTAMP}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
N8N_URL="${N8N_URL:-http://localhost:5678}"
COLLECTIONS="${MERLIN_BACKUP_COLLECTIONS:-home_ai_memory swarm_memory documents openwebui perplexica n8n_memory conversations}"

log() { echo "[backup] $*"; }
warn() { echo "[backup] WARN: $*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[backup] ERROR: Missing required command: $1" >&2
    exit 1
  }
}

qdrant_ready() {
  curl -fsS --max-time 3 "${QDRANT_URL}/collections" >/dev/null 2>&1
}

collection_exists() {
  curl -fsS --max-time 3 "${QDRANT_URL}/collections/$1" >/dev/null 2>&1
}

backup_collection() {
  local collection="$1"
  local target="${OUT}/qdrant_${collection}.json"

  if ! collection_exists "$collection"; then
    warn "Skipping missing Qdrant collection: ${collection}"
    return 0
  fi

  if curl -fsS --max-time 60 \
    -X POST "${QDRANT_URL}/collections/${collection}/points/scroll" \
    -H "Content-Type: application/json" \
    -d '{"limit":10000,"with_payload":true,"with_vector":false}' \
    > "$target" 2>/dev/null; then
    log "Qdrant collection backed up: ${collection}"
  else
    warn "Failed to back up Qdrant collection: ${collection}"
    rm -f "$target"
  fi
}

backup_n8n() {
  local target="${OUT}/n8n_workflows.json"

  if curl -fsS --max-time 10 "${N8N_URL}/api/v1/workflows" \
    -H "Accept: application/json" > "$target" 2>/dev/null; then
    log "n8n workflows backed up"
  else
    warn "Skipping n8n workflows; service may be disabled or require an API key"
    rm -f "$target"
  fi
}

backup_env_snapshot() {
  local env_file="${STACK_DIR}/.env"

  if [[ -f "$env_file" ]]; then
    cp "$env_file" "${OUT}/.env.bak"
    chmod 600 "${OUT}/.env.bak"
    log ".env snapshot backed up"
  else
    warn "No .env found at ${env_file}; skipping config snapshot"
  fi
}

main() {
  require_cmd curl
  require_cmd tar

  mkdir -p "$OUT"
  log "Writing backup to ${OUT}"

  if qdrant_ready; then
    for collection in $COLLECTIONS; do
      backup_collection "$collection"
    done
  else
    warn "Qdrant is not reachable at ${QDRANT_URL}; skipping memory backup"
  fi

  backup_n8n
  backup_env_snapshot

  (
    cd "$BACKUP_DIR"
    tar -czf "wizard_backup_${TIMESTAMP}.tar.gz" "wizard_backup_${TIMESTAMP}/"
  )
  rm -rf "$OUT"

  log "Backup complete: ${BACKUP_DIR}/wizard_backup_${TIMESTAMP}.tar.gz"
}

main "$@"
