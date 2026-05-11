# Merlin AI Expansion Boundaries

Last verified: 2026-05-10
Status: Active product guardrail

This document replaces the older active "Merlin control plane" strategy. The
old direction was useful as exploration, but it made the repo sound like an
enterprise security platform before the consumer product was proven. The active
direction is simpler:

> Merlin AI is private AI on your Mac. Merlin is the assistant inside it.

## Current Product Wedge

The first product is for a privacy-conscious Mac owner who wants local AI to
work without becoming a developer.

The first-use loop must stay narrow:

1. Install Merlin AI.
2. Open the Merlin Dashboard.
3. Talk to Merlin.
4. Save a useful conversation into a local Room.
5. See where that Room lives on disk.
6. Approve what Merlin is allowed to remember.
7. Reopen or delete local history without cloud involvement.

Everything else is secondary until that loop feels inevitable.

## What Exists Today

- Protected installer, package, uninstall, and upgrade paths.
- Wizard HQ on `localhost:8888`.
- Merlin Chat with bounded in-session context.
- Local Rooms under `~/Merlin/brain/rooms`.
- Approval-gated local transcript save, reopen, and delete paths.
- Read-only status API on `localhost:8765`.
- Execution-aware task API on `localhost:8766`.
- Local-first model routing through Ollama/LiteLLM.
- Qdrant memory infrastructure with approval-gated memory writes.
- Failure-learning evidence process and Local Trusted Beta evidence pack.

## What Still Must Improve

- Merlin Chat should feel like the primary product, not a dashboard widget.
- Rooms need clean create/open/delete/reopen flows for nontechnical users.
- Saved transcripts should be easy to name, review, and remove.
- Approved memory review/delete must be visible in Wizard HQ.
- Storage location must be obvious and human-readable.
- The installer must lead to a clear first action after install.

## Do Not Sell Or Build Yet

Do not present Merlin AI as any of the following active products:

- an enterprise security platform,
- a compliance suite,
- an autonomous execution engine,
- a browser automation system,
- a multi-user administration platform,
- a provider marketplace,
- a public beta or public release.

Those may become future lines only after the local Merlin AI product earns trust
with real users, evidence, and clean install results.

## Deferred Expansion Order

Expansion is parked in [`FUTURE_IDEAS.md`](FUTURE_IDEAS.md). Nothing below is a
v1.0 commitment. Expansion is allowed only after the five v1.0 jobs are proven:

1. **Rooms and export/import.** Only after install/onboarding clearly work.
2. **Voice for Merlin.** Only after local audio consent is designed.
3. **Home Assistant.** Optional, after local trust works.
4. **Professional mode.** Local evidence for regulated solo users.
5. **Linux support.** After macOS first-use quality is stable.
6. **Supervised agents.** Suggest-only first, with explicit approval gates.

## Release Claims Rule

Current allowed claim:

> Merlin AI is a local-first private AI product in local-trusted-test
> hardening. Merlin runs inside it as the assistant, router, memory, and safety
> layer.

Forbidden current claims:

- Public Beta ready.
- Public Release ready.
- Fully autonomous.
- Cloud-free in every optional configuration.
- Compliance-ready.
- Enterprise-ready.

## Investor Sentence

Merlin AI is the missing bridge between "local AI exists" and "a normal Mac
owner can actually use it." Merlin is the face, memory, and safety layer that
makes the private local stack feel like a product instead of a pile of tools.
