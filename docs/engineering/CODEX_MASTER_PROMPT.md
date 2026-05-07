# Codex Master Prompt

Last updated: 2026-05-06

Read this with `docs/MASTER_CONTEXT.md` before implementation.

## Current Rule

Do not solve a stale prompt without checking what is already built. Read the current files, current issue state, and recent SHAs first.

## Non-Negotiables

- Protect the installer.
- Keep changes small and reviewable.
- No cloud calls by default.
- No automatic model downloads.
- No hardcoded secrets.
- No raw user input in logs.
- Memory writes require approval.
- `documents` remains 1536d; canonical Merlin collections remain 768d.
- n8n remains optional workflow automation, not the primary Merlin brain.
- Port 8765 stays read-only; port 8766 owns task/status panels.

## Current v2.0 State

- #60 staff router integration is closed.
- #53 session memory bridge adds `n8n-workflows/06-session-memory-bridge.json`.
- The session memory bridge ships inactive, is approval-gated by `approved_by: user_explicit`, and targets only `merlin_session`.
- Follow-up Phase 3 learning must build on this approval-gated memory path, not bypass it.

## Before Calling Work Done

- Run focused tests.
- Run CI-relevant smoke tests.
- Push only after local validation.
- Watch GitHub Actions.
- Update issue comments and docs.
