# Canonical Project State — Merlin AI

Last updated: 2026-05-10

## Current Truth

Merlin AI is the official product name.

Merlin is also the assistant persona inside the local stack.

Tagline: **Your private AI. On your Mac. Forever.**

Repository currently resolves to:
`TheYfactora12/Secure-Local--AI-Merlin`.

## Source Of Truth Order

1. GitHub issues and milestones
2. Recent commits and CI status
3. This file
4. `docs/MASTER_CONTEXT.md`
5. `docs/MASTER_PROMPT.md`
6. `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
7. Product, architecture, security, engineering, and IP docs
8. Archive docs as history only

## v1.0 Product Focus

v1.0 work is limited to five outcomes:

1. Install that just works.
2. Privacy that is enforced by default.
3. Onboarding that removes confusion.
4. Uninstall that builds trust.
5. Open source credibility.

Rooms, voice, Home Assistant, Linux, Windows, professional mode, connectors,
advanced agents, and native automation runtime are future unless they directly
support those five outcomes.

## Active Queue

1. Brand/docs reset to Merlin AI.
2. README and roadmap cleanup.
3. Installer, package, dashboard, and docs smoke validation.
4. Issue triage against the v1.0 focus.
5. Evidence note update.

## Protected Areas

- `install.sh`
- `pkg/`
- `pkg/scripts/`
- `scripts/doctor.sh`
- `scripts/uninstall*`
- `launchd/`
- `.github/workflows/`
- local-first privacy defaults
- no-surprise model-pull defaults
- uninstall/purge behavior

Protected areas can be edited only for verified defects or required branding
cleanup with focused smoke tests.

## Release Claim

Allowed: Merlin AI is preparing for controlled local testing.

Not allowed: public beta, public release, compliance-ready, enterprise-ready,
fully autonomous, or cloud-free in every optional configuration.

## Current Navigation

| Document | Purpose |
|---|---|
| [`README.md`](../README.md) | New contributor and user entry point |
| [`docs/MERLIN_IMPLEMENTATION_ROADMAP.md`](MERLIN_IMPLEMENTATION_ROADMAP.md) | v1.0 milestone ladder |
| [`docs/product/PRODUCT_NORTH_STAR.md`](product/PRODUCT_NORTH_STAR.md) | Product decision filter |
| [`docs/product/FUTURE_IDEAS.md`](product/FUTURE_IDEAS.md) | Parking lot for non-v1.0 ideas |
| [`docs/product/MERLIN_AI_EXPANSION_BOUNDARIES.md`](product/MERLIN_AI_EXPANSION_BOUNDARIES.md) | Guardrail against scope drift |
| [`docs/operations/FAILURE_LEARNING_LOOP.md`](operations/FAILURE_LEARNING_LOOP.md) | Failure learning protocol |
| [`docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`](operations/TRUSTED_LOCAL_BETA_EVIDENCE.md) | Evidence/runbook path |

## Next Decision

After this reset, the next build slice should be the smallest missing v1.0 gap
found by tests: onboarding clarity, installer recovery, or uninstall proof.
