#!/usr/bin/env bash
# Static smoke test for the Merlin Rooms design surface.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_FILE="${ROOT_DIR}/dashboard/index.html"
ROOMS_DOC="${ROOT_DIR}/docs/architecture/MERLIN_ROOMS.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$DASHBOARD_FILE" ]] || fail "dashboard file missing"
[[ -f "$ROOMS_DOC" ]] || fail "Rooms architecture doc missing"

grep -q 'data-tab-target="rooms"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Rooms tab"
grep -q 'data-tab-page="rooms"' "$DASHBOARD_FILE" \
  || fail "dashboard missing Rooms page"
grep -q "Rooms are local project spaces" "$DASHBOARD_FILE" \
  || fail "dashboard must explain Rooms in plain language"
grep -q "Room context not active yet" "$DASHBOARD_FILE" \
  || fail "chat surface must show Room context state"
grep -q "Current chat is not silently saved or promoted into memory" "$DASHBOARD_FILE" \
  || fail "chat surface must block silent transcript-to-memory implication"
grep -q "No Room context" "$DASHBOARD_FILE" \
  || fail "Rooms page must show no-context default"
grep -q "Active Room only" "$DASHBOARD_FILE" \
  || fail "Rooms page must show active-Room reference policy"
grep -q "Selected Rooms" "$DASHBOARD_FILE" \
  || fail "Rooms page must show selected-Rooms reference policy"
grep -q "All Rooms" "$DASHBOARD_FILE" \
  || fail "Rooms page must show all-Rooms reference policy as explicit"
grep -q "Save current chat" "$DASHBOARD_FILE" \
  || fail "Rooms page must show save-to-Room state"
grep -q "separate approval" "$DASHBOARD_FILE" \
  || fail "Rooms page must separate transcript save from memory extraction"
grep -q "must show linked memory" "$DASHBOARD_FILE" \
  || fail "Rooms page must warn that Room delete must account for linked memory"

for required in \
  "A saved transcript does not become approved memory automatically" \
  "Default policy is **No Room context**" \
  "Cloud/synced folders are treated as user-selected filesystem paths" \
  "Browser-side filesystem writes" \
  "Save chat transcript to Room through Task API policy gate"; do
  grep -Fq "$required" "$ROOMS_DOC" || fail "Rooms doc missing: $required"
done

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "1" ]] || fail "dashboard must have exactly one POST: Merlin Task API /task"

if grep -qiE '<input|type="password"|writeRoom|saveRoom|deleteRoom|writeMemory|approveGate|denyGate|runShell|downloadModel|pullModel|data-action="approve"|data-action="deny"' "$DASHBOARD_FILE"; then
  fail "Rooms surface must not expose unsafe browser controls"
fi

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE" "$ROOMS_DOC"; then
  fail "Rooms surface/doc must not expose secret-like values"
fi

echo "PASS: Merlin Rooms surface is local, explicit, and non-writing"
