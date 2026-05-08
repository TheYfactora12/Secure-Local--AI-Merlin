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
  if [[ "\$count" -eq 1 ]]; then
    echo "1111111111111111111111111111111111111111"
  else
    echo "2222222222222222222222222222222222222222"
  fi
  exit 0
fi
exit 0
SH
chmod +x "${TMP}/bin/git"

PATH="${TMP}/bin:${PATH}" HOME_AI_INSTALL_PROFILE=core bash "${STACK_DIR}/scripts/update.sh" >/dev/null

grep -q "docker compose pull dashboard qdrant litellm open-webui" "$LOG" \
  || fail "update.sh did not pull only core macOS services"
grep -q "docker compose up -d dashboard qdrant litellm open-webui" "$LOG" \
  || fail "update.sh did not restart only core macOS services"
if grep -Eq "docker compose (pull|up).* (ollama|n8n|openhands|searxng|perplexica|watchtower|fail2ban)" "$LOG"; then
  fail "update.sh included non-core services for macOS core profile"
fi

PATH="${TMP}/bin:${PATH}" HOME_AI_INSTALL_PROFILE=core bash "${STACK_DIR}/scripts/upgrade.sh" --dry-run --skip-backup >> "$LOG"

grep -q "pull --quiet dashboard qdrant litellm open-webui" "$LOG" \
  || fail "upgrade.sh dry-run did not target core pull services"
grep -q "up -d --remove-orphans dashboard qdrant litellm open-webui" "$LOG" \
  || fail "upgrade.sh dry-run did not target core up services"
if grep -q "n8n         → http://localhost:5678" "$LOG"; then
  fail "upgrade.sh advertised n8n for core profile"
fi

echo "PASS: update and upgrade stay profile-aware"
