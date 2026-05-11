# Merlin AI — Product North Star

**Version:** 1.5
**Date:** 2026-05-10
**Status:** CANONICAL — supersedes all prior positioning docs

## One Sentence

> Download one file, run it, and in 30 minutes you have a fully private AI
> running on your Mac that you own forever. If you ever want it gone, one click
> removes everything.

Every product, engineering, design, and release decision must support this
sentence. If it does not, it is not v1.0 work.

## Product Identity

**Merlin AI** is the product the customer installs and buys.

Merlin is the visible assistant and internal brain inside Merlin AI:
chat, voice later, local memory, routing, safety checks, and plain-English
status.

The repo name is `TheYfactora12/Secure-Local--AI-Merlin`, but the user promise
is Merlin AI with Merlin inside.

## v1.0 Must Do Only Five Things

These are the only v1.0 jobs. Every feature either serves one of these or gets
cut from v1.0.

### 1. Install Everything In One Shot

- User runs one command or double-clicks one file.
- Core services come up automatically.
- The user does not need Docker knowledge or terminal expertise.
- Target: under 30 minutes on a clean Apple Silicon Mac.
- Installer behavior must stay idempotent, auditable, and reversible.

### 2. Tell The User It Worked

- After install, the user sees a clear first-run screen:
  "Your private AI is ready."
- Wizard HQ explains what each service does in plain English.
- The user is pointed to the first safe action: ask Merlin a local question.
- No user should land on a blank Open WebUI and wonder what happened.
- This is the biggest current product gap.

### 3. Keep Everything Private

- Zero data leaves the machine by default.
- No cloud account is required.
- No API key is required to get started.
- Local models run on owned hardware.
- External providers, telemetry, remote access, and cloud sync are opt-in only.
- Privacy must be enforced by architecture, not just copy.

### 4. Recover Gracefully When Something Breaks

- If a service fails, the user sees plain English:
  what broke, why it matters, and what to do next.
- No silent failures.
- No raw Docker error dump as the primary user experience.
- A failure report should be generated so Merlin, Codex, or a support person can
  diagnose the issue quickly.
- Every repeated failure must improve a smoke test, runbook, troubleshooting
  note, or follow-up issue.

### 5. Uninstall Cleanly

- One command or one click removes Merlin AI.
- Containers, volumes, configs, launch agents, local app files, and downloaded
  pieces are removed when the user chooses a full purge.
- The user can trust installation because they can undo installation.
- Uninstall behavior is protected and must be tested before release claims.

## What v1.0 Is Not

v1.0 is not:

- an enterprise governance platform,
- a compliance suite,
- an autonomous execution engine,
- a browser automation product,
- a provider marketplace,
- a multi-user administration product,
- a public beta or public release.

Those ideas stay deferred until the five v1.0 jobs are proven by evidence.

## Current Priority Order

1. Installer and package evidence.
2. Post-install onboarding and Wizard HQ first action.
3. Local-only privacy proof and no-cloud-default checks.
4. Human-readable recovery and failure learning loop.
5. Full uninstall / purge validation.
6. Everything else goes to [`FUTURE_IDEAS.md`](FUTURE_IDEAS.md) until these
   five jobs are proven.

## Decision Rules

Before work starts, ask:

1. Does this make install easier for a nontechnical Mac user?
2. Does this make the first-run result obvious?
3. Does this make privacy local-by-default stronger or clearer?
4. Does this make failure recovery easier?
5. Does this make uninstall more trustworthy?

If the answer is no to all five, defer it.

## What Success Looks Like

For v1.0:

- A nontechnical person installs Merlin AI on a clean Mac in under 30
  minutes.
- The first screen tells them their private AI is ready and what to do next.
- They can ask Merlin a local question without creating any cloud account.
- If something is degraded, the product explains it in plain English.
- They can uninstall or purge everything without hunting through the system.

## Investor Framing

The market does not need another local AI toolkit. It needs the missing bridge
between "local AI exists" and "a normal person can use private AI at home."

Merlin AI is that bridge. Merlin is the assistant that makes the local stack
feel alive, understandable, and owned.
