#!/usr/bin/env bash
# Smoke-test that update/upgrade commands stay profile-aware.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMP="$(mktemp -d)"
LOG="${TMP}/commands.log"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  if [[ -f "$LOG" ]]; then
    echo "--- command log ---" >&2
    cat "$LOG" >&2
  fi
  exit 1
}

mkdir -p "${TMP}/bin"

cat > "${TMP}/bin/uname" <<'SH'
#!/usr/bin/env bash
echo Darwin
SH
chmod +x "${TMP}/bin/uname"

cat > "${TMP}/bin/docker" <<SH
#!/usr/bin/env bash
echo "docker \$*" >> "${LOG}"
exit 0
SH
chmod +x "${TMP}/bin/docker"

cat > "${TMP}/bin/git" <<SH
#!/usr/bin/env bash
echo "git \$*" >> "${LOG}"
if [[ " \$* " == *" rev-parse HEAD "* ]]; then
  COUNT_FILE="${TMP}/revparse-count"
  count=0
  [[ -f "\$COUNT_FILE" ]] && count="\$(cat "\$COUNT_FILE")"
  count=\$((count + 1))
  echo "\$count" > "\$COUNT_FILE"
  if (( count % 2 == 1 )); then
    echo "1111111111111111111111111111111111111111"
  else
    echo "2222222222222222222222222222222222222222"
  fi
  exit 0
fi
exit 0
SH
chmod +x "${TMP}/bin/git"

PATH="${TMP}/bin:${PATH}" HOME_AI_INSTALL_PROFILE=core bash "${STACK_DIR}/scripts/update.sh" --dry-run >> "$LOG"

grep -q 'exec bash "$UPGRADE_SCRIPT" "$@"' "${STACK_DIR}/scripts/update.sh" \
  || fail "update.sh must delegate to rollback-aware upgrade.sh"
grep -q 'rollback-aware upgrade path' "${STACK_DIR}/scripts/update.sh" \
  || fail "update.sh must explain rollback-aware update behavior"
grep -q "pull --quiet dashboard qdrant litellm open-webui" "$LOG" \
  || fail "update.sh wrapper did not route core pull through upgrade.sh"
grep -q "up -d --remove-orphans dashboard qdrant litellm open-webui" "$LOG" \
  || fail "update.sh wrapper did not route core up through upgrade.sh"
if grep -Eq "docker compose (pull|up).* (ollama|n8n|openhands|searxng|perplexica|watchtower|fail2ban)" "$LOG"; then
  fail "update.sh included non-core services for macOS core profile"
fi

PATH="${TMP}/bin:${PATH}" HOME_AI_INSTALL_PROFILE=core bash "${STACK_DIR}/scripts/upgrade.sh" --dry-run --skip-backup >> "$LOG"

grep -q "pull --quiet dashboard qdrant litellm open-webui" "$LOG" \
  || fail "upgrade.sh dry-run did not target core pull services"
grep -q "up -d --remove-orphans dashboard qdrant litellm open-webui" "$LOG" \
  || fail "upgrade.sh dry-run did not target core up services"
grep -q 'install-manifest.json' "${STACK_DIR}/scripts/upgrade.sh" \
  || fail "upgrade.sh must back up the Merlin install manifest"
grep -q 'http://localhost:8888' "${STACK_DIR}/scripts/upgrade.sh" \
  || fail "upgrade.sh health check must include Merlin Dashboard"
grep -q 'http://localhost:4000/health/readiness' "${STACK_DIR}/scripts/upgrade.sh" \
  || fail "upgrade.sh health check must include LiteLLM readiness"
grep -q 'http://localhost:11434/api/tags' "${STACK_DIR}/scripts/upgrade.sh" \
  || fail "upgrade.sh health check must include local Ollama"
if grep -q 'ollama pull' "${STACK_DIR}/scripts/update.sh" "${STACK_DIR}/scripts/upgrade.sh"; then
  fail "update/upgrade must not pull models silently"
fi
if grep -q "n8n         → http://localhost:5678" "$LOG"; then
  fail "upgrade.sh advertised n8n for core profile"
fi

echo "PASS: update and upgrade stay profile-aware"
