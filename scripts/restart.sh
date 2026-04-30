#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose down
docker compose up -d
brew services restart ollama || true
echo "Stack restarted."
