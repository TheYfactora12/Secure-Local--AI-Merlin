#!/usr/bin/env bash
# Smoke-test upgrade rollback without touching real Docker or remote Git.
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

cat > "${TMP}/bin/curl" <<SH
#!/usr/bin/env bash
echo "curl \$*" >> "${LOG}"
exit 22
SH
chmod +x "${TMP}/bin/curl"

cat > "${TMP}/bin/sleep" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "${TMP}/bin/sleep"

set +e
PATH="${TMP}/bin:${PATH}" \
  HOME_AI_INSTALL_PROFILE=core \
  HOME_AI_UPGRADE_BACKUP_ROOT="${TMP}/backups" \
  HOME_AI_UPGRADE_HEALTH_MAX_WAIT=1 \
  HOME_AI_UPGRADE_HEALTH_INTERVAL=1 \
  bash "${STACK_DIR}/scripts/upgrade.sh" >"${TMP}/upgrade.out" 2>&1
status=$?
set -e

[[ "$status" -ne 0 ]] || fail "upgrade rollback smoke should exit non-zero after forced health failure"

grep -q "git -C ${STACK_DIR} reset --hard 1111111111111111111111111111111111111111" "$LOG" \
  || fail "rollback did not reset to previous git SHA"
grep -q "docker compose -f ${STACK_DIR}/docker-compose.yml up -d --remove-orphans dashboard qdrant litellm open-webui" "$LOG" \
  || fail "rollback did not restart core profile services"
grep -q "docker compose -f ${STACK_DIR}/docker-compose.yml images --format json" "$LOG" \
  || fail "upgrade did not snapshot image digests before rollback"
grep -q "install-manifest.json" "${STACK_DIR}/scripts/upgrade.sh" \
  || fail "upgrade did not include install manifest in backup"
grep -q "Rollback complete" "${TMP}/upgrade.out" \
  || fail "rollback completion message missing"

backup_count="$(find "${TMP}/backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
[[ "$backup_count" -eq 1 ]] || fail "expected one upgrade backup directory, found ${backup_count}"

echo "PASS: upgrade rollback path is testable"
