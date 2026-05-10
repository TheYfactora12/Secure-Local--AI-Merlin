# Merlin AI — Product North Star

**Version:** 1.1
**Date:** 2026-05-10
**Status:** CANONICAL — supersedes all prior positioning docs
**Change from v1.1:** Aligned active sprint with live v3.1 execution: Rooms,
Room Master Prompt review, approved memory review/delete, and storage-location
clarity come before PC control, broad connectors, or runtime agents.

---

## The One-Sentence Product

> Merlin is your personal AI that lives on your device, never forgets what you tell it, works on any computer or phone, does tasks and runs your apps for you — and never shares your data without permission.

Every build decision gets tested against that sentence.

---

## The Apple 1997 Lesson

When Steve Jobs returned to Apple in 1997, Apple had 350 products. He cut to 4.
Not because the other 346 were bad ideas — because **focus compounds** and complexity kills.

The product today is three things, in this order:

1. **An AI that remembers your life and never forgets.** (Phase 1)
2. **An AI that can do things on your computer and in your apps.** (Phase 2)
3. **An AI that travels with you across every device you own.** (Phase 2–3)

Everything else is deferred until these three are proven.

---

## Who This Is For

**Primary user:** Anyone who owns a laptop or phone and wants an AI that actually knows them, remembers their work, and can help them get things done — without their data leaving their machine.

The test user is not a DevOps engineer. The test user is:
- A grandmother who wants help without worrying her grandchildren will see her conversations.
- A student who wants an AI that remembers their projects across weeks and months.
- A professional who wants their work context to follow them device to device.
- A power user who wants Merlin to open apps, run tasks, and automate their day — under their control.

**If grandma can install it and use it on day one, we have the right product.**
If she needs a terminal, we failed.

---

## The Six Core Promises

### Promise 1 — It Just Works
- Install once. Double-click or one-command install.
- Opens to a clean chat UI. No errors. No warnings. No setup wizard maze.
- Within 3 minutes of install, Merlin is answering questions.
- Works on macOS today. Windows and Linux in Phase 2. Phone access in Phase 3.
- If a service is slow, Merlin says "warming up" — it does not show a broken screen.

### Promise 2 — It Never Forgets (Unless You Tell It To)
- Everything you tell Merlin goes into your personal context store.
- Your context is stored as readable `.md` files and a fast local vector index.
- Merlin can always search it, summarize it, and reference it.
- You choose where it lives: local folder, external drive, USB flash drive, synced folder.
- You can archive old context — it never gets deleted, just stored away.
- You can always come back and ask: *"What did we work on last month?"*

### Promise 3 — You Own It. Completely.
- No account required. No cloud by default. No telemetry by default.
- Your data never leaves your machine unless you choose to sync it.
- You control how much or how little security you want — one slider, not 40 checkboxes.
- **Trust Mode** (relaxed, Merlin acts fast) ↔ **Vault Mode** (Merlin asks before every action).
- You can see exactly what Merlin knows about you, and delete any of it at any time.

### Promise 4 — Secure Rooms (Projects)
- Chat is not one big pile. It is organized into Rooms.
- Each Room is a project, a topic, a person, or a purpose.
- Rooms keep their own context. Asking in "Work" doesn't bleed into "Family."
- Rooms can be exported as a folder of `.md` files — fully readable without Merlin.
- Rooms can be archived and reopened years later.

### Promise 5 — Export Brain / Import Brain
Full spec below. This is a first-class product feature, not a power user tool.

### Promise 6 — Merlin Does Things For You
- Merlin can run tasks, open apps, control your PC — under your supervision.
- Agents are opt-in. You approve what Merlin is allowed to do before it does anything.
- Connectors to apps and programs are always explicit, always secure, always removable.
- Full spec below.

---

## Promise 5 — Export Brain / Import Brain (Full Spec)

This is the feature that makes Merlin feel like it belongs to you, not to a server somewhere.

### The User Experience (What They See)

**Export Brain:**
1. User clicks "Export My Brain" — one button in Settings or the main sidebar.
2. Merlin shows a progress bar: "Packing your memories..."
3. When done: a single folder (or `.zip` file if preferred) is saved wherever the user wants.
   - Default: Desktop, named `Merlin-Brain-2026-05-09/`
   - User can also choose a USB flash drive, external drive, or any folder.
4. Merlin confirms: "Your brain is packed. 247 memories, 8 rooms, your preferences. Ready to move."
5. Done. No terminal. No config. No errors.

