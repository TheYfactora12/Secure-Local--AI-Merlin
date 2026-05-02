#!/usr/bin/env bash
# =============================================================================
# init-qdrant.sh — Auto-create Qdrant collections on first run
# Called by install.sh and bootstrap.sh after services are healthy
# Qdrant REST API: PUT /collections/{name}
# Docs: https://qdrant.tech/documentation/manage-data/collections/
# =============================================================================
set -euo pipefail

QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
MAX_WAIT=60
INTERVAL=3

COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

log()  { echo -e "${COLOR_GREEN}[qdrant-init]${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}[qdrant-init]${COLOR_RESET} $*"; }
fail() { echo -e "${COLOR_RED}[qdrant-init]${COLOR_RESET} $*" >&2; exit 1; }

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

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  wait_for_qdrant

  log "Initializing Qdrant collections..."

  # Open WebUI RAG — nomic-embed-text produces 768-dim vectors
  create_collection "openwebui"            768  "Cosine"
  create_payload_index "openwebui"         "user_id"   "keyword"
  create_payload_index "openwebui"         "file_id"   "keyword"

  # Perplexica web-search memory — nomic-embed-text 768-dim
  create_collection "perplexica"           768  "Cosine"
  create_payload_index "perplexica"        "url"       "keyword"
  create_payload_index "perplexica"        "session_id" "keyword"

  # n8n long-term memory (AI Agent Memory nodes) — 768-dim
  create_collection "n8n_memory"           768  "Cosine"
  create_payload_index "n8n_memory"        "workflow_id" "keyword"
  create_payload_index "n8n_memory"        "session_id"  "keyword"

  # General-purpose document store for custom scripts / API
  create_collection "documents"            1536 "Cosine"   # OpenAI ada-002 compatible
  create_payload_index "documents"         "source"    "keyword"
  create_payload_index "documents"         "doc_type"  "keyword"

  log ""
  log "✅ Qdrant initialization complete."
  log "   Collections: openwebui | perplexica | n8n_memory | documents"
  log "   Dashboard: ${QDRANT_URL}/dashboard"
}

main "$@"
