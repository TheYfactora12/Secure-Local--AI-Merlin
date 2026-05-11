# Merlin AI Master Reset Prompt v3.0

May 2026 | Codex Session Anchor

## Product

Merlin AI is a one-click macOS installer that gives anyone a fully private,
locally-running AI stack on Apple Silicon with no cloud account, no
subscription, and no terminal knowledge required after setup.

Tagline: **Your private AI. On your Mac. Forever.**

Product name: **Merlin AI**.

Assistant persona: **Merlin**.

## Session Mission

This session is cleanup, validation, and release-readiness alignment.

Do:

1. Keep docs, UI, installer copy, and tests aligned to Merlin AI.
2. Validate installer/package/dashboard/docs smokes.
3. Triage GitHub issues against the v1.0 focus.
4. Document current state honestly.
5. Record failures and what the project learned.

Do not:

- add new product features,
- enable cloud defaults,
- add telemetry,
- change installer/uninstall behavior without focused tests,
- claim public beta or public release,
- revive future governance/agent/runtime work as v1.0 scope.

## Five v1.0 Focus Areas

1. **Install that just works.**
   A non-technical person on a fresh Mac runs one command or package install and
   the local stack comes up in under 30 minutes.
2. **Privacy that is architecturally enforced.**
   No cloud account, API key, external model call, analytics, or telemetry is
   required by default.
3. **Onboarding that removes confusion.**
   The first screen says Merlin AI is running, shows service status in plain
   English, and gives three clear actions.
4. **Uninstall that builds trust.**
   The user can remove app files and can explicitly purge local data, images,
   and Merlin-managed model downloads.
5. **Open source credibility.**
   A contributor can clone the repo, read the README, run smoke tests, and
   understand the product state quickly.

Anything else goes to `docs/product/FUTURE_IDEAS.md`.

## Current Repo Truth

- GitHub repository: `TheYfactora12/Secure-Local--AI-Merlin`.
- Canonical state file: `docs/CANONICAL_PROJECT_STATE.md`.
- Roadmap: `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`.
- Product north star: `docs/product/PRODUCT_NORTH_STAR.md`.
- Expansion boundary: `docs/product/MERLIN_AI_EXPANSION_BOUNDARIES.md`.

## Protected Areas

- `install.sh`
- `pkg/`
- `pkg/scripts/`
- `scripts/doctor.sh`
- `scripts/uninstall*`
- `launchd/`
- `.github/workflows/`
- privacy defaults
- model-pull defaults
- uninstall/purge behavior

## Quality Gate

Before calling work complete, run or explain why skipped:

```bash
git diff --check
bash -n install.sh
bash install.sh --help
bash tests/installer-branding-smoke.sh
bash tests/pkg-readiness-smoke.sh
bash tests/uninstall-smoke.sh
bash tests/release-readiness-readme-smoke.sh
```

If a failure happens, stop broad implementation, preserve output, classify the
failure, make the smallest scoped fix, retest, and update the evidence note.

## Decision Filter

Would a non-technical person on a fresh Mac smile and say, "this just works"?

If yes, build or keep it.

If no, simplify it, defer it, or write the issue.