**Import Brain:**
1. User installs Merlin fresh on a new device.
2. First-run screen shows two options: **"Start Fresh"** or **"Import My Brain."**
3. User clicks Import, picks the exported folder or `.zip`.
4. Merlin shows a progress bar: "Rebuilding your memories..."
5. Index rebuilds from `.md` files automatically (under 2 minutes for typical brain size).
6. When done: Merlin opens to chat. First message: *"Welcome back. I remember you."*
7. All rooms, memories, and preferences are restored. No data lost.

**Mid-life import (adding a second device):**
- User can also import at any time via Settings → "Load Brain from Folder."
- Merlin merges the imported brain with any existing context, deduplicating by timestamp.
- User can preview what will be merged before confirming.

### What the Export Package Contains
```
Merlin-Brain-2026-05-09/
├── memories/
│   └── YYYY-MM-DD-topic.md          ← human-readable, always
├── rooms/
│   ├── work/
│   │   └── YYYY-MM-DD.md
│   └── family/
│       └── YYYY-MM-DD.md
├── preferences.md                   ← name, settings, Trust/Vault level
├── merlin-brain.index               ← vector index cache (rebuilt on import if missing)
└── MANIFEST.md                      ← version, export date, item count, import instructions
```

### Key Rules
- The `.md` files are the source of truth. The index is always rebuildable.
- The export package is readable by a human without Merlin. Open any `.md` file in any text editor.
- Export is always a full copy, never a diff. Diffs create merge complexity that breaks for non-technical users.
- The export is not encrypted by default. Users who want encryption can enable it in Vault Mode (AES-256, password of their choice). The password is never stored — if they forget it, the brain is unrecoverable. Merlin warns them clearly.
- `MANIFEST.md` always explains what the folder is and how to use it, in plain English. A user who finds the folder years later should be able to understand it without any help.

### Flash Drive Export (Special Case)
- If the user selects a USB drive as the destination, Merlin also copies the Merlin installer for their OS into a `/installer/` subfolder.
- This means the flash drive is fully self-contained: plug it into any machine → install Merlin from the drive → import brain from the same drive → done.
- No internet required for the transfer. No account. No cloud.

---

## Promise 6 — Merlin Does Things For You (Full Spec)

Merlin can be a thinking partner. It can also be a doing partner. The second role is Phase 2 — but it must be designed correctly from the start, because security trust is hard to retrofit.

### The Principle: Secure by Default, Capable by Choice

Merlin never touches your computer or apps without your permission.
The first time Merlin could do something on your machine, it asks:
*"I can help you with this. Want me to open Chrome and navigate to your calendar? Yes / No / Always ask"*

That permission is stored and can be revoked at any time from Settings → Permissions.

### What Merlin Can Do (Phase 2)

**On your PC (local task execution):**
- Open, close, or switch between applications
- Create, move, rename, or organize files and folders
- Run scripts or commands you have explicitly approved
- Fill forms, copy text, take screenshots on request
- Set reminders, alarms, or calendar events (via local calendar if available)
- Search your files by content ("find the document where I wrote about the budget")

**In your apps (connectors — opt-in only):**
- Calendar: read events, create events, set reminders
- Email: read summaries (no send without explicit approval every time)
- Browser: open URLs, search the web, summarize pages
- Local documents: read `.md`, `.txt`, `.pdf` files you point it to
- Music / media: play, pause, next track
- Custom connectors: user can install additional connectors from a verified list

**What Merlin will never do without explicit per-action approval:**
- Send any email or message
- Delete any file
- Make any purchase or payment
- Submit any form
- Execute any code it wrote itself (user must review and approve first)
- Connect to any new app or service not already in the approved list

### The Connector Security Model

Every connector is a named, auditable permission. The user sees them in Settings → Connectors as a simple list:

```
✅ Calendar         — reads and creates events         [Revoke]
✅ Browser          — opens URLs, searches web         [Revoke]
⬜ Email            — not connected                    [Connect]
⬜ File System      — not connected                    [Connect]
```

- Connecting requires one explicit user action (a toggle + confirm dialog).
- Every connector action is logged in the Activity Log (Settings → Activity).
- Revoking a connector immediately removes all related permissions. No restart needed.
- Connectors never share data with each other. Calendar data stays in Calendar context. Email data stays in Email context. There is no cross-connector data blending without user approval.

### Agents — The Smart Automation Layer

An Agent is a saved sequence of tasks Merlin can run on your behalf.
Example: "Every Monday morning, open my calendar, summarize the week's meetings, and save it to my Work room."

- Agents are always user-created, never automatically created by Merlin.
- Every Agent has a plain-English description of what it does before it runs.
- Every Agent requires at least one approval the first time it runs on a new device.
- Agents are stored as `.md` files in the brain — human-readable, editable, deletable.
- In Trust Mode: approved agents run without asking each time.
- In Vault Mode: every agent run requires a one-tap approval.

