# Merlin AI Implementation Roadmap

Last updated: 2026-05-10

## Product Direction

Merlin AI is a one-click macOS installer that gives anyone a fully private,
locally-running AI stack on Apple Silicon with no cloud account, no
subscription, and no terminal knowledge required after setup.

Tagline: **Your private AI. On your Mac. Forever.**

## v1.0 Scope

v1.0 has exactly five focus areas:

1. **Install that just works.** One command or one package install brings the
   local stack up on a clean Apple Silicon Mac.
2. **Privacy architecturally enforced.** No cloud account, API key, telemetry,
   analytics, or external model call is required by default.
3. **Onboarding that removes confusion.** The first screen says Merlin AI is
   running, shows service status in plain English, and gives three actions:
   chat, automate, or view status.
4. **Uninstall that builds trust.** One command removes app files and can purge
   local data, images, and Merlin-managed model downloads when the user chooses.
5. **Open source credibility.** A new contributor can clone the repo, read the
   README, run smoke tests, and understand the current state quickly.

Anything else is future unless it directly improves one of those five jobs.

## Milestone Ladder

| Stage | Scope |
|---|---|
| v1.0 | Install, privacy, onboarding, recovery, uninstall, open-source clarity |
| v1.5 | Voice input and auto-update/version notification |
| v2.0 | Home Assistant integration and Linux support |
| v2.5 | Windows support and iOS companion app |
| Future | Rooms depth, export/import brain, advanced agents, professional mode, native automation runtime |

## Active Work

1. Finish this Merlin AI reset: branding, README, roadmap, tests, evidence.
2. Validate `install.sh` and package smokes without changing protected behavior
   unless a verified defect exists.
3. Triage GitHub issues so v1.0 only contains the five focus areas.
4. Document every failure in the evidence note and update a test, runbook, or
   follow-up issue when needed.

## Deferred Work

Deferred ideas live in:

- [`docs/product/FUTURE_IDEAS.md`](product/FUTURE_IDEAS.md)
- [`docs/product/MERLIN_AI_EXPANSION_BOUNDARIES.md`](product/MERLIN_AI_EXPANSION_BOUNDARIES.md)

Do not sell or build Merlin AI as an enterprise governance suite, autonomous
execution engine, browser automation product, provider marketplace, or public
release until v1.0 evidence proves the core local product.

## Protected Rules

- Do not enable cloud behavior by default.
- Do not add telemetry.
- Do not add surprise model downloads.
- Do not weaken `HOME_AI_SKIP_MODEL_PULLS=true`.
- Do not change uninstall behavior without smoke tests.
- Do not claim public beta or public release without clean install evidence.
- Do not treat future roadmap ideas as active sprint commitments.
