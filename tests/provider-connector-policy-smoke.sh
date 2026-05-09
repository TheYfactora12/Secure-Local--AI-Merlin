#!/usr/bin/env bash
# Static smoke test for #117 provider connector setup boundaries.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STORE="${ROOT_DIR}/merlin/provider_connector_store.py"
REGISTRY="${ROOT_DIR}/merlin/provider_registry.py"
STATUS_EXTENSION="${ROOT_DIR}/merlin/status_extension.py"
DOC="${ROOT_DIR}/docs/product/PROVIDER_CONNECTOR_CAPABILITIES.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$STORE" ]] || fail "missing provider connector store"
[[ -f "$REGISTRY" ]] || fail "missing provider registry"
[[ -f "$STATUS_EXTENSION" ]] || fail "missing status extension"
[[ -f "$DOC" ]] || fail "missing provider connector doc"

grep -q "presence_marker_only" "$STORE" \
  || fail "provider connector store must be presence-marker only"
grep -q "secret_persisted: bool = False" "$STORE" \
  || fail "provider connector store must not persist raw secrets"
grep -q "credential_fingerprint" "$STORE" \
  || fail "provider connector store must use fingerprint metadata"
grep -q "approval_id is required" "$STORE" \
  || fail "provider connector setup must require approval id"
grep -q "json.dump" "$STORE" \
  || fail "provider connector store must use structured JSON persistence"

grep -q "provider_connector_writes.*backend_approval_only" "$STATUS_EXTENSION" \
  || fail "settings manifest must describe provider writes as backend approval only"
grep -q '@router.post("/settings/provider-connectors")' "$STATUS_EXTENSION" \
  || fail "missing backend provider connector setup route"
grep -q '@router.post("/settings/provider-connectors/{provider_id}/disable")' "$STATUS_EXTENSION" \
  || fail "missing backend provider connector disable route"
grep -q "Provider connector setup requires explicit approval" "$STATUS_EXTENSION" \
  || fail "provider setup route must reject missing approval"
grep -q '"secret_returned": False' "$STATUS_EXTENSION" \
  || fail "provider setup route must never return submitted secret"
grep -q "write_audit_event(\"provider_connector\"" "$STATUS_EXTENSION" \
  || fail "provider setup route must attempt metadata-only audit"

grep -q "credential_storage" "$REGISTRY" \
  || fail "provider registry must expose credential storage mode"
grep -q "secret_persisted=False" "$REGISTRY" \
  || fail "provider registry must report raw secrets are not persisted"
grep -q "allowed_pending_cloud_gate" "$REGISTRY" \
  || fail "provider registry must keep external allow pending cloud gate"

grep -q "Raw API key values are not persisted" "$DOC" \
  || fail "provider connector doc must state raw keys are not persisted"
grep -q "port 8766" "$DOC" \
  || fail "provider connector doc must route setup through execution-aware API"
grep -q "not cloud routing" "$DOC" \
  || fail "provider connector doc must prevent cloud routing overclaim"

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DOC"; then
  fail "provider connector doc must not contain secret-like values"
fi

echo "PASS: provider connector setup is approval-gated and presence-only"
