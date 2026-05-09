# Merlin Rooms Architecture

**Status:** Current design contract for issue #135.
**Last updated:** 2026-05-09
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
| Index | A rebuildable local search cache over Room files. It is not the source of truth. |
| Approved memory | User-approved facts/preferences/context that Merlin may reuse across future sessions. |

## Boundary Rules

1. Chat history may be saved to a Room only through an explicit user flow.
2. A saved transcript does not become approved memory automatically.
3. Memory extraction follows propose -> stage -> approve/edit/deny -> write.
4. Room reference policy must be visible before Merlin uses Room context.
5. Room storage path must be visible.
6. Cloud/synced folders are treated as user-selected filesystem paths, not cloud
   inference.
7. Merlin must not silently index arbitrary folders.
8. Deleting a Room must show whether approved memories were derived from it.

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
      room.md
  memories/
  preferences.md
  merlin-brain.index
```

The Markdown files are the durable user-owned record. Any vector index is a
local cache that can be rebuilt.

## Wizard HQ Surface

Wizard HQ should show:

- active Room,
- Room storage path,
- Room reference policy,
- save-to-Room state,
- memory extraction state,
- delete/export status.

Read-only design state is acceptable until backend file, index, migration, and
audit paths are implemented.

## Runtime Work To Split

Before writable Room support ships, split #135 into implementation issues:

1. Room data model and local file schema.
2. Save chat transcript to Room through Task API policy gate.
3. Room picker and reference policy persistence.
4. Local index rebuild from Room Markdown files.
5. Memory proposal flow from transcript/summary.
6. Delete/archive Room with linked-memory warning.

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
