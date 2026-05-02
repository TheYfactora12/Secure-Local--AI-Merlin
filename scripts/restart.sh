#!/usr/bin/env bash
# Home AI Elite — Restart all services
echo "Restarting Home AI Elite services..."
docker compose restart
echo "Done. Run: bash scripts/status.sh"
