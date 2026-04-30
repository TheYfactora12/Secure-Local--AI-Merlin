#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
TS=$(date +%Y%m%d-%H%M%S)
DEST="backups/$TS"
mkdir -p "$DEST"
cp -R data/qdrant "$DEST/" 2>/dev/null || true
cp -R data/n8n "$DEST/" 2>/dev/null || true
cp .env "$DEST/" 2>/dev/null || true
echo "Backup saved to $DEST"
