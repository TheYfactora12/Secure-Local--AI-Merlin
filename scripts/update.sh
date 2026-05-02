#!/usr/bin/env bash
# Home AI Elite — Pull latest Docker images and restart
set -euo pipefail
echo "Pulling latest images..."
docker compose pull
echo "Restarting with new images..."
docker compose up -d
echo "Update complete. Run: bash scripts/status.sh"
