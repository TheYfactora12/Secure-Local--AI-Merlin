# Merlin AI Coding Master Prompt v2

**Status:** Current product/engineering operating prompt.
**Last verified:** 2026-05-10
**Repository:** `TheYfactora12/home-ai-elite`
**Product:** Merlin AI
**Control surface:** Wizard HQ, `localhost:8888`
**Read-only status API:** `localhost:8765`
**Execution-aware Task API:** `localhost:8766`

Use this after validating live GitHub issues, recent commits, CI status, and
`docs/CANONICAL_PROJECT_STATE.md`. If this file conflicts with live issue state
or canonical state, update this file or open a governance issue.

## Who Merlin Is

Merlin AI is a local-first, privacy-first AI brain for project work.

Product sentence:

> Merlin is the only AI that tells you exactly where your data is, what it
> remembers, and asks before it acts, while running on hardware you own.

Merlin is not:

- a ChatGPT wrapper,
- an enterprise governance suite today,
- an autonomous agent OS today,
- a pile of disconnected local AI tools,
- a public beta until evidence proves it.

Merlin is:

- a private AI command center,
- a local chat and context system,
- a user-owned memory and Room system,
- a governed approval layer for AI actions,
- a trustworthy alternative to throwing private work into cloud AI apps.

## Product Soul

Every build decision must support the current product core:

1. Merlin Chat is the primary user experience.
2. Rooms are local project/context containers.
3. Saved chat history is not the same as approved memory.
4. Merlin learns from approved memory extraction, not silent transcript mining.
5. Export/Import Brain makes the user's context portable and human-readable.
6. Providers, models, web comprehension, agents, and automation are supporting
   connectors. They wait unless they directly improve the chat/history/Rooms
   loop.

If a proposed change does not improve first install trust, Wizard HQ clarity,
local/private proof, controlled task flow, approval visibility, or Local Trusted
Beta evidence, defer it.

## Mythology Means Architecture

Use myth names only when they map to real controls.

| Myth name | Real component | Current status |
| --- | --- | --- |
| Merlin | Primary local AI assistant | Active |
| Realm | User's local stack and project environment | Active |
| Wizard HQ | Dashboard command surface | Active |
| Watchtower | Readiness and service health | Active |
| Gatehouse | Policy gates and access control | Active |
| Chronicle | Redacted audit/activity history | Active |
| Vault | Memory and context store | In progress |
| Rooms / Project Realms | Local chat/project context containers | #135 |
| Round Table | Approval and governance board | #133 |
| Knights | Scoped agents | Planned |
| Excalibur | High-risk execution authority | Future only |

Myth language must clarify the product for normal users. Always pair myth labels
with plain-language support text.

## Architecture Constraints

1. **Local first.** Cloud is opt-in. Never enable external providers, telemetry,
   remote access, or cloud sync by default.
2. **8765 is read-only.** Never add writes, execution, approvals, model calls, or
   shell/service controls to the status API.
3. **8766 is execution-aware and policy-gated.** Every write, mutation, model
   route, or privileged action must go through backend policy gates.
4. **No secret display.** API keys, tokens, passwords, and credentials are
   presence/status only. Backend may accept secrets only through explicit
   approved paths and must never return them.
5. **No silent memory writes.** Normal chat may save local transcript/history
   only when the product flow says so. Reusable Merlin memory requires
   propose -> stage -> approve/edit/deny -> write.
6. **No fake readiness.** Use Preparing, Starting, Warming, Ready, Degraded, and
   Failed. Never show Ready for a dependency that is unavailable or unknown.
7. **No browser-side shell execution.** Wizard HQ cannot run shell commands,
   start services, download models, write files, or approve gates directly.
8. **Mobile-first and accessible.** New UI must not depend on hover-only
   controls. Use labels plus color, ARIA labels, keyboard support, and respect
   reduced motion.
9. **Patent-sensitive files require care.** Do not alter patent anchor
   docstrings or named claim evidence without explicit instruction and tests.

## Current Issue Priorities

Live issue state is the source of truth. As of 2026-05-09, the focus stack is:

### Critical

- **#122 Product Focus Cut.** Prove the Local Trusted Beta wedge before feature
  expansion.
- **#123 Offline Local Brain + User-Owned Context Store.** User-owned context
  storage, local indexing, review/delete/export, and offline proof.

### High

- **#134 Product Value Checkpoint.** Prove the value demo or pivot/stop.
- **#106 Wizard HQ Product Shell.** Merlin-native Chat, Rooms, Brains, Memory,
  Agents, Security, System, and Settings.
- **#114 Policy-Gated Settings Backend.** Settings actions route through
  backend policy gates or remain disabled.
- **#130 Brain Storage Location UI.** Show where Merlin keeps its brain.
- **#135 Merlin Rooms.** Local chat history and scoped context containers.
  Current slices include default Room layout, transcript save, Room launcher,
  and Room Master Prompt drafts. Next: review/edit and approve-for-context.
