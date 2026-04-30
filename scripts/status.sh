#!/usr/bin/env bash
set -euo pipefail
echo "=== Docker Containers ==="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true
echo ""
echo "=== Ollama Models ==="
ollama list || true
echo ""
echo "=== Endpoint Health ==="
for url in \
  http://localhost:11434/api/tags \
  http://localhost:3001 \
  http://localhost:5678 \
  http://localhost:6333 \
  http://localhost:3000; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)
  status=$( [[ "$code" =~ ^[23] ]] && echo OK || echo --)
  echo "  $url  [$code $status]"
done
