# Merlin Rooms Architecture

**Status:** Current design contract for issue #135.
**Last updated:** 2026-05-10
**Scope:** Local chat history and scoped context containers.

## Purpose

Rooms make Merlin Chat user-owned. A Room is a local project, topic, person, or
purpose container that can hold chat history, local context notes, summaries,
and references to approved memory.

Rooms are not a shortcut around the memory approval model. They are the place
where conversation history can be saved locally while reusable Merlin memory
still requires explicit approval.

## Definitions

| Term | Meaning |
| --- | --- |
| Room | A user-visible local workspace for a project/topic/person/purpose. |
| Transcript | The saved chat history for a Room. It is local history, not approved memory. |
| Summary | A human-readable synopsis generated from a transcript. It is not memory until approved. |
| Room Master Prompt | A highly engineered, user-reviewable prompt distilled from Room transcripts, summaries, goals, decisions, preferences, and approved context. It can be tapped into later as scoped context for Merlin or a future Room agent. |
| Room Agent | A future scoped assistant/persona backed by a Room Master Prompt and governed by the Room reference policy. |
| Index | A rebuildable local search cache over Room files. It is not the source of truth. |
| Approved memory | User-approved facts/preferences/context that Merlin may reuse across future sessions. |

## Boundary Rules

1. Chat history may be saved to a Room only through an explicit user flow.
2. A saved transcript does not become approved memory automatically.
3. Room Master Prompt generation is separate from transcript save and must be
   visible, reviewable, and replaceable.
4. Memory extraction follows propose -> stage -> approve/edit/deny -> write.
5. Room reference policy must be visible before Merlin uses Room context.
6. Room storage path must be visible.
7. Cloud/synced folders are treated as user-selected filesystem paths, not cloud
   inference.
8. Merlin must not silently index arbitrary folders.
9. Deleting a Room must show whether approved memories or Room Master Prompts
   were derived from it.
10. Prompt-based Room deletion may exist only as an approval-gated intent flow:
    Merlin can identify the Room by name, but deletion requires explicit review
    and confirmation before any local files are removed.
11. Room creation should keep knowledge clustered. If Merlin can detect a
    similar Room later, it should suggest adding the transcript to the existing
    Room before creating a near-duplicate Room.

## Reference Policies

| Policy | Behavior |
| --- | --- |
| No Room context | Default. Merlin does not use Room context. |
| Active Room only | Merlin may use the currently selected Room. |
| Selected Rooms | Merlin may use only Rooms chosen by the user. |
| All Rooms | Explicit advanced mode. Merlin may search every Room. |

Default policy is **No Room context** until the user chooses otherwise.

## Storage Shape

Future source-of-truth files should be human-readable Markdown:

```text
~/Merlin/brain/
  rooms/
    merlin-build/
      transcripts/
        2026-05-09.md
      summaries/
        2026-05-09-summary.md
      master-prompt.md
      agent.md
      room.md
  memories/
  preferences.md
  merlin-brain.index
```

The Markdown files are the durable user-owned record. Any vector index is a
local cache that can be rebuilt.

## Room Master Prompt Pipeline

The long-term Room value loop is:

1. Save selected Merlin Chat transcript to a local Room.
2. Condense one or more transcripts into a Room summary.
3. Distill summaries, durable decisions, project goals, terminology,
   preferences, and approved context into `master-prompt.md`.
4. Let the user review, edit, accept, or reject the Room Master Prompt.
5. When the user chooses that Room as context, Merlin may attach the Room Master
   Prompt as scoped context before asking the local model.
6. Future Room Agents may use `agent.md` as their scoped behavior contract, but
   execution remains policy-gated.

This pipeline is intentionally not the same as approved memory. A Room Master
Prompt is scoped to that Room and can be disabled, edited, replaced, or deleted
without changing global Merlin memory.

Current implementation does **not** generate Room Master Prompts yet. It only
creates the folder structure needed for that future workflow and saves approved
transcripts as local Markdown.

## Room Creation

Current implementation exposes a local metadata-only Room creation path:

```text
POST http://localhost:8766/rooms
```

