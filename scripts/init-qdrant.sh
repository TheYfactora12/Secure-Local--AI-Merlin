#!/usr/bin/env bash
# =============================================================================
# init-qdrant.sh — Auto-create Qdrant collections on first run
# Called by install.sh and bootstrap.sh after services are healthy
# Qdrant REST API: PUT /collections/{name}
# Docs: https://qdrant.tech/documentation/manage-data/collections/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="${HOME_AI_STACK_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
MEMORY_COLLECTIONS_FILE="${MERLIN_MEMORY_COLLECTIONS_FILE:-${STACK_DIR}/config/merlin/memory-collections.env}"
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
QDRANT_COLLECTION="${QDRANT_COLLECTION:-}"
QDRANT_VECTOR_SIZE="${QDRANT_VECTOR_SIZE:-768}"
EXTRA_QDRANT_COLLECTIONS="${EXTRA_QDRANT_COLLECTIONS:-}"
MERLIN_CREATE_CANONICAL_COLLECTIONS="${MERLIN_CREATE_CANONICAL_COLLECTIONS:-false}"
MAX_WAIT=60
INTERVAL=3

COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

log()  { echo -e "${COLOR_GREEN}[qdrant-init]${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}[qdrant-init]${COLOR_RESET} $*"; }
fail() { echo -e "${COLOR_RED}[qdrant-init]${COLOR_RESET} $*" >&2; exit 1; }

if [[ -f "$MEMORY_COLLECTIONS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$MEMORY_COLLECTIONS_FILE"
else
  warn "Memory collection manifest missing: ${MEMORY_COLLECTIONS_FILE}; using built-in fallback"
  MERLIN_QDRANT_LEGACY_COLLECTIONS=(
    "home_ai_memory:768:Cosine"
    "swarm_memory:768:Cosine"
    "documents:1536:Cosine"
    "openwebui:768:Cosine"
    "perplexica:768:Cosine"
    "n8n_memory:768:Cosine"
    "conversations:768:Cosine"
  )
  MERLIN_QDRANT_LEGACY_INDEXES=(
    "documents:source:keyword"
    "documents:doc_type:keyword"
    "openwebui:user_id:keyword"
    "openwebui:file_id:keyword"
    "perplexica:url:keyword"
    "perplexica:session_id:keyword"
    "n8n_memory:workflow_id:keyword"
    "n8n_memory:session_id:keyword"
  )
  MERLIN_QDRANT_CANONICAL_COLLECTIONS=()
  MERLIN_QDRANT_CANONICAL_INDEXES=()
fi

# ---------------------------------------------------------------------------
# Wait for Qdrant to be ready
# ---------------------------------------------------------------------------
wait_for_qdrant() {
  log "Waiting for Qdrant at $QDRANT_URL ..."
  local elapsed=0
  until curl -sf "${QDRANT_URL}/healthz" >/dev/null 2>&1; do
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
    if [[ $elapsed -ge $MAX_WAIT ]]; then
      fail "Qdrant did not become ready within ${MAX_WAIT}s. Is it running?"
    fi
    warn "  still waiting... (${elapsed}s)"
  done
  log "Qdrant is ready."
}

# ---------------------------------------------------------------------------
# Create a collection if it doesn't already exist
# $1 = collection name
# $2 = vector size (dimensions)
# $3 = distance metric: Cosine | Dot | Euclid
# ---------------------------------------------------------------------------
create_collection() {
  local name="$1" size="$2" distance="$3"

  # Check if already exists
  local status
  status=$(curl -sf -o /dev/null -w "%{http_code}" \
    "${QDRANT_URL}/collections/${name}" 2>/dev/null || echo "000")

  if [[ "$status" == "200" ]]; then
    log "  Collection '${name}' already exists — skipping."
    return 0
  fi

  log "  Creating collection '${name}' (size=${size}, distance=${distance})..."
  local http_code
  http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
    -X PUT "${QDRANT_URL}/collections/${name}" \
    -H 'Content-Type: application/json' \
    -d "{
      \"vectors\": {
        \"size\": ${size},
        \"distance\": \"${distance}\"
      },
      \"optimizers_config\": {
        \"default_segment_number\": 2
      },
      \"replication_factor\": 1
    }" 2>/dev/null || echo "000")

  if [[ "$http_code" == "200" ]]; then
    log "  ✅ Created '${name}'"
  else
    warn "  ⚠️  Failed to create '${name}' (HTTP ${http_code}) — may need manual setup"
  fi
}