### Offline-First Intelligence

Merlin's core capability — memory, reasoning, task planning — must work fully offline.

- The base model runs on-device (quantized, 8GB-friendly tier for Phase 1).
- Cloud AI providers (OpenAI, Anthropic, etc.) are optional accelerators, not dependencies.
- If cloud is configured and available, Merlin can route complex requests there.
- If offline, Merlin uses the local model and tells the user: "Running locally — some complex tasks may be slower."
- Local model choice is surfaced simply: "Fast (smaller model)" or "Smart (larger model, needs more RAM)."
- No model download or configuration is required at install time — a capable default ships with Merlin.

---

## Platform Roadmap

| Phase | Deliverable | Gate to Enter |
|---|---|---|
| **Phase 1** | macOS: install → chat → memory → no errors | 10 non-technical testers, 8/10 succeed without help |
| **Phase 1** | Export Brain / Import Brain (button, no terminal) | Tested: export → wipe → import → full restore in <2 min |
| **Phase 2** | Windows + Linux install | macOS stable, 50+ real testers |
| **Phase 2** | PC control + connectors (Calendar, Browser, Files) | Context store proven 30+ days, connector security model reviewed |
| **Phase 2** | Agents (user-created, saved task sequences) | Connectors working, permission model audited |
| **Phase 3** | Phone (web access to local Merlin) | Desktop Phase 2 complete |
| **Phase 4** | Native mobile app | Phone web access has 90-day data |
| **Phase 5** | Cross-device real-time sync | Context store format stable + versioned |

**Rule:** Do not begin a phase until its gate is proven, not just coded.

---

## The Context Store — The Heart of the Product

The entire product depends on this working perfectly. Nothing else matters if this is broken.

