# GitHub Issues Draft

> Moved from `docs/GITHUB_ISSUES_DRAFT.md` on 2026-05-06 — content fully preserved.
> This is the product backlog issue spec. Use this as the source of truth for issue acceptance criteria, risk, and test plans.

Last updated: 2026-05-06

## Current GitHub Milestone Alignment

The active GitHub milestone ladder is:

- `v1.0 — Stable Installer Release`
- `v1.1 — Mobile Access + Remote-Safe Entry Points`
- `v1.2 — Hardware Guide + Document Ingestion Planning`
- `v1.3 — Reliability + Memory + Router`
- `v1.5 — Memory Benchmarking`
- `v1.6 — Pi Intelligence + Observability`
- `v1.7 — Security Hardening`
- `v2.0 — Merlin Staff Core`
- `v2.1 — Dashboard Command Center`
- `v2.2 — Magic Mode`
- `v3.0 — Public Product Release`

Recent normalization:

- #41 through #46 are closed under `v1.0` and normalized with `v1.0`, `release`, and `priority: critical` labels.
- #48 and #49 are closed under `v1.0`.
- #61 is closed under `v1.0` after fixing optional Compose service profile gating exposed by live core upgrade.
- #1 remains open under `v1.0`; live launchd, clean uninstall/reinstall, unsigned package install, and signed package builder fixes passed on the 8GB Mac. Self-signed `.pkg` install remains blocked by macOS privileged installer trust unless the certificate is trusted at the System level or the release uses Developer ID Installer/notarization.
- #47 is open under `v1.1`.
- #5 is open under `v1.2`.
- #28 is closed under `v2.0`.
- #50, #51, #52, #54, #55, #56, #57, #58, and #59 are closed under `v2.0`.
- #53 remains open under `v2.0`; #60 is closed under `v2.0`.
- #30 and #39 are open under `v2.1`.
- #33 and #34 are open under `v2.2`.
- #37 is open under `v3.0`.

Current next queue:

1. Finish #1 release notes after the uninstaller launchd warning fix lands and CI is green.
2. Keep signed/notarized package distribution separate from the functional unsigned installer gate.
3. Then take #47 or #5 as docs/planning work, not runtime behavior.

## Issue 1: Document Current Installer Baseline And Do-Not-Break List

- Goal: Preserve the working installer before product changes.
- User value: Fewer regressions and clearer upgrade path.
- Files likely touched: `docs/BASELINE_INSTALLER_REVIEW.md`, `docs/DO_NOT_BREAK.md`.
- Implementation notes: Document service flow, ports, profile behavior, fragile areas.
- Acceptance criteria: Docs identify protected files and current architecture.
- Manual tests: Run `bash install.sh --help`, `bash scripts/doctor.sh --help`.
- Automated tests: Existing CI only.
- Risk: Low.
- Rollback: Revert docs.

## Issue 2: Add Mac Hardware Detection And Doctor Visibility

- Goal: Make RAM tier and low-memory warnings visible.
- User value: 8GB users get safe defaults.
- Files likely touched: `scripts/doctor.sh`, `cli/wizard`, tests.
- Implementation notes: Additive only; preserve existing doctor behavior.
- Acceptance criteria: 8GB reports low tier; heavy services warn.
- Manual tests: `wizard doctor`.
- Automated tests: doctor smoke tests.
- Risk: Low.
- Rollback: Revert doctor additions.

## Issue 3: Add Merlin Configuration Foundation

- Goal: Define safe local-first config contract without changing runtime behavior.
- User value: Clear future settings and safer defaults.
- Files likely touched: `configs/merlin/`, docs, tests.
- Implementation notes: Keep `configs/` canonical; do not create legacy root config directory.
- Acceptance criteria: Config validates; cloud disabled; memory approval required.
- Manual tests: `wizard merlin config validate`.
- Automated tests: config loader and config-root smoke.
- Risk: Low.
- Rollback: Revert config docs/examples.

## Issue 4: Add `wizard merlin ask` Thin Local Wrapper

Status: implemented locally; ready for review once tests pass.

- Goal: Make Merlin usable from CLI.
- User value: First direct Merlin product loop.
- Files likely touched: `cli/wizard`, `scripts/merlin-ask.sh`, tests, README.
- Implementation notes: Call local 8766 task endpoint; degrade clearly.
- Acceptance criteria: Local prompt works or gives startup message; risky routes block.
- Manual tests: `wizard merlin ask "explain RAG"`.
- Automated tests: mocked/degraded smoke test.
- Risk: Medium.
- Rollback: Remove wrapper and test.

## Issue 5: Add Read-Only Merlin Dashboard Status Cards

- Goal: Show Merlin state in dashboard.
- User value: Non-technical status and next steps.
- Files likely touched: `dashboard/`, tests, docs.
- Implementation notes: Read 8765 and 8766 only; no mutation controls. Keep the current dashboard safe while preparing the Merlin-native command center.
- Acceptance criteria: Shows local-only, tier, routes, gates, memory, traces, selected staff mode, selected model, and fallback reason.
- Manual tests: Open dashboard with services up/down.
- Automated tests: dashboard smoke/no secret checks.
- Risk: Medium.
- Rollback: Revert dashboard panel.