# ---------------------------------------------------------------------------
# Create payload index for fast metadata filtering
# $1 = collection name, $2 = field name, $3 = field type (keyword|integer|float|bool)
# ---------------------------------------------------------------------------
create_payload_index() {
  local name="$1" field="$2" type="$3"
  curl -sf -o /dev/null \
    -X PUT "${QDRANT_URL}/collections/${name}/index" \
    -H 'Content-Type: application/json' \
    -d "{\"field_name\": \"${field}\", \"field_schema\": \"${type}\"}" 2>/dev/null || true
}

create_collection_from_spec() {
  local spec="$1"
  local name size distance
  IFS=':' read -r name size distance <<< "$spec"
  [[ -n "$name" ]] || return 0
  create_collection "$name" "${size:-768}" "${distance:-Cosine}"
}

create_index_from_spec() {
  local spec="$1"
  local name field type
  IFS=':' read -r name field type <<< "$spec"
  [[ -n "$name" && -n "$field" ]] || return 0
  create_payload_index "$name" "$field" "${type:-keyword}"
}

collection_in_specs() {
  local wanted="$1"
  shift
  local spec name
  for spec in "$@"; do
    IFS=':' read -r name _ <<< "$spec"
    [[ "$name" == "$wanted" ]] && return 0
  done
  return 1
}

create_extra_collections() {
  local spec name size

  if [[ -n "$QDRANT_COLLECTION" ]] && ! collection_in_specs "$QDRANT_COLLECTION" "${MERLIN_QDRANT_LEGACY_COLLECTIONS[@]}"; then
    create_collection "$QDRANT_COLLECTION" "$QDRANT_VECTOR_SIZE" "Cosine"
  fi

  if [[ -n "$EXTRA_QDRANT_COLLECTIONS" ]]; then
    IFS=',' read -ra extra_specs <<< "$EXTRA_QDRANT_COLLECTIONS"
    for spec in "${extra_specs[@]}"; do
      name="$(echo "$spec" | cut -d: -f1)"
      size="$(echo "$spec" | cut -d: -f2)"
      [[ -n "$name" ]] || continue
      create_collection "$name" "${size:-768}" "Cosine"
    done
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  wait_for_qdrant

  log "Initializing Qdrant collections..."

  log "Creating legacy/current collections from memory manifest..."
  for spec in "${MERLIN_QDRANT_LEGACY_COLLECTIONS[@]}"; do
    create_collection_from_spec "$spec"
  done

  for spec in "${MERLIN_QDRANT_LEGACY_INDEXES[@]}"; do
    create_index_from_spec "$spec"
  done

  if [[ "$MERLIN_CREATE_CANONICAL_COLLECTIONS" == "true" ]]; then
    log "Creating canonical Merlin collections because MERLIN_CREATE_CANONICAL_COLLECTIONS=true..."
    for spec in "${MERLIN_QDRANT_CANONICAL_COLLECTIONS[@]}"; do
      create_collection_from_spec "$spec"
    done
    for spec in "${MERLIN_QDRANT_CANONICAL_INDEXES[@]}"; do
      create_index_from_spec "$spec"
    done
  else
    warn "Canonical Merlin collections are not created by default yet"
  fi

  create_extra_collections

  log ""
  log "✅ Qdrant initialization complete."
  log "   Legacy/current collections initialized from: ${MEMORY_COLLECTIONS_FILE}"
  log "   Dashboard: ${QDRANT_URL}/dashboard"
}

main "$@"