### What it must do
- Store everything the user explicitly tells Merlin.
- Store it as human-readable `.md` files (user's data survives even if Merlin stops existing).
- Index it locally so Merlin can search it fast (target: under 300ms for typical queries).
- Never delete anything without an explicit user action.
- Support archiving: move old context out of active search without destroying it.
- Support Export Brain / Import Brain (full spec above).
- Rebuild the vector index automatically from `.md` files if the index is missing or corrupted.

### What it must NOT do
- Never write to the store silently (no automatic learning without approval).
- Never send context to any cloud service without explicit user action.
- Never require the user to understand vector databases, embeddings, or indexing.
- Never show raw technical errors to a non-technical user.

### Storage Locations (User's Choice)
- Default: `~/Merlin/brain/` on local machine.
- Custom folder: user picks any folder during setup.
- External drive: user picks a folder on any connected drive.
- Synced folder: user points to an existing OneDrive/Dropbox/iCloud path — Merlin treats it as a local folder.
- Flash drive: full self-contained export including installer.

### File Format
- Memories: `memories/YYYY-MM-DD-topic.md`
- Room context: `rooms/[room-name]/YYYY-MM-DD.md`
- Preferences: `preferences.md`
- Agent definitions: `agents/[agent-name].md`
- Connector permissions: `connectors/permissions.md`
- Index: local vector index (Qdrant or equivalent) alongside the `.md` files.
- The `.md` files are the source of truth. The index is always a rebuildable cache.

---

## The Install Experience — Non-Negotiable Standard

1. User downloads one installer file (`.dmg` on Mac, `.exe` on Windows eventually).
2. User double-clicks. Progress bar. No terminal. No Docker commands.
3. Installer sets up all services in background.
4. When done: browser opens to `localhost:8888` — Merlin chat is ready.
5. First screen shows two options: **"Start Fresh"** or **"Import My Brain."**
6. If Start Fresh: clean chat. *"Hi, I'm Merlin. What's your name?"* Context store goes live on first reply.
7. If Import Brain: user picks their export folder. Merlin restores in under 2 minutes.
8. No errors. No warnings. No service health panels on first launch.
9. System Doctor runs silently. If something is wrong, a small amber dot appears — not a wall of red text.

**The test:** Hand the installer to someone who has never used a terminal. They should be in a working, personalized chat within 5 minutes.

---

## Security — Simplicity First, Depth for Those Who Want It

### Default (Trust Mode)
- Merlin runs locally. Context stored locally. No cloud. No telemetry.
- No approval popups for routine chat and memory actions.
- Agent and connector actions still log to Activity Log silently.

### Optional (Vault Mode)
- Approval gate on every memory write.
- Approval gate on every connector action.
- Approval gate on every agent run.
- Full Activity Log visible and exportable.
- Per-Room privacy levels.
- Optional AES-256 brain encryption (user sets password — not stored by Merlin).

### The Slider
```
[Trust Mode] ←————————————————→ [Vault Mode]
 Less friction                   More control
Merlin acts fast          Merlin asks before acting
```
One setting. Power users can still configure individual gates after choosing a mode.

---

## What We Are Cutting (Deferred, Not Deleted)

These are real ideas. They go into `docs/product/FUTURE_IDEAS.md`.

| Idea | Why Deferred |
|---|---|
| DLP / data loss prevention gates | Needs Phase 2 connector model first |
| IDS/IPS-style anomaly detection | Needs 90+ days of real usage data |
| SIEM-grade governance reporting | Needs Phase 2 control plane first |
| Enterprise RBAC / multi-user | Not target user yet |
| MerlinFlow native workflow runtime | n8n proves the case first |
| Provider marketplace | Needs stable connector model first |
| Native mobile app | Web phone access proves demand first |
| Patent public claims in product copy | Keep internal until provisionals filed |

---

## Active Sprint Issues

**Core build — stay in sprint:**
- #31, #32 — Memory approval + delete (Promise 2 foundation)
- #123 — Offline brain + context store (the product's heart)
- #106 — Wizard HQ product shell (Promise 1 front door)
- #114, #117, #119 — Settings and security controls (Promise 3)
- #95 — Product audit (gate for any public beta)

**Current v3.1 product-core order:**
- #135 — Finish Rooms: Room Master Prompt review/edit, approve-for-context, and
  no cross-Room sharing by default.
- #31, #32, #120 — Memory approval, review, and delete.
- #130 — Brain/context storage location UI, read-only first.
- #123, #134 — Prove the local brain value demo before expanding scope.

**Already tracked, after product proof improves:**
- #124, #125 — Export/Import Brain.
- #126 — Connector permission model + Settings UI.
- #127 — PC task execution first actions.
- #128 — Agent definition + storage format.
- #129 — Offline model selection ("Fast" / "Smart") UI.

**Parallel track — never blocks product:**
- #81, #82, #83, #84 — Patent anchors

---

## Decision Rules

Before any new issue is opened or feature prioritized, ask:

1. Does this help Merlin remember better? → **Build it.**
2. Does this make install easier for a non-technical user? → **Build it.**
3. Does this let users export or import their brain easily? → **Build it now.**
4. Does this let Merlin do tasks on the user's machine, with permission? → **Design it, but do not build runtime execution until Rooms, memory review/delete, and connector permissions are proven.**
5. Does this let the user control their data and security simply? → **Build it.**
6. Does this add complexity the user has to manage? → **Defer it.**
7. Does this require the user to understand infrastructure? → **Defer it.**
8. Is this a governance/enterprise/DLP feature? → **Defer until Phase 3 at earliest.**
9. Does this serve the patent IP track? → **Parallel track. Never blocks product.**

---

## What Success Looks Like

### End of Phase 1
- Non-technical user installs Merlin on a Mac in under 5 minutes, zero errors.
- User tells Merlin their name, job, and one project. Closes laptop. Opens next day. Merlin remembers all three.
- User finds an old conversation by asking: *"What did we talk about last week?"*
- User clicks "Export My Brain," picks their Desktop, and sees a readable folder of `.md` files.
- User wipes Merlin, reinstalls, imports brain, and is back in under 2 minutes — no data lost.
- 10 non-technical testers complete all of the above without help. 8/10 succeed on first try.

### End of Phase 2
- Merlin installs on Windows and Linux with the same experience as macOS.
- User connects Calendar and Browser connectors with two taps.
- User asks Merlin to open an app, create a file, or search their documents — Merlin does it.
- User creates one saved Agent. It runs reliably. User can see what it did in Activity Log.
- Vault Mode user sees every action logged. They can revoke any connector in one tap.
- Flash drive export works: plug into a new machine, install from drive, import brain — done.

---

## The Market Opportunity

Every major AI tool today — ChatGPT, Claude, Gemini, Perplexity — has the same flaw: **it forgets you the moment you close the tab.**

People paste `context.txt` files into every new chat session. That is a product gap the size of a market.

The person who builds a personal AI that genuinely remembers, lives on your device, does things for you, and travels with you on a flash drive — owns the most durable position in consumer AI.

Not because of enterprise governance. Because **memory is personal, capability is practical, and ownership is the new privacy**.

Merlin's defensible position:
- Your AI. Your data. Your device. Your rules.
- It works fully offline.
- It never forgets unless you tell it to.
- It does things for you — with your permission, under your control.
- It travels with you on a flash drive.
- Grandma can install it.

---

*This document is the product north star. If a decision conflicts with it, update this document first — with a reason and a date — before proceeding.*
