# Merlin AI — Product North Star

**Version:** 1.0  
**Date:** 2026-05-09  
**Status:** CANONICAL — supersedes all prior positioning docs  
**Author:** Product Direction Audit

---

## The One-Sentence Product

> Merlin is your personal AI that lives on your device, never forgets what you tell it, works on any computer or phone, and never shares your data without permission.

That sentence must be true on day one. Every build decision gets tested against it.

---

## The Apple 1997 Lesson

When Steve Jobs returned to Apple in 1997, Apple had 350 products. He cut to 4.
Not because the other 346 were bad ideas — because **focus compounds** and complexity kills.

Merlin has the same problem right now:
- IDS/IPS, DLP, SIEM-grade reporting, enterprise RBAC, MerlinFlow native runtime,
  autonomous agents, patent-heavy public claims, governance suites, observability stacks.

All of those are **real ideas**. None of them is the product **today**.

The product today is one thing:

> **An AI that lives on your device, remembers your life, and is yours alone.**

---

## Who This Is For

**Primary user:** Anyone who owns a laptop or phone and is frustrated that every AI they talk to forgets them the moment they close the app.

The test user is not a DevOps engineer. The test user is:
- A grandmother who wants to ask questions without worrying her grandchildren will see.
- A student who wants an AI that remembers their projects across weeks.
- A professional who wants their work context to follow them from laptop to phone.
- Someone who just wants it to work — no Docker knowledge, no ports, no `.env` files.

**If grandma can install it and use it on day one, we have the right product.**  
If she needs a terminal, we failed.

---

## The Five Core Promises

These are the only things Merlin must deliver before any other feature is touched.

### Promise 1 — It Just Works
- Install once. Double-click or one-command install.
- Opens to a clean chat UI. No errors. No warnings. No setup wizard maze.
- Within 3 minutes of install, Merlin is answering questions.
- Works on macOS today. Windows and Linux in the next milestone. Phone access after that.
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
- You control how much or how little security you want — from fully open to fully locked.
- Simple slider concept: **Trust Mode** (relaxed, fewer confirmations) ↔ **Vault Mode** (every action approved).
- You can see exactly what Merlin knows about you, and delete any of it at any time.

### Promise 4 — Secure Rooms (Projects)
- Chat is not one big pile. It is organized into Rooms.
- Each Room is a project, a topic, a person, or a purpose.
- Rooms keep their own context. Asking in "Work" doesn't bleed into "Family".
- Rooms can be exported as a folder of `.md` files — fully readable without Merlin.
- Rooms can be archived and reopened years later.

### Promise 5 — Your Brain Travels With You
- Your entire Merlin context (memories, rooms, preferences) can be exported to a USB flash drive.
- Plug it into a new device, install Merlin, import — and your AI picks up exactly where it left off.
- Same for phone access: when the phone app exists, it reads from the same context store.
- Context sync across devices is always explicit, never automatic without your action.
- Long-term: encrypted context package that travels with you across any device, any OS.

---

## Platform Roadmap (What Order, What Matters)

| Phase | Platform | Gate to Enter |
|---|---|---|
| Phase 1 (Now) | macOS | Clean install → chat works → context saved → no errors |
| Phase 2 | Windows, Linux | macOS version is stable and shipped to 50+ testers |
| Phase 3 | Phone (web access to local Merlin) | Desktop version has context store proven for 30+ days |
| Phase 4 | Native mobile app | Phone web access has 90-day real-world usage data |
| Phase 5 | Cross-device sync + flash drive export | Context store format is stable and versioned |

**Rule:** Do not begin Phase 2 until Phase 1 is provably working for non-technical users.

---

## The Context Store — The Heart of the Product

This is the single most important technical component. Everything else is secondary.

### What it must do
- Store everything the user explicitly tells Merlin.
- Store it as human-readable `.md` files (so the user never loses their data even without Merlin).
- Index it locally so Merlin can search it fast (under 500ms for typical context lookups).
- Never delete anything without an explicit user action.
- Support archiving: move old context out of active search without destroying it.
- Support export: one command or one button packages the entire context store.
- Support import: on a new device, import restores full context in under 2 minutes.

### What it must NOT do
- Never write to the store silently (no automatic learning without approval).
- Never send context to any cloud service without explicit user action.
- Never require the user to understand vector databases, embeddings, or indexing.
- Never show raw technical errors to a non-technical user.

### Storage Locations (User's Choice)
- Default: `~/Merlin/brain/` on local machine.
- Custom folder: user picks any folder during setup.
- External drive: user picks a folder on connected drive.
- Synced folder: user points to a OneDrive/Dropbox/iCloud folder path (Merlin treats it as a local folder — no special integration needed).
- Flash drive export: full packaged export for device transfer.

### File Format
- Memories: `memories/YYYY-MM-DD-topic.md`
- Room context: `rooms/[room-name]/YYYY-MM-DD.md`
- Preferences: `preferences.md`
- Index: local vector index (Qdrant or equivalent) alongside the `.md` files.
- The `.md` files are the source of truth. The index is a cache that can always be rebuilt.

---

## The Install Experience — Non-Negotiable Standard

This is the product's first impression. It must be flawless.

