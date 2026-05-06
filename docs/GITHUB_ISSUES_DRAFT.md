# GitHub Issues Draft

Last updated: 2026-05-06

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
- Implementation notes: Read 8765 and 8766 only; no mutation controls.
- Acceptance criteria: Shows local-only, tier, routes, gates, memory, traces.
- Manual tests: Open dashboard with services up/down.
- Automated tests: dashboard smoke/no secret checks.
- Risk: Medium.
- Rollback: Revert dashboard panel.

## Issue 6: Add Provider Registry Skeleton

- Goal: Track local and optional providers safely.
- User value: User knows whether cloud is disabled.
- Files likely touched: `configs/merlin/models.yaml`, docs, tests.
- Implementation notes: Do not call cloud. Only expose enabled/disabled/present-key status.
- Acceptance criteria: Cloud disabled by default; no key values shown.
- Manual tests: doctor/dashboard provider state.
- Automated tests: no-cloud default tests.
- Risk: Medium.
- Rollback: Revert registry additions.

## Issue 7: Add Model Router Visibility And Low-Memory Fallbacks

- Goal: Make route/model decisions explainable.
- User value: Better trust and fewer low-memory crashes.
- Files likely touched: `merlin/router.py`, configs, tests.
- Implementation notes: Avoid heavy aliases on low tier; no cloud fallback.
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

Issue 4 gives the most immediate product value now that baseline docs, doctor, config validation, CI, and security scanning already exist. If the team wants a pure-doc first PR, use Issue 1. If shipping value is the goal, use Issue 4.