- **#133 Round Table Architecture Doc.** Approval/governance model before broad
  agent work. Current spec exists; next runtime slice should be read-only UI
  only.
- **#129 Fast/Smart Model Selection UI.** No raw model config for normal users.
- **#31 and #32 Memory Approval + Delete Path.** Blockers for memory review and
  durable learning UX.

### Medium / Later

- **#124 and #125 Export/Import Brain.**
- **#126 Connector permission model.**
- **#127 PC task execution.**
- **#128 Agent definition and storage format.**
- **#121 ClosClaw web comprehension.** Future; no default network.
- **#92 / #111 MerlinFlow/native runtime.** Future.

## Do Not Build Until Product Proof Improves

- Enterprise governance suite claims.
- DLP/IDS/IPS/SIEM-grade blocking/reporting.
- Autonomous shell/file/network execution.
- Native MerlinFlow runtime.
- Multi-user enterprise RBAC.
- Provider marketplace.
- Broad agent autonomy.
- Public beta or investor language that outpaces evidence.
- ClosClaw/web browsing before Merlin Chat, Rooms, and memory review are useful.

## Governed Intelligence Made Visible

Merlin's UI advantage is that it shows trust controls instead of hiding them.
The user should be able to answer these from the UI:

- Where does my data live?
- What is Merlin doing right now?
- What did it just do?
- What is waiting for approval?
- Is cloud on or off?
- What does Merlin remember?
- Which agents/connectors are active and what can they do?

Trust is not a setting. Trust is the interface.

## Required UI Primitives

### Sovereignty Indicator

Visible on every Wizard HQ screen.

- `local`: Local Mode. No data leaving the machine.
- `cloud_bridge`: Cloud Bridge Active. User explicitly enabled it.
- `offline`: Offline or no model available. Degraded state.

The indicator must include label/icon text, not color alone.

### Honest Readiness

States:

```text
Preparing -> Starting -> Warming -> Ready -> Degraded -> Failed
```

Use real checks or documented degraded conditions. Never cover failure with a
generic spinner.

### Context Source Pill

Every response that uses local context, Room context, Vault memory, or an agent
should expose a subtle source line:

```text
Local | Vault | Room: Merlin Build
```

Click/tap opens lineage: what source was used, where it lives, and whether cloud
was used.

### Round Table Approval Card

Every memory write or privileged action should be understandable in one card:

```text
Scribe is requesting permission
"Save a memory: You prefer concise technical responses."
Stored to: ~/Merlin/Vault/preferences
Cloud: not used
[Approve] [Edit] [Deny]
```

Approve, edit, and deny must each write a Chronicle/audit record when the
backend flow exists.

## First-Run Flow To Build Toward

1. Where should I keep your brain?
2. What are you working on?
3. Create first Room / Project Realm.
4. Add one local note/file/folder.
5. Ask the first question.
6. Merlin answers with visible context source.
7. UI shows Local, No cloud used, and memory proposal state.

## Coding Protocol

Before coding, state:

```text
ISSUE:
FOCUS CRITERIA MET:
FILES TOUCHED:
ARCHITECTURE CONSTRAINTS VERIFIED:
PATENT-SAFE:
ROLLBACK:
```

Before merge/push, verify:

- no cloud defaults,
- no raw secrets in UI/logs/API responses,
- 8765 remains read-only,
- 8766 remains policy-gated,
- no silent memory writes,
- no fake readiness states,
- no browser-side shell execution,
- patent anchor docstrings untouched,
- accessible/mobile-first UI for new components,
- evidence note updated,
- focused tests and relevant CI smokes pass.

## Merlin UI Voice

Merlin is warm, direct, and truthful.

Use:

- "I'm warming up. Give me a moment before we start."
- "I learned something. Want me to remember it?"
- "Running locally. Your data stays on this machine."
- "Your connector is configured. Cloud remains off until you allow it."

Avoid:

- "Service unavailable."
- "Memory write requires approval."
- "Cloud provider not configured."
- "API key successfully stored."

## Response Shape For Merlin The Product

When the product answers users, prefer:

1. Bottom line.
2. Why it matters.
3. How to.
4. Tradeoffs.
5. Upgrade path.
6. Chronicle: what happened, context used, memory proposed yes/no.

Confidence must be visible:

- High: from approved context.
- Moderate: based on local Room/Vault context but not definitive.
- Low: reasoning only; verify before acting.

## Next Concrete Build Steps

1. Sovereignty Indicator in persistent Wizard HQ chrome.
2. Brain Storage Location UI (#130), read-only first.
3. Honest readiness states across Watchtower/System (#95/#106).
4. Memory approval flow (#31).
5. Memory delete/review path (#32/#120).
6. Merlin Chat first context path (#123).
7. Product value demo (#134).
8. Rooms review/edit path for Room Master Prompt drafts (#135).
9. Export/Import Brain (#124/#125).
10. Read-only Round Table panel (#133).

Do not skip ahead unless a live GitHub issue, security blocker, or user decision
explicitly changes the order.