## Issue 5A: Make Merlin Chat the Dashboard First Screen

- Goal: Move the dashboard from service-status-first to Merlin-chat-first.
- User value: User gets a polished ChatGPT-class Merlin experience while still seeing local-first safety state.
- Files likely touched: `dashboard/index.html`, dashboard smoke tests, docs.
- Implementation notes: Use `POST /task` on port 8766 for Merlin Chat. Keep Open WebUI linked as an advanced/alternate chat surface. Show route, staff mode, selected model, approval gates, memory state, and degraded startup state inline.
- Acceptance criteria: First viewport centers Merlin Chat; local-only/cloud-disabled state is visible; approval-required responses show gate names; degraded task API/LiteLLM state is graceful; no secrets or raw audit input appear.
- Manual tests: Open dashboard with task API online/offline; ask a general task; ask a code task that requires approval; confirm UI does not imply auto-approval.
- Automated tests: Static dashboard smoke checks for `localhost:8766`, local-only badge, no API key values, no privileged execution controls.
- Risk: Medium.
- Rollback: Revert dashboard HTML/CSS/JS changes.

## Issue 5B: Add Wizard Theme Design System

- Goal: Give Home AI Elite a strong, elegant Merlin visual identity.
- User value: Product feels distinct, trustworthy, and premium instead of a generic Docker status page.
- Files likely touched: `dashboard/index.html`, future dashboard assets, docs.
- Implementation notes: Dark mode first; restrained wizard motifs; no cartoon art, decorative orbs, or marketing hero sections. Use green/yellow/red operational states and clear status chips.
- Acceptance criteria: Dashboard has consistent typography, spacing, button states, status chips, and Merlin branding; mobile and desktop layouts do not overlap.
- Manual tests: Desktop and mobile browser review.
- Automated tests: Static smoke for required labels and no unsafe controls.
- Risk: Low.
- Rollback: Revert visual-only changes.

## Issue 6: Add Provider Registry Skeleton

Status: implemented in Issue #28.

- Goal: Track local and optional providers safely.
- User value: User knows whether cloud is disabled.
- Files touched: `merlin/provider_registry.py`, `merlin/status_extension.py`, `tests/test_status_extension.py`.
- Implementation notes: Do not call cloud. Only expose enabled/disabled/present-key status.
- Acceptance criteria: Cloud disabled by default; no key values shown; `/status/providers` returns local-first registry.
- Manual tests: `curl http://localhost:8766/status/providers` with the task API running.
- Automated tests: status provider tests assert local-first defaults and no secret value exposure.
- Risk: Medium.
- Rollback: Revert registry additions.

## Issue 7: Add Model Router Visibility And Low-Memory Fallbacks

- Goal: Make route/model decisions explainable.
- User value: Better trust and fewer low-memory crashes.
- Files likely touched: `merlin/router.py`, configs, tests.
- Implementation notes: Avoid heavy aliases on low tier; no automatic external-provider fallback.
- Acceptance criteria: Route metadata includes model alias and warning.
- Manual tests: route common prompts.
- Automated tests: router tests for all route IDs.
- Risk: Medium.
- Rollback: Revert router changes.

## Issue 8: Add Explicit Memory Approval Flow

- Goal: Memory writes only after user approval.
- User value: Controlled learning.
- Files likely touched: Merlin memory scripts/API, CLI, tests, docs.
- Implementation notes: No auto-learning. Preserve dimension guards.
- Acceptance criteria: pending -> approve -> write; deny writes nothing; delete works.
- Manual tests: remember/delete preference.
- Automated tests: approval, dimension, degraded tests.
- Risk: High.
- Rollback: Disable memory write command/API path.

## Issue 9: Add Magic Mode Plan-Only UI/CLI Polish

- Goal: Make supervised planning understandable.
- User value: Safe orchestration preview.
- Files likely touched: `scripts/merlin-magic-plan.sh`, dashboard, tests.
- Implementation notes: No execution. Show gates and blocked steps.
- Acceptance criteria: Plans are redacted, auditable, and non-executing.
- Manual tests: plan a multi-step goal.
- Automated tests: no execution side effects.
- Risk: Medium.
- Rollback: Revert UI/CLI polish.

## Issue 10: Add Audit Log Format And Viewer

- Goal: Make route, approval, memory, and action history reviewable.
- User value: Trust and troubleshooting.
- Files likely touched: logs/audit scripts, dashboard, tests, docs.
- Implementation notes: Redacted only; no raw input or secrets.
- Acceptance criteria: Audit viewer shows event summaries and IDs.
- Manual tests: route, approval, memory events.
- Automated tests: redaction and no-secret assertions.
- Risk: Medium.
- Rollback: Disable viewer, keep logs.

## Recommended First PR

Issue 4 is complete. The current highest-value work is not a new feature PR; it is the second fresh v1.0 installer validation run from current `main`.
