#!/bin/bash
# WIZARD Backup — backs up Qdrant memory + n8n workflows
BACKUP_DIR="$HOME/wizard-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT="$BACKUP_DIR/wizard_backup_$TIMESTAMP"
mkdir -p "$OUT"
echo "[WIZARD] Backing up..."
curl -s "http://localhost:5678/api/v1/workflows" -H "Accept: application/json" 2>/dev/null > "$OUT/n8n_workflows.json" && echo "  ✓ n8n workflows"
for col in conversations documents; do
  curl -s "http://localhost:6333/collections/$col/points/scroll" -X POST -H "Content-Type: application/json" -d '{"limit":10000,"with_payload":true,"with_vector":false}' 2>/dev/null > "$OUT/qdrant_${col}.json" && echo "  ✓ qdrant/$col"
done
cp "$HOME/wizard-ai/.env" "$OUT/.env.bak" 2>/dev/null && echo "  ✓ .env"
cd "$BACKUP_DIR" && tar -czf "wizard_backup_$TIMESTAMP.tar.gz" "wizard_backup_$TIMESTAMP/" && rm -rf "$OUT"
echo "✓ Backup: $BACKUP_DIR/wizard_backup_$TIMESTAMP.tar.gz"
