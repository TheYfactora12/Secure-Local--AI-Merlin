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
grep -q "/status/rooms" "$DASHBOARD_FILE" \
  || fail "dashboard must load read-only Rooms manifest"
grep -q "function loadRooms" "$DASHBOARD_FILE" \
  || fail "dashboard missing Rooms manifest loader"
grep -q "rooms-manifest-panel" "$DASHBOARD_FILE" \
  || fail "dashboard missing Rooms manifest panel"
grep -q "Room Review Table" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room review table"
grep -q "rooms-review-table" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room review table container"
grep -q "function roomReviewTableHtml" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room review table renderer"
grep -q "function saveCurrentChatToRoom" "$DASHBOARD_FILE" \
  || fail "dashboard missing user-initiated Room table save action"
grep -q "Saving the latest chat uses the backend approval lifecycle and writes local Markdown only" "$DASHBOARD_FILE" \
  || fail "Rooms manifest must describe approval-gated local save behavior"
grep -q "Room Master Prompt drafts require a separate backend approval and are not approved context" "$DASHBOARD_FILE" \
  || fail "Rooms manifest must describe approval-gated Room Master Prompt drafts"
grep -q "Save chat to Room" "$DASHBOARD_FILE" \
  || fail "Rooms surface must expose user-initiated chat Room save surface"
grep -q "Save to Room" "$DASHBOARD_FILE" \
  || fail "Rooms save flow must require a prepare approval step"
grep -q "Allow once" "$DASHBOARD_FILE" \
  || fail "Rooms save flow must require explicit one-time allow action"
grep -q "Merlin does not interrupt every prompt" "$DASHBOARD_FILE" \
  || fail "Rooms save flow must stay user-initiated, not nag every prompt"
grep -q 'data-room-save-stage="waiting"' "$DASHBOARD_FILE" \
  || fail "Rooms save flow must expose a waiting stage before Merlin responds"
grep -q 'data-room-save-stage="response-ready"' "$DASHBOARD_FILE" \
  || fail "Rooms save flow must expose a prepare stage after a safe response"
grep -q 'data-room-save-stage="approval-prepared"' "$DASHBOARD_FILE" \
  || fail "Rooms save flow must expose an allow/cancel stage after backend approval"
grep -q "Chat normally. Save becomes available after Merlin returns a safe local response" "$DASHBOARD_FILE" \
  || fail "Rooms save waiting stage must explain why save is unavailable"
grep -q "Room approval endpoint is unavailable. Restart Merlin Task API" "$DASHBOARD_FILE" \
  || fail "Rooms save flow must explain stale Task API 404s"
if grep -qE 'requestRoomTranscriptApproval\(\)" \$\{canRequest|allowRoomTranscriptSave\(\)" \$\{canAllow|cancelRoomTranscriptSave\(\)" \$\{canAllow' "$DASHBOARD_FILE"; then
  fail "Rooms save flow must not render unavailable actions as disabled buttons"
fi
grep -q "Rooms are local project spaces" "$DASHBOARD_FILE" \
  || fail "dashboard must explain Rooms in plain language"
grep -q "Active Room picker" "$DASHBOARD_FILE" \
  || fail "chat surface must include active Room picker"
grep -q "function selectActiveRoom" "$DASHBOARD_FILE" \
  || fail "dashboard missing client-side active Room selection"
grep -q "function openRoomInChat" "$DASHBOARD_FILE" \
  || fail "Rooms tab must let users jump back into Chat with a Room selected"
grep -q "Open in Chat" "$DASHBOARD_FILE" \
  || fail "Rooms list must expose Room launcher actions"
grep -q "Reopen latest" "$DASHBOARD_FILE" \
  || fail "Rooms table must expose latest transcript reopen action"
grep -q "Delete latest transcript" "$DASHBOARD_FILE" \
  || fail "Rooms table must expose latest transcript delete action"
grep -q "Room archive/delete remains locked until linked-memory review exists" "$DASHBOARD_FILE" \
  || fail "Rooms table must keep whole-Room archive/delete locked"
grep -q "Ask Merlin first. Save becomes available after a safe local response returns" "$DASHBOARD_FILE" \
  || fail "Rooms table save action must fail closed before Merlin responds"
grep -q "selectTab('chat')" "$DASHBOARD_FILE" \
  || fail "Room launcher must return the user to Merlin Chat"
grep -q "active this session" "$DASHBOARD_FILE" \
  || fail "Room picker must show session-only selection state"
grep -q "Target Room:" "$DASHBOARD_FILE" \
  || fail "Room save panel must show selected target Room"
grep -q "reference policy persistence is tested" "$DASHBOARD_FILE" \
  || fail "Room picker must keep reference policy persistence locked"
grep -q "function createRoomFromField" "$DASHBOARD_FILE" \
  || fail "Rooms surface must expose local Room creation"
grep -q "New Room name" "$DASHBOARD_FILE" \
  || fail "Rooms surface must let users name a Room before creating it"
grep -q "Similarity guard planned" "$DASHBOARD_FILE" \
  || fail "Rooms surface must track future duplicate/similar Room guard"
