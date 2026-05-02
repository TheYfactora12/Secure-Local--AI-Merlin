#!/usr/bin/env bash
# Home AI Elite — Backup all persistent data volumes
# Backups go to: ~/home-ai-elite-backups/<timestamp>/
set -euo pipefail

BACKUP_DIR="$HOME/home-ai-elite-backups"
DATESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${DATESTAMP}"

mkdir -p "$BACKUP_PATH"
echo "Backing up to: $BACKUP_PATH"

for vol in open-webui qdrant-storage n8n-data perplexica-data ollama; do
  echo "  Backing up: $vol"
  docker run --rm \
    -v "${vol}:/source:ro" \
    -v "${BACKUP_PATH}:/backup" \
    alpine tar czf "/backup/${vol}.tar.gz" -C /source . 2>/dev/null && \
    echo "    ✓ ${vol}.tar.gz" || \
    echo "    ! ${vol} not found — skipping"
done

echo ""
echo "Backup complete: $BACKUP_PATH"
ls -lh "$BACKUP_PATH"
