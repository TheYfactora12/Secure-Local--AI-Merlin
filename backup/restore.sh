#!/usr/bin/env bash
# Home AI Elite restore: dry-run by default is available with --dry-run.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash backup/restore.sh [--dry-run] <backup.tar.gz>

Environment:
  QDRANT_URL=http://localhost:6333
  HOME_AI_ASSUME_YES=true   # skip interactive confirmation
USAGE
}

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  shift
fi

[[ -n "${1:-}" ]] || { usage; exit 1; }
FILE="$1"
[[ -f "$FILE" ]] || { echo "[restore] ERROR: File not found: $FILE" >&2; exit 1; }

QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
TMP="$(mktemp -d)"

log() { echo "[restore] $*"; }
warn() { echo "[restore] WARN: $*" >&2; }
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[restore] ERROR: Missing required command: $1" >&2
    exit 1
  }
}

qdrant_ready() {
  curl -fsS --max-time 3 "${QDRANT_URL}/collections" >/dev/null 2>&1
}

collection_exists() {
  curl -fsS --max-time 3 "${QDRANT_URL}/collections/$1" >/dev/null 2>&1
}

extract_points() {
  python3 -c 'import json,sys
d=json.load(sys.stdin)
pts=d.get("result",{}).get("points",[])
print(json.dumps({"points": pts}))'
}

restore_collection_file() {
  local json_file="$1"
  local base collection points_file count

  base="$(basename "$json_file")"
  collection="${base#qdrant_}"
  collection="${collection%.json}"
  points_file="${TMP}/points_${collection}.json"

  if ! extract_points < "$json_file" > "$points_file"; then
    warn "Skipping ${collection}; backup JSON could not be parsed"
    return 0
  fi

  count="$(python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("points", [])))' < "$points_file")"
  if [[ "$count" == "0" ]]; then
    warn "Skipping ${collection}; backup contains no points"
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log "Would restore ${count} point(s) into Qdrant collection: ${collection}"
    return 0
  fi

  if ! collection_exists "$collection"; then
    warn "Skipping ${collection}; collection does not exist. Create it before restore."
    return 0
  fi

  if curl -fsS --max-time 60 \
    -X PUT "${QDRANT_URL}/collections/${collection}/points" \
    -H "Content-Type: application/json" \
    --data-binary @"$points_file" >/dev/null; then
    log "Restored ${count} point(s): ${collection}"
  else
    warn "Failed to restore collection: ${collection}"
  fi
}

main() {
  require_cmd curl
  require_cmd tar
  require_cmd python3

  tar -xzf "$FILE" -C "$TMP"
  SRC="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [[ -n "$SRC" ]] || { echo "[restore] ERROR: Backup archive has no root directory" >&2; exit 1; }

  log "Reading backup: $(basename "$FILE")"

  shopt -s nullglob
  qdrant_files=("${SRC}"/qdrant_*.json)
  if [[ "${#qdrant_files[@]}" -eq 0 ]]; then
    warn "No qdrant_*.json files found in backup"
    return 0
  fi

  if [[ "$DRY_RUN" == false ]]; then
    qdrant_ready || { echo "[restore] ERROR: Qdrant is not reachable at ${QDRANT_URL}" >&2; exit 1; }
    if [[ "${HOME_AI_ASSUME_YES:-false}" != "true" ]]; then
      read -rp "This will upsert backed-up points into existing Qdrant collections. Type yes to continue: " confirm
      [[ "$confirm" == "yes" ]] || { log "Aborted."; exit 0; }
    fi
  fi

  for json_file in "${qdrant_files[@]}"; do
    restore_collection_file "$json_file"
  done

  if [[ -f "${SRC}/.env.bak" ]]; then
    warn ".env.bak is included for manual recovery only; restore does not overwrite .env"
  fi

  log "Restore ${DRY_RUN:+dry-run }complete."
}

main "$@"
