# Merlin Implementation Roadmap

## Guiding Rules

- Protect the working installer.
- Keep changes small and reviewable.
- Do not make cloud calls default.
- Do not make heavy services mandatory.
- Do not silently learn into memory.
- Do not add a heavy agent framework before core is stable.

## Milestone 0: Protect Working Installer and Document Current State

Tasks:

- Keep `install.sh` as baseline.
- Add baseline documentation.
- Add regression checklist for installer.
- Identify current service/profile assumptions.
- Capture "do not break" list.

Risks:

- Documentation drifts from code.
- Existing installer defects get mixed with new architecture work.

Tests:

- `bash -n install.sh`
- `bash -n scripts/*.sh`
- `docker compose config --quiet`
- non-interactive install smoke test when Docker is available

Acceptance criteria:

- Current behavior is documented.
- Installer protection list exists.
- No application code changed.

## Milestone 1: Add Architecture Docs, Config Model, and Health Checks

Tasks:

- [x] Define profiles: `core`, `search`, `automation`, `coding`, `security`, `ops`, `full`.
- [x] Define hardware tiers.
- Draft future `config/merlin/*.yaml` structure.
- [x] Add `wizard doctor` baseline diagnostic.
- [x] Add profile-aware start scripts for core, search, automation, coding, and full.
- [x] Wire `wizard start [core|search|automation|coding|full]`.
- Split test plan by profile.

Risks:

- Config model becomes too large before implementation.

Tests:

- Documentation review.
- Static config validation once config files exist.

Acceptance criteria:

- Profiles are agreed.
- Hardware tier rules are agreed.
- Health check requirements are documented.

## Milestone 2: Add Merlin Core Interface Without Changing All Existing Services

Tasks:

- Add a thin Merlin command/API facade.
- Read current `.env`, hardware tier, and service state.
- Expose status and route decision dry-run.
- Do not replace Open WebUI or LiteLLM.

Risks:

- Duplicating `wizard` CLI responsibilities.

Tests:

- Merlin status returns service/profile/tier.
- No cloud calls.
- No service startup side effects in status mode.

Acceptance criteria:

- Merlin can report system state without changing runtime behavior.

## Milestone 3: Add Model Router

Tasks:

- Keep LiteLLM as gateway.
- Add Merlin route decision logic.
- Route by task type, privacy, hardware tier, online mode, and model availability.
- Log route decisions.

Risks:

- Static LiteLLM config and Merlin router conflict.

Tests:

- Sensitive task always local.
- Offline mode never selects cloud.
- Missing local model returns clear fallback/action.
- Low tier avoids heavy models.

Acceptance criteria:

- Router chooses correct backend in dry-run and live local calls.

## Milestone 4: Add Memory Layer

Tasks:

- Define canonical Qdrant collections.
- Add memory write approval flow.
- Add memory deletion.
- Add audit trail.
- Align backup/restore with canonical collections.

Risks:

- Memory poisoning.
- Silent retention of private data.

Tests:

- Memory write requires approval.
- Memory delete works.
- Backup/restore covers canonical collections.
- RAG retrieval does not include deleted memory.

Acceptance criteria:

- Memory is explicit, auditable, and restorable.

## Milestone 5: Add Magic Mode Planner

Tasks:

- Add plan-only Magic Mode.
- Break goals into steps.
- Mark tool/action risk.
- Add approval requirements.
- Add pause/stop semantics.

Risks:

- Users mistake plan-only mode for full automation.
- Agents perform actions without policy gates.

Tests:

- Risky steps require approval.
- Stop/pause works in simulation.
- Plan is logged.

Acceptance criteria:

- Magic Mode can plan safely without executing risky actions.

## Milestone 6: Add Dashboard Improvements

Tasks:

- Show profile and hardware tier.
- Show local-only/online mode.
- Show installed models.
- Show service groups by profile.
- Add Magic Mode plan/status UI.
- Add memory approval UI once backend exists.

Risks:

- Static UI attempts privileged actions without backend policy.

Tests:

- Dashboard never displays secrets.
- Dashboard handles offline services gracefully.
- Dashboard warnings match hardware tier.

Acceptance criteria:

- Non-technical user can understand system state and next steps.

## Milestone 7: Add Security Hardening and Approval Gates

Tasks:

- Move high-risk services behind profiles.
- Add approval policy for shell, files, network, cloud, memory, OpenHands.
- Add local-only enforcement tests.
- Add token leak checks.

Risks:

- Approval prompts become annoying and users disable them.

Tests:

- No cloud calls by default.
- `0.0.0.0` bind warning.
- OpenHands disabled until coding profile enabled.
- Shell/file/network actions blocked without approval.

Acceptance criteria:

- Magic Mode and agents cannot perform risky actions silently.

## Milestone 8: Add Hardware-Tier Optimization

Tasks:

- Use detected RAM and OS to suggest profile/model tier.
- Add dashboard warnings.
- Add low-memory mode.
- Ask before large model pulls.

Risks:

- Overblocking advanced users.

Tests:

- 8 GB tier does not start heavy services.
- 16-24 GB tier defaults to core.
- User override is possible and logged.

Acceptance criteria:

- Installer scales safely from low-end to high-end Macs.

## Milestone 9: Testing, Packaging, and Release Readiness

Tasks:

- Profile-specific smoke tests.
- Installer regression tests.
- Backup/restore test.
- Upgrade/rollback test.
- Package test on clean macOS.
- Changelog and release notes.

Risks:

- Packaging hides install failures.

Tests:

- Clean install.
- Non-interactive install.
- Skip model pulls.
- Core profile.
- Optional profiles.
- Package install/uninstall.

Acceptance criteria:

- v1 release can be installed, verified, upgraded, backed up, restored, and uninstalled.

## Do Not Do Yet

- Do not replace `install.sh`.
- Do not replace LiteLLM.
- Do not replace Open WebUI.
- Do not add a mandatory LangChain/LangGraph/OpenAI Agents SDK dependency.
- Do not make OpenHands default.
- Do not make n8n required for basic chat.
- Do not enable cloud fallback by default.
- Do not auto-learn memory without approval.
- Do not implement autonomous Magic Mode before approval gates.

## Recommended First 3 GitHub Issues

1. Add profile model and core-first startup plan without changing installer behavior. `Done: config, start commands, installer profile selection, and live core validation are in place.`
2. Add `wizard doctor` requirements and implementation. `Done: baseline diagnostics, model recommendation checks, profile-aware service checks, and live core validation are in place.`
3. Normalize Merlin memory schema and align bootstrap, CLI, backup, restore, and tests. `In progress: schema config, Qdrant init, backup/restore, CLI alignment, and smoke tests are in place; workflow migration still pending.`

## Current Implementation Checkpoint

Completed without replacing the working installer:

- Added profile-aware startup scripts and `wizard start` profile routing.
- Added `wizard doctor` baseline diagnostics.
- Added `config/merlin/profiles.yaml` and `config/merlin/hardware-tiers.yaml`.
- Added `config/merlin/model-tiers.env` as the bash-readable model recommendation manifest.
- Added `config/merlin/memory.yaml` as the canonical/legacy memory schema reference.
- Added `config/merlin/memory-collections.env` as the bash-readable Qdrant collection manifest.
- Added installer profile options for core, developer, workstation, server, full, and custom installs.
- Added `scripts/profile-lib.sh` so installer, bootstrap, and tests share one profile mapping.
- Validated `core` profile live on this 8 GB Mac with Docker Desktop and native Ollama.
- Verified approved local model `qwen2.5:7b` answers through native Ollama.
- Verified LiteLLM routes the `qwen7b` alias to local Ollama successfully.
- Verified `scripts/doctor.sh` finishes with 43 passes, 2 warnings, and 0 failures on the core install.
- Fixed live-validation defects: profile helper load order, host Qdrant bootstrap URL, non-interactive CLI symlink handling, persistent native Ollama startup, and profile-aware doctor checks.
- Updated Qdrant initialization to create current/legacy collections from the manifest.
- Updated `cli/wizard` memory commands to read collection names from the manifest while keeping `swarm_memory` compatible.
- Updated backup/restore to use repo-root `.env`, configurable Qdrant collection coverage, vector-inclusive backups, restore dry-run mode, and failing exit status on restore write failures.
- Added `tests/memory-config-smoke.sh`.
- Added `tests/doctor-model-smoke.sh`.
- Added `tests/wizard-memory-config-smoke.sh`.
- Added `tests/profile-selection-smoke.sh`.
- Added `tests/core-live-smoke.sh`.
- Added `tests/qdrant-restore-live-smoke.sh`.
- Added `tests/update-upgrade-profile-smoke.sh`.
- Added `tests/installer-model-pull-policy-smoke.sh`.
- Added `tests/core-install-budget-smoke.sh`.
- Added `tests/pkg-readiness-smoke.sh`.
- Added `tests/pkg-signing-preflight-smoke.sh`.
- Added `tests/release-workflow-smoke.sh`.
- Added static smoke tests to `.github/workflows/ci.yml`.

Next implementation slice:

- Add a reusable core model smoke test for Ollama and LiteLLM without exposing secrets. `Done: tests/core-live-smoke.sh`
- Add a disposable live-Qdrant restore test. `Done: tests/qdrant-restore-live-smoke.sh`
- Make update/upgrade profile-aware and macOS native-Ollama safe. `Done: scripts/update.sh, scripts/upgrade.sh, tests/update-upgrade-profile-smoke.sh`
- Make hardware-tier model pulls opt-in while preserving explicit override. `Done: install.sh, tests/installer-model-pull-policy-smoke.sh`
- Document and enforce core install time budget. `Done: tests/core-install-budget-smoke.sh`
- Align package postinstall with laptop-safe core install. `Done: pkg/scripts/postinstall, tests/pkg-readiness-smoke.sh`
- Add signed/notarized release preflight checks. `Done: pkg/release-preflight.sh, tests/pkg-signing-preflight-smoke.sh`
- Gate GitHub release creation on tags/manual dispatch and package artifact checks. `Done: .github/workflows/release.yml, tests/release-workflow-smoke.sh`
- Run static smoke tests in CI. `Done: .github/workflows/ci.yml`
- Document floating container image tags and gate new ones with a static smoke test. `Done: docs/CONTAINER_IMAGE_POLICY.md, tests/container-image-policy-smoke.sh`
- Update GitHub checkout actions to the Node 24-compatible major version. `Done: .github/workflows/ci.yml, .github/workflows/release.yml`
- Publish unsigned `v0.8.1` prerelease with tested package artifacts and changelog. `Done: GitHub release v0.8.1`
- Update release artifact actions to the Node 24-compatible major version. `Done: .github/workflows/release.yml, tests/release-workflow-smoke.sh`
- Make package uninstall guarded, dry-runnable, and covered by smoke tests. `Done: pkg/scripts/uninstall.sh, scripts/uninstall.sh, tests/uninstall-smoke.sh`
- Add live Docker validation for optional `search` profile on a machine with enough memory.