The request accepts a user-provided Room name. Merlin creates a safe local slug,
creates `transcripts/`, `summaries/`, `master-prompts/`, and `room.md`, and
records audit metadata without raw chat content. This does not write approved
memory, approve context reuse, call a model, or enable cloud sync.

Current Wizard HQ duplicate prevention compares the proposed Room name against
existing Room names before calling the create endpoint. When an obvious match
exists, Wizard HQ asks the user to use the existing Room or explicitly create a
separate Room. This is a guidance layer only; it does not write files until the
user chooses.

Future duplicate prevention should also compare the first transcript topic and
Room Master Prompt summaries against existing Rooms. When a close match exists,
Wizard HQ should ask: "This looks related to <Room>. Add it there instead?" The
user can choose the existing Room or continue creating the new Room.

## Prompt-Based Room Management

Long term, users should be able to ask Merlin natural-language Room commands:

```text
Delete the Merlin Build room.
Archive the old FFIEC room.
Rename Client A notes to Client A Risk Review.
```

Merlin may parse that request into a Room management intent, but it must not
perform destructive changes directly from chat. The required flow is:

1. Resolve the requested Room by exact name or safe slug.
2. Show the Room path, transcript count, summary count, Room Master Prompt
   status, and any linked approved memory references.
3. If more than one Room matches, ask the user to choose one.
4. Stage a policy-gated approval request.
5. Show an approval card in Merlin Chat asking, "Are you sure?"
6. Require an explicit button click such as `Delete this Room` or `Cancel`.
7. Move the Room to a local archive/trash path first when possible.
8. Record a Chronicle/audit entry with no raw transcript content.

Deletion by prompt is therefore a convenience layer over a visible,
approval-gated backend operation. It is not autonomous cleanup.

## Wizard HQ Surface

Wizard HQ should show:

- active Room,
- Room storage path,
- Room reference policy,
- a Room Review Table with Room metadata, local path, transcript count, latest
  transcript action, Room Master Prompt status, and safe actions,
- save-to-Room state,
- memory extraction state,
- delete/export status.

Discovery remains read-only. The current dashboard may request an approved save
for the latest completed Merlin exchange only through the Task API approval
lifecycle. Arbitrary browser filesystem controls, folder picking, indexing, and
memory extraction remain locked.

The Room Review Table is metadata-only. It may let the user open a Room in
Merlin Chat, start the existing one-time save approval for the latest safe
Merlin response, reopen the latest saved transcript through the one-time read
approval, or delete one saved transcript through the one-time delete approval.
It must not show raw transcript bodies, approve Room context reuse, delete a
whole Room, or bypass the Task API approval lifecycle. Whole-Room archive/delete
remains locked until linked approved memory and Room Master Prompt artifacts can
be reviewed before removal.

The Room creation surface should stay one or two clicks from the right outcome:
name the Room, then either create it or pick the suggested existing Room if the
name appears related. It must not nag during normal chat and must not create
near-duplicate Room folders without the user's explicit confirmation.

Install-time setup creates the default local folder layout:

```text
~/Merlin/brain/rooms/merlin-build/
  room.md
  transcripts/
  summaries/
  master-prompts/
  index/
```

The initializer is idempotent and local-only. It creates folders and Room
metadata so Wizard HQ has a real default save target, but it does not save chat
transcripts, extract memory, index content, pull models, or enable cloud.

## Current Runtime Slice

Current implementation exposes a read-only Task API manifest:

```text
GET http://localhost:8766/status/rooms
```

The manifest reports:

- brain root,
- Rooms root,
- discovered Room metadata folders,
- create Room by name,
- latest transcript metadata by Room,
- active Room state,
- reference policy,
- save-to-Room locked state,
- backend save-to-Room approval requirement,
- memory extraction locked state,
- Room Master Prompt draft state,
- Room Master Prompt draft approval requirement,
- cloud sync default off,
- browser file controls disabled.

Discovery requires a safe Room folder name and a `room.md` metadata file. The
endpoint may return transcript ids, file paths, byte counts, modified
timestamps for already-saved local transcripts, and Room Master Prompt draft
metadata. It does not read or return raw transcript content, raw Room Master
Prompt content, index content, extract memory, or approve context reuse.

Current implementation also exposes an approval-gated write path:

```text
POST http://localhost:8766/rooms/transcripts
```

