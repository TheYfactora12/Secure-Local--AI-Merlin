#!/bin/bash
# WIZARD Restore
[[ -z "$1" ]] && { echo "Usage: bash restore.sh <backup.tar.gz>"; exit 1; }
FILE="$1"
[[ ! -f "$FILE" ]] && { echo "File not found: $FILE"; exit 1; }
TMP=$(mktemp -d)
tar -xzf "$FILE" -C "$TMP"
EXTRACTED=$(ls "$TMP/")
SRC="$TMP/$EXTRACTED"
echo "[WIZARD] Restoring from $(basename $FILE)..."
read -rp "  This overwrites current memory. Continue? (yes/no): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && { echo "Aborted."; exit 0; }
for col in conversations documents; do
  [[ -f "$SRC/qdrant_${col}.json" ]] && {
    POINTS=$(cat "$SRC/qdrant_${col}.json" | python3 -c "import sys,json; d=json.load(sys.stdin); pts=d.get('result',{}).get('points',[]); print(json.dumps({'points':pts}))" 2>/dev/null)
    [[ -n "$POINTS" ]] && curl -s -X PUT "http://localhost:6333/collections/$col/points" -H "Content-Type: application/json" -d "$POINTS" >/dev/null && echo "  ✓ $col restored"
  }
done
echo "✓ Restore complete."
rm -rf "$TMP"