grep -q "Room context not active yet" "$DASHBOARD_FILE" \
  || fail "chat surface must show Room context state"
grep -q "unless you explicitly allow selected-Room or all-Room sharing" "$DASHBOARD_FILE" \
  || fail "chat Room tag must keep cross-Room sharing explicit"
grep -q "future context retrieval remains Room-only unless explicit sharing is enabled" "$DASHBOARD_FILE" \
  || fail "Rooms launcher must state Room-only context default"
grep -q "Current chat is not silently saved or promoted into memory" "$DASHBOARD_FILE" \
  || fail "chat surface must block silent transcript-to-memory implication"
grep -q "Storage is not inference" "$DASHBOARD_FILE" \
  || fail "Rooms surface must distinguish storage from inference"
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
grep -q "backend approval required" "$DASHBOARD_FILE" \
  || fail "Rooms save flow must require backend approval"
grep -q "draft approval required" "$DASHBOARD_FILE" \
  || fail "Rooms page must show Room Master Prompt draft approval state"
grep -q "Latest transcripts" "$DASHBOARD_FILE" \
  || fail "Rooms surface must show read-only transcript metadata"
grep -q "raw hidden" "$DASHBOARD_FILE" \
  || fail "Rooms manifest must not imply raw transcript content is loaded"
grep -q "separate approval" "$DASHBOARD_FILE" \
  || fail "Rooms page must separate transcript save from memory extraction"
grep -q "must show linked memory" "$DASHBOARD_FILE" \
  || fail "Rooms page must warn that Room delete must account for linked memory"

for required in \
  "A saved transcript does not become approved memory automatically" \
  "Room Master Prompt" \
  "POST http://localhost:8766/approvals/room-master-prompt" \
  "POST http://localhost:8766/rooms/master-prompt-drafts" \
  "POST http://localhost:8766/rooms" \
  "approved_for_context: false" \
  "context_reuse: disabled_until_user_approved" \
  "This is a local draft only" \
  "Prompt-Based Room Management" \
  "Show an approval card in Merlin Chat asking, \"Are you sure?\"" \
  "Delete this Room" \
  "Deletion by prompt is therefore a convenience layer over a visible" \
  "Default policy is **No Room context**" \
  "Cloud/synced folders are treated as user-selected filesystem paths" \
  "Browser-side filesystem writes" \
  "POST http://localhost:8766/rooms/transcripts" \
  "This endpoint requires \`approval_id\`" \
  "POST http://localhost:8766/approvals/room-transcript" \
  "POST http://localhost:8766/approvals/room-transcript-read" \
  "POST http://localhost:8766/rooms/transcripts/read" \
  "POST http://localhost:8766/approvals/room-transcript-delete" \
  "POST http://localhost:8766/rooms/transcripts/delete" \
  "deletes one saved transcript/session inside a Room" \
  "The approval is marked used after the local read" \
  "rejects approvals that are still"; do
  grep -Fq "$required" "$ROOMS_DOC" || fail "Rooms doc missing: $required"
done

POST_COUNT="$(grep -c "method: 'POST'" "$DASHBOARD_FILE" || true)"
[[ "$POST_COUNT" == "3" ]] || fail "dashboard must use only Task API /task POSTs and shared policy-gated POST helper"
grep -q "/approvals/room-transcript" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room transcript approval path"
grep -q "/rooms/transcripts" "$DASHBOARD_FILE" \
  || fail "dashboard missing approved Room transcript save path"
grep -q "/approvals/room-transcript-read" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room transcript read approval path"
grep -q "/rooms/transcripts/read" "$DASHBOARD_FILE" \
  || fail "dashboard missing approved Room transcript read path"
grep -q "/approvals/room-transcript-delete" "$DASHBOARD_FILE" \
  || fail "dashboard missing Room transcript delete approval path"
grep -q "/rooms/transcripts/delete" "$DASHBOARD_FILE" \
  || fail "dashboard missing approved Room transcript delete path"
grep -q "Allow once to reopen saved chat" "$DASHBOARD_FILE" \
  || fail "Rooms surface must expose one-time saved chat reopen approval"
grep -q "Delete this saved transcript" "$DASHBOARD_FILE" \
  || fail "Rooms surface must expose one-time saved transcript delete approval"
grep -q "No local transcript was read, no memory was written" "$DASHBOARD_FILE" \
  || fail "Rooms read cancel path must fail closed"
grep -q "No saved transcript was deleted" "$DASHBOARD_FILE" \
  || fail "Rooms delete cancel path must fail closed"

if grep -qiE '<input|type="password"|writeRoom|deleteRoom|writeMemory|approveGate|denyGate|runShell|downloadModel|pullModel|data-action="approve"|data-action="deny"' "$DASHBOARD_FILE"; then
  fail "Rooms surface must not expose unsafe browser controls"
fi

if grep -qiE 'sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]' "$DASHBOARD_FILE" "$ROOMS_DOC"; then
  fail "Rooms surface/doc must not expose secret-like values"
fi

echo "PASS: Merlin Rooms surface is local, explicit, and non-writing"
