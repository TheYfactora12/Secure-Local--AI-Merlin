#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Pulling latest Docker images..."
docker compose pull
echo "Restarting stack..."
docker compose up -d
echo "Updating Ollama..."
brew upgrade ollama || true
echo "Update complete."
