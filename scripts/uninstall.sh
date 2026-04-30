#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
read -r -p "This will stop all containers and remove stack data. Type YES to confirm: " confirm
[[ "$confirm" == "YES" ]] || { echo "Cancelled."; exit 0; }
docker compose down -v || true
brew services stop ollama || true
echo "Stack stopped and volumes removed."
echo "Stack directory $(pwd) was NOT deleted. Remove manually if desired."
