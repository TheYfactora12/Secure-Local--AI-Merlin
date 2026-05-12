#!/usr/bin/env bash
# Verify the Merlin AI macOS package install without changing system state.
set -euo pipefail

PKG_ID="${PKG_ID:-com.merlin.ai}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/merlin-ai}"
USER_INSTALL_DIR="${USER_INSTALL_DIR:-${HOME}/merlin-ai}"
INSTALL_LOG="${INSTALL_LOG:-/tmp/merlin-ai-install.log}"
MANIFEST="${MANIFEST:-${HOME}/.merlin/install-manifest.json}"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

green="\033[0;32m"
yellow="\033[1;33m"
red="\033[0;31m"
reset="\033[0m"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "%bPASS%b %s\n" "$green" "$reset" "$*"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf "%bWARN%b %s\n" "$yellow" "$reset" "$*"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "%bFAIL%b %s\n" "$red" "$reset" "$*"
}

http_check() {
  local label="$1"
  local url="$2"
  local code
  code="$(curl -sS -o /tmp/merlin-verify-pkg-install.out -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || true)"
  if [[ "$code" == "200" ]]; then
    pass "$label is reachable ($url)"
  else
    fail_check "$label is not reachable yet ($url, HTTP ${code:-000})"
  fi
}

file_check() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    pass "$label exists: $path"
  else
    fail_check "$label missing: $path"
  fi
}

launchd_check() {
  local label="$1"
  if launchctl print "gui/$(id -u)/${label}" >/dev/null 2>&1; then
    pass "launchd agent registered: $label"
  else
    fail_check "launchd agent not registered: $label"
  fi
}

echo "Merlin AI package install verification"
echo "This command only checks local state. It does not install, uninstall, or start services."
echo ""

if pkgutil --pkg-info "$PKG_ID" >/dev/null 2>&1; then
  pass "package receipt found: $PKG_ID"
else
  fail_check "package receipt not found: $PKG_ID"
fi

file_check "system package payload" "$INSTALL_DIR"
file_check "user runtime folder" "$USER_INSTALL_DIR"
file_check "install log" "$INSTALL_LOG"

if [[ -f "$INSTALL_LOG" ]]; then
  if rg -q "postinstall complete|install.sh completed|Stack started|Merlin AI is running" "$INSTALL_LOG"; then
    pass "install log contains completion/progress markers"
  else
    warn "install log exists but does not show a clear completion marker yet"
  fi
fi

file_check "dependency install manifest" "$MANIFEST"

launchd_check "com.merlin.docker"
launchd_check "com.merlin.stack"
launchd_check "com.merlin.status-api"
launchd_check "com.merlin.task-api"

http_check "Dashboard" "http://localhost:8888"
http_check "Open WebUI" "http://localhost:3000"
http_check "LiteLLM readiness" "http://localhost:4000/health/readiness"
http_check "Qdrant" "http://localhost:6333/healthz"
http_check "Ollama" "http://localhost:11434/api/tags"
http_check "Merlin status API" "http://localhost:8765/healthz"
http_check "Merlin task API" "http://localhost:8766/status/routes"

echo ""
printf "Summary: %s pass, %s warn, %s fail\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "Merlin package install is not fully verified yet."
  echo "Next useful checks:"
  echo "  tail -n 120 /tmp/merlin-ai-install.log"
  echo "  cd ~/merlin-ai && bash scripts/doctor.sh"
  exit 1
fi

echo "Merlin package install verification passed."