This endpoint requires `approval_id`, validates a safe Room slug, writes a
local Markdown transcript, and records audit metadata without raw transcript
text. It does not perform memory extraction and does not create browser-side
file controls.

Wizard HQ currently uses this path only for:

- user-initiated save of the current Merlin Chat session,
- the selected active Room in browser UI state, defaulting to `merlin-build`,
- explicit "Save to Room" then "Allow once" clicks,
- local transcript history only.

Active Room selection is session-local in Wizard HQ. It is not persisted to
backend settings, does not enable Room context retrieval, and does not change the
reference policy. It only makes the selected Room visible as the explicit
transcript save target before the approval flow.

It does not save degraded/blocked responses, does not index the Room for future
context, does not approve Room Master Prompts for context reuse, does not persist
reference policy, and does not write approved memory.
It also does not delete, rename, or archive Rooms from chat yet.

The `approval_id` must come from the Task API approval lifecycle:

```text
POST http://localhost:8766/approvals/room-transcript
POST http://localhost:8766/approvals/{approval_id}/approve
POST http://localhost:8766/approvals/{approval_id}/deny
```

The approval request stores a redacted payload hash and Room/session metadata.
It does not store raw user input or raw Merlin response text. The transcript
save endpoint re-computes the payload hash and rejects approvals that are still
pending, denied, missing, already used, or bound to different transcript
content.

Current implementation also exposes an approval-gated local read path for
reopening saved chats:

```text
POST http://localhost:8766/approvals/room-transcript-read
POST http://localhost:8766/rooms/transcripts/read
```

This path requires a redacted `file_read` approval for the selected Room and
transcript id. Wizard HQ uses it when the user selects a saved Room transcript
from Room History and then clicks `Allow once`. The read endpoint returns only
the selected transcript's User and Merlin sections to the chat view. It does not
write memory, approve context reuse, index Room content, or share context across
Rooms. The approval is marked used after the local read, so Merlin asks again
next time.

Current implementation also exposes an approval-gated transcript delete path:

```text
POST http://localhost:8766/approvals/room-transcript-delete
POST http://localhost:8766/rooms/transcripts/delete
```

This path deletes one saved transcript/session inside a Room after a redacted
`file_delete` approval. It does not delete the Room folder, other transcripts,
Room Master Prompt drafts, approved memory, or any future linked context. The
approval is marked used after the local delete, so Merlin asks again next time.

Current implementation also exposes a separate approval-gated Room Master Prompt
draft path:

```text
POST http://localhost:8766/approvals/room-master-prompt
POST http://localhost:8766/rooms/master-prompt-drafts
```

The approval endpoint counts the current saved transcripts for the Room and
creates a redacted approval record with `file_write`. It does not include raw
transcript text. The draft endpoint requires an approved matching approval id,
verifies that the source transcript count did not change after approval
preparation, and writes:

```text
~/Merlin/brain/rooms/<room-id>/master-prompts/master-prompt.md
```

The draft file is local Markdown with frontmatter:

```yaml
status: draft
approved_for_context: false
memory_written: false
context_reuse: disabled_until_user_approved
```

This is a local draft only. It is not approved memory, it is not automatically
used as Room context, and it is not shared across Rooms. A future review screen
must let the user edit/approve it before Merlin may use it as scoped context.

## Runtime Work To Split

Before writable Room support ships, split #135 into implementation issues:

1. Room data model and local file schema.
2. Room picker and reference policy persistence.
3. Local index rebuild from Room Markdown files.
4. Memory proposal flow from transcript/summary.
5. Room Master Prompt generation and review flow.
6. Room Agent prompt contract for scoped context.
7. Prompt-based Room management intent parser.
8. Delete/archive Room with linked-memory and master-prompt warning.

## Out Of Scope

- Silent memory writes.
- Automatic cloud sync.
- Browser-side filesystem writes.
- Background indexing of arbitrary folders without approval.
- Native automation runtime.
- ClosClaw/web fetch behavior.

## Test Contract

Static and unit tests must verify:

- no silent memory write language,
- no default cloud sync,
- no browser execution controls,
- transcript and approved memory are distinct,
- reference policy is visible,
- change/write actions stay locked until backend gates exist.