1. User downloads one installer file (`.dmg` on Mac, `.exe` on Windows eventually).
2. User double-clicks. Progress bar. No terminal. No Docker commands.
3. Installer sets up all services in background.
4. When done: browser opens to `localhost:8888` — Merlin chat is ready.
5. First screen: clean chat input. One line of onboarding: *"Hi, I'm Merlin. What's your name?"*
6. User types their name. Merlin saves it. **Context store is live from this moment.**
7. No errors. No warnings. No service health panels on first launch.
8. System Doctor runs silently. If something is wrong, a small amber dot appears — not a wall of red.

**The test:** Hand the installer to someone who has never used a terminal. They should be in a working chat within 5 minutes.

---

## Security — Simplicity First, Depth for Those Who Want It

The security model must not be the first thing the user sees. But it must be real and accessible.

### Default (Trust Mode)
- Merlin runs locally. Context stored locally. No cloud. No telemetry.
- User does not need to configure anything to be safe.
- No approval popups for routine actions.

### Optional (Vault Mode)
- User can turn on approval gates for any memory write.
- User can require confirmation before Merlin uses a cloud provider.
- User can see a full log of everything Merlin has done.
- User can set per-Room privacy levels.

### The Slider Concept
One setting. Not 40 checkboxes.
```
[Trust Mode] ←————————————————→ [Vault Mode]
 Less friction                   More control
Merlin acts fast          Merlin asks before acting
```
Power users who want granular control can still configure individual gates — but the default UI is one slider.

---

## What We Are Cutting (Deferred, Not Deleted)

These are real ideas. They go into `docs/product/FUTURE_IDEAS.md`. They do not get built until the 5 Core Promises are provably delivered.

| Idea | Why Deferred |
|---|---|
| DLP / data loss prevention gates | Requires the control plane to exist first |
| IDS/IPS-style anomaly detection | Requires 90+ days of real usage data |
| SIEM-grade governance reporting | Requires the control plane to exist first |
| Enterprise RBAC / multi-user | Not the target user yet |
| MerlinFlow native workflow runtime | Requires proven n8n replacement case |
| Autonomous agent execution | Trust must be earned before autonomy is granted |
| Provider marketplace | Requires stable provider connector model first |
| Native mobile app (Phase 4) | Web phone access must prove demand first |
| Patent public claims in product copy | Keep IP work internal until provisionals filed |
| AI firewall product positioning | Over-claim; earn the trust layer first |

---

## Issue Audit — Cut List

The following open issues are valid long-term but must be re-labeled `deferred` and removed from active sprint consideration until Phase 1 is complete:

- #107 (DLP + Prevention Gates)
- #104 (Monitoring IDS Signals + Drift)
- #112 (Governance Reporting + Evidence)
- #111 (MerlinFlow Native Runtime)
- #92 (Native Automation Runtime)
- #121 (ClosClaw web comprehension connector)

The following open issues are **active and stay in sprint**:

- #31, #32 (Memory approval + delete — foundation of Promise 2)
- #123 (Offline local brain + context store — this IS the product)
- #122 (Product focus cut — confirmed by this doc)
- #106 (Wizard HQ product shell — Promise 1 front door)
- #114, #117, #119 (Settings — needed for Promise 3 security controls)
- #95 (Product audit — must complete before any public beta)
- #81, #82, #83, #84 (Patent — time-sensitive, parallel track, not a product delay)

---

## The Market Opportunity

This is stated once, plainly, without hype.

Every major AI tool today — ChatGPT, Claude, Gemini, Perplexity — has the same flaw:
**it forgets you the moment you close the tab.**

People have started keeping their own `context.txt` files, pasting them into every new chat session. That is a product gap the size of a market.

The person who builds **a personal AI that genuinely remembers, lives on your device, and travels with you** — across devices, across years — owns the most durable position in consumer AI.

Not because of enterprise governance. Not because of DLP. Because **memory is personal**, and personal things belong to the person, not the platform.

Merlin's defensible position:
- Your AI. Your data. Your device. Your rules.
- It works offline.
- It never forgets unless you tell it to.
- It travels with you on a flash drive if needed.
- Grandma can use it.

That is the product. Build that first.

---

## Decision Rules Going Forward

Before any new issue is opened or any feature is prioritized, ask:

1. Does this help Merlin remember better? → **Build it.**
2. Does this make install easier for a non-technical user? → **Build it.**
3. Does this make the product work on more devices? → **Build it (in platform order).**
4. Does this let the user control their data more simply? → **Build it.**
5. Does this make the product more complex for the user? → **Defer it.**
6. Does this require the user to understand infrastructure? → **Defer it.**
7. Is this a governance/enterprise/DLP feature? → **Defer it until Phase 3 at earliest.**
8. Does this serve the patent IP track? → **Parallel track. Never blocks product.**

---

## What Success Looks Like at End of Phase 1

- Non-technical user installs Merlin on a Mac in under 5 minutes, zero errors.
- Merlin opens to a clean chat. No terminal required.
- User tells Merlin their name, job, and one project. Merlin saves it.
- User closes laptop. Opens it next day. Merlin remembers all three things.
- User can find an old conversation by asking: *"What did we talk about last week?"*
- User can export their entire brain to a folder and see readable `.md` files.
- User can set Trust Mode or Vault Mode with one setting.
- 10 non-technical testers complete this without help. 8 out of 10 pass on first try.

When that evidence exists, Phase 2 begins.

---

*This document is the product north star. If a decision conflicts with it, update this document first — with a reason — before proceeding.*
