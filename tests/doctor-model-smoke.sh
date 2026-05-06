#!/usr/bin/env bash
# Smoke-test doctor model reporting without requiring real Ollama or Docker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "${TMP}/bin"
cat > "${TMP}/bin/ollama" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  cat <<'MODELS'
NAME           ID       SIZE      MODIFIED
qwen2.5:7b     fake     4.7 GB    now
nomic-embed-text:latest fake 274 MB now
MODELS
  exit 0
fi
echo "ollama version smoke-test"
SH
chmod +x "${TMP}/bin/ollama"

cat > "${TMP}/model-tiers.env" <<'SH'
MERLIN_LOW_MODELS=("qwen2.5:7b" "nomic-embed-text")
MERLIN_BASE_MODELS=("qwen2.5:7b" "nomic-embed-text")
MERLIN_MID_MODELS=("qwen2.5:7b" "nomic-embed-text")
MERLIN_HIGH_MODELS=("qwen2.5:7b" "nomic-embed-text")
MERLIN_UNKNOWN_MODELS=("qwen2.5:7b" "nomic-embed-text")
SH

set +e
OUTPUT="$(
  PATH="${TMP}/bin:${PATH}" \
  MERLIN_MODEL_TIERS_FILE="${TMP}/model-tiers.env" \
  bash "${STACK_DIR}/scripts/doctor.sh" 2>&1
)"
set -e

echo "$OUTPUT" | grep -q "Installed Ollama models detected: 2" \
  || fail "Doctor did not detect fake installed model"
echo "$OUTPUT" | grep -q "Recommended model installed: qwen2.5:7b" \
  || fail "Doctor did not mark installed recommended model"
echo "$OUTPUT" | grep -q "Recommended model installed: nomic-embed-text" \
  || fail "Doctor did not treat :latest as installed model"

echo "PASS: Doctor model reporting is valid"
