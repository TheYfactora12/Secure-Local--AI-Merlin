# Merlin Implementation Roadmap

> **Canonical roadmap.** This file was updated 2026-05-06 to absorb the unique content from `IMPLEMENTATION_ROADMAP.md` (now deleted). All milestone strategy, GitHub ladder, and current checkpoint content lives here.

---

## Strategy

Ship Merlin as a useful local-first product before expanding into supervised execution. The installer remains protected. The first implementation slices should be docs/config/health/CLI/dashboard layers, not broad service rewrites.

## GitHub Milestone Ladder

| Milestone | Purpose | Current rule |
|---|---|---|
| `v1.0 — Stable Installer Release` | Fresh install, package, backup/restore, upgrade, uninstall | Must finish before new runtime feature work |
| `v1.1 — Mobile Access + Remote-Safe Entry Points` | Optional mobile/local-network entry point design | Opt-in only; no default LAN exposure |
| `v1.2 — Hardware Guide + Document Ingestion Planning` | 8GB-first hardware guide and optional ingestion plan | Docs/planning before heavy dependencies |
| `v1.3 — Reliability + Memory + Router` | Retry logic, memory reliability, router cleanup | Local-first and approval-gated |
| `v1.5 — Memory Benchmarking` | Memory quality evaluation | After memory behavior is stable |
| `v1.6 — Pi Intelligence + Observability` | Warmth/persona and local observability | No heavy default tracing dependency |
| `v1.7 — Security Hardening` | SAST, red team, policy enforcement | Security gates stay fail-closed |
| `v2.0 — Merlin Staff Core` | Python Merlin core and policy surfaces | No cloud default, no autonomous execution |
| `v2.1 — Dashboard Command Center` | Read-only/user-facing control center | No privileged mutation in dashboard v1 |
| `v2.2 — Magic Mode` | Supervised orchestration | Plan-first, approval-gated |
| `v3.0 — Public Product Release` | Public packaging/onboarding polish | Only after stable lower milestones |

Stress-test result: keep this ladder explicit. Do not jump from v1.0 to v1.3; v1.1 and v1.2 are now real GitHub milestones.

## Execution Governance

Milestone order is the main execution track. Work the highest-priority open issue
in the current milestone before jumping to future features.

Drift/stale cleanup is part of the same work when it directly relates to the
active milestone, active issue, or code being touched. If verified drift is
aligned with the current milestone and can be fixed safely in the same small
slice, fix it with tests and document the evidence.

If drift is real but belongs to another milestone, capture or update a GitHub
issue with the evidence, labels, milestone, risk, and acceptance criteria. Do
not hijack the active session for unrelated cleanup. Before closing a milestone,
review its related open issues and stale findings again so nothing relevant is
left behind.

## Current Issue Alignment (2026-05-06)

- GitHub milestones `v1.0 — Stable Installer Release`,
  `v1.1 — Mobile Access + Remote-Safe Entry Points`, and
  `v1.2 — Hardware Guide + Document Ingestion Planning`, and
  `v1.3 — Reliability + Memory + Router` are closed as of 2026-05-07.
  The next milestone in execution order is `v1.5 — Memory Benchmarking`.
- #41–#46, #48, #49, and #61 closed under `v1.0` with `release` + `priority: critical` labels.
- #1 is closed under `v1.0`; installer runtime and package builder defects are resolved. Developer ID Installer/notarization is split to #64 under `v3.0`.
- #62 passed under `v1.0` on 2026-05-07 after a fresh-data low/core reinstall and launchd validation; see `docs/archive/WHOLE_STACK_RC_VALIDATION_2026-05-07.md`.
- #63 is closed under `v1.0`; whole-stack low/core release-candidate validation passed on the 8GB Mac after the fixes documented in `docs/archive/WHOLE_STACK_RC_VALIDATION_2026-05-06.md`.
- #47 is closed under `v1.1`: mobile/local-network access is design-first,
  opt-in only, and preserves localhost defaults. See
  `docs/MOBILE_ACCESS_PLAN.md`.
- #80 tracks the related webhook execution gate drift under `v1.7`.
- #5 is closed under `v1.2`: stale 16GB-minimum hardware guidance was replaced
  with the current 8GB-first guide, free stack map, and planning-only document
  ingestion scope.
- #3 is closed under `v1.3` after static retry contracts were added to all n8n
  Ollama HTTP nodes.
- #6 is closed as stale/duplicate of #35 because its original acceptance
  criteria required automatic cloud escalation, which conflicts with the
  current local-first approval-gated policy.
- #35 is closed under `v1.3`; it hardens
  `n8n-workflows/ai-router-starter.json` so n8n remains an
  optional local-first workflow adapter. Executable cloud provider HTTP nodes
  are forbidden in the starter workflow; cloud routes return
  `approval_required` metadata for `cloud_model_call`, `external_network`, and
  `api_key_use`.
- #85 captures the future v2.0 design question of whether to add more Merlin
  staff skills. It is intentionally not part of v1.3.
- Next active milestone is `v1.5`; open issue: #7.
- #28 closed under `v2.0`. #50–#60 closed under `v2.0`.
- #30, #39 open under `v2.1`. #33, #34 open under `v2.2`. #37 open under `v3.0`.

---

## Guiding Rules

- Protect the working installer.
- Keep changes small and reviewable.
- Do not make cloud calls default.
- Do not make heavy services mandatory.
- Do not silently learn into memory.
- Do not add a heavy agent framework before core is stable.
- Do not merge port 8766 FastAPI execution-aware behavior into the port 8765 read-only status server.
- Do not auto-push, auto-PR, or auto-merge; user approval is required.

## Current Checkpoint

Last updated: 2026-05-06.

Phase 2 is complete on `main` through `b4f35c8`.

| Phase | Status | Commit |
| --- | --- | --- |
| 2A Config Loader | Done | `99645ca` |
| 2B Policy Engine | Done | `e6ffa8c` |
| 2B secret gate fix | Done | `3c8222f` |
| 2C Native Router | Done | `cbbd41c` |
| 2D Memory Manager | Done | `dfcd500` |
| 2C schema correction | Done | `d608de0` |
| 2E Persona + Task Endpoint | Done | `1503dab` |
| 2F Status Extension | Done | `b4f35c8` |

Issue #22 support tooling is complete and pushed at `47f30df`:

- Additive `scripts/doctor.sh` Merlin Core checks only.
- `scripts/redact.sh` shared redaction helper.
- `scripts/report-bug.sh` sanitized bug report generator.
- `wizard doctor` and `wizard report-bug` wiring.
- Smoke tests for doctor/report-bug/redaction.

Issue #24 CI gate is complete and pushed at `c6f6652`; GitHub Actions run `25451110988` passed:

- Add `merlin-staff-core-pytest` to `.github/workflows/ci.yml`.
- Validate `configs/merlin/persona.yaml` with Python against the real nested schema.
- Run the offline Merlin Staff Core pytest files in CI.
- Add the new Python job to `ci-success.needs`.

Issue #25 Layer 1 is complete and pushed at `d4ece3d`; GitHub Actions run `25454666989` passed:

- Extend `.gitleaks.toml` with default gitleaks rules.
- Add a required `gitleaks-scan` CI job while preserving the existing regex `secret-scan`.
- Add `tests/sast-gitleaks-smoke.sh`.
- Require `gitleaks-scan` in `ci-success.needs`.

Issue #1 latest package validation is complete through `64096f4`; GitHub Actions run `25470059874` passed:

- `pkg/build-pkg.sh --sign` now signs the `pkgbuild` component package and the final `productbuild` distribution package.
- Local self-signed signing supports an explicit keychain and `PACKAGE_SIGNING_TIMESTAMP=none` for private tests.
- `pkgutil --check-signature` can validate current-user trust after the local cert is trusted in the login keychain.
- Privileged `installer` still rejects the self-signed package without System keychain trust or Developer ID Installer notarization. Do not spend more engineering cycles trying to bypass this macOS trust model.

Issue #66 Phase 3B retrieval scoring is complete at `1487176`; GitHub Actions run `25473476135` passed and #66 is closed.

Issue #67 Phase 3C preference extraction is complete as the next narrow slice:

- Add `merlin/preference_extractor.py`.
- Return review-only preference candidates with category, confidence, redacted evidence, and write eligibility.
- Do not write Qdrant memory, call models, call cloud APIs, start services, edit config, or touch the installer.

Issue #79 Phase 3C preference approval bridge is complete:

- Add `wizard preferences list [category]` to read approved preferences from local Qdrant.
- Add `wizard preferences review` to show recent extracted candidates from `logs/merlin-preference-candidates.jsonl`.
- Add `wizard preferences approve "text" category [approval-id]` to write explicitly approved preferences through `MemoryManager.write_approved_preference()`.
- Pass approved text, category, and approval ID through environment variables instead of inline Python string interpolation.
- Keep writes human-triggered, local-only, and consent-gated; no model calls, cloud calls, service starts, or installer changes.

Issue #68 Phase 3D session reflection is complete:

- Add `merlin/session_reflector.py`.
- Summarize existing task outcomes and review-only preference candidates.
- Track task counts, routes, low-confidence routes, staff modes, hardware tier, duration, and 90-day expiry.
- Redact emitted strings and perform no Qdrant writes, model calls, cloud calls, service starts, config edits, or installer changes.

Issue #69 Phase 3D hardening is complete:

- Add `outcome_mix`, `reflection_quality`, and `review_recommended`.
- Add explicit redacted preview logging through `write_reflection_preview()`.
- Keep normal reflection side-effect free.

Issue #70 Phase 3E skill scores is complete:

- Extend approved task outcomes with `skill_domain` and `outcome_rating`.
- Add consent-gated `skill_outcomes` writes using neutral 384-dimension vectors.
- Add read-only `skill_scorer.py` aggregation with recency weighting, confidence scaling, trend detection, and route-bias eligibility.
- Add non-blocking skill bias in `route_task()` and `wizard skills`.
- Preserve graceful degradation: if Qdrant or the scorer is unavailable, routing continues normally.

After #70, continue with a review pass before adding any stronger learning behavior.

Port contract:

- `scripts/merlin-status-api.py` serves 8765 and stays read-only forever unless a dedicated security review changes that contract.
- `merlin/task_endpoint.py` serves 8766 and owns `POST /task` plus `/status/routes`, `/status/approvals`, `/status/traces`, and `/status/memory`.

## Milestone 0: Protect Working Installer and Document Current State

Tasks:

- Keep `install.sh` as baseline.
- Add baseline documentation.
- Add regression checklist for installer.
- Identify current service/profile assumptions.
- Capture “do not break” list.

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
- Draft future `configs/merlin/*.yaml` structure.
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

- [x] Add Python Merlin package without replacing Open WebUI or LiteLLM.
- [x] Add config loader, policy engine, router, memory manager, persona injector, task endpoint, and status extension.
- [x] Expose `POST /task` through FastAPI on port 8766.
- [x] Keep legacy status API on port 8765 read-only.

Risks:

- Duplicating `wizard` CLI responsibilities.
- Accidentally merging the read-only status API with execution-aware task behavior.

Tests:

- Merlin status returns service/profile/tier.
- No cloud calls.
- No service startup side effects in status mode.

Acceptance criteria:

- Merlin can report system state and route tasks without changing the working installer or defaulting to cloud calls.

## Milestone 3: Add Model Router

Tasks:

- Keep LiteLLM as gateway.
- [x] Add Merlin route decision logic in `merlin/router.py`.
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

- Router chooses correct route IDs and model aliases from actual config, with raw input hashed before logging.

## Milestone 4: Add Memory Layer

Tasks:

- Define canonical Qdrant collections.
- [x] Add memory write/search/delete interface in `merlin/memory_manager.py`.
- [x] Enforce Qdrant dimension guards before writes.
- [x] Add degraded mode when Qdrant is unreachable.
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
- Dimension mismatch fails closed; `documents` remains 1536 dimensions and `merlin-session` remains 768 dimensions.

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

- Make Merlin Chat the first-screen primary experience.
- Show profile and hardware tier.
- Show local-only/online mode.
- Show installed models.
- Show active route, staff mode, selected model, and fallback reason.
- Show service groups by profile.
- Add Magic Mode plan/status UI.
- Add memory approval UI once backend exists.
- Add Security Center summary for approval gates and cloud/API state.

Risks:

- Static UI attempts privileged actions without backend policy.
- Dashboard remains a developer status page instead of the Merlin user experience.
- Dashboard duplicates Open WebUI without adding Merlin-specific routing, memory, policy, and hardware context.

Tests:

- Dashboard never displays secrets.
- Dashboard handles offline services gracefully.
- Dashboard warnings match hardware tier.
- Dashboard chat degraded state is clear when task API or LiteLLM is down.
- Dashboard does not expose raw audit input or API key values.

Acceptance criteria:

- Non-technical user can chat with Merlin, understand local/cloud state, see route/model/memory status, and preview Magic Mode without any privileged action executing.

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
- Do not enable external providers or cloud fallback by default.
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
- Added `configs/merlin/profiles.yaml` and `configs/merlin/hardware-tiers.yaml`.
- Added `configs/merlin/model-tiers.env` as the bash-readable model recommendation manifest.
- Added `configs/merlin/memory.yaml` as the canonical/legacy memory schema reference.
- Added `configs/merlin/memory-collections.env` as the bash-readable Qdrant collection manifest.
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
- Profile-gate optional Compose services so core upgrade does not start search, automation, coding, security, or ops services. `Done: docker-compose.yml, tests/compose-profile-gating-smoke.sh`
- Make hardware-tier model pulls opt-in while preserving explicit override. `Done: install.sh, tests/installer-model-pull-policy-smoke.sh`
- Document and enforce core install time budget. `Done: tests/core-install-budget-smoke.sh`
- Align package postinstall with laptop-safe core install. `Done: pkg/scripts/postinstall, tests/pkg-readiness-smoke.sh`
- Add signed/notarized release preflight checks. `Done: pkg/release-preflight.sh, tests/pkg-signing-preflight-smoke.sh`
- Add a local self-signed package wrapper for trusted/private v1.0 testing. `Done: scripts/sign-pkg.sh, tests/pkg-local-sign-smoke.sh`
- Gate GitHub release creation on tags/manual dispatch and package artifact checks. `Done: .github/workflows/release.yml, tests/release-workflow-smoke.sh`
- Run static smoke tests in CI. `Done: .github/workflows/ci.yml`
- Document floating container image tags and gate new ones with a static smoke test. `Done: docs/CONTAINER_IMAGE_POLICY.md, tests/container-image-policy-smoke.sh`
- Update GitHub checkout actions to the Node 24-compatible major version. `Done: .github/workflows/ci.yml, .github/workflows/release.yml`
- Publish unsigned `v0.8.1` prerelease with tested package artifacts and changelog. `Done: GitHub release v0.8.1`
- Update release artifact actions to the Node 24-compatible major version. `Done: .github/workflows/release.yml, tests/release-workflow-smoke.sh`
- Make package uninstall guarded, dry-runnable, and covered by smoke tests. `Done: pkg/scripts/uninstall.sh, scripts/uninstall.sh, tests/uninstall-smoke.sh`
- Warn when launchd agent unload fails during uninstall so a loaded agent is not silently left behind. `Done: pkg/scripts/uninstall.sh, tests/uninstall-smoke.sh`
- Update GitHub release action to the Node 24-compatible major version. `Done: .github/workflows/release.yml, tests/release-workflow-smoke.sh`
- Make launchd auto-start use the laptop-safe core profile instead of raw full-stack Compose. `Done: launchd/com.homeai.stack.plist, tests/launchd-core-smoke.sh`
- Validate same-machine unsigned package install through macOS Installer. `Done: v0.8.6 package receipt, postinstall, doctor, and core-live smoke`
- Make Docker-volume backup profile-aware so core backups stay lightweight and optional n8n/search data is included only when selected. `Done: scripts/backup.sh, tests/backup-profile-smoke.sh`
- Add search profile static safety coverage and a guarded live smoke test. `Done: scripts/start-search.sh, tests/search-profile-smoke.sh, tests/search-profile-live-smoke.sh`
- Add automation profile static safety coverage and a guarded live smoke test. `Done: scripts/start-automation.sh, scripts/import-n8n-workflows.sh, tests/automation-profile-smoke.sh, tests/automation-profile-live-smoke.sh`
- Add a declarative Merlin persona seed for local-first AI engineering team behavior. `Done: configs/merlin/persona.yaml, tests/merlin-persona-smoke.sh`
- Add Merlin guardian ethos with explicit consent, humility, and safety boundaries. `Done: configs/merlin/persona.yaml, tests/merlin-persona-smoke.sh`
- Add coding profile static safety coverage and a guarded live smoke test. `Done: scripts/start-coding.sh, tests/coding-profile-smoke.sh, tests/coding-profile-live-smoke.sh`
- Add upgrade rollback smoke coverage with fake Docker/Git/Curl and test-controlled backup/health timing. `Done: scripts/upgrade.sh, tests/upgrade-rollback-smoke.sh`
- Add declarative Merlin policy and approval-gate coverage before Magic Mode execution. `Done: configs/merlin/policy.yaml, tests/merlin-policy-smoke.sh`
- Add declarative Magic Mode task routing before runtime orchestration. `Done: configs/merlin/routes.yaml, tests/merlin-routing-smoke.sh`
- Add declarative hybrid orchestration decision before runtime control-plane work. `Done: configs/merlin/orchestration.yaml, tests/merlin-orchestration-smoke.sh`
- Add declarative route trace schema before runtime logging. `Done: configs/merlin/trace.yaml, tests/merlin-trace-smoke.sh`
- Add read-only Merlin route decision dry-run before side-effecting runtime actions. `Done: scripts/merlin-dry-run.sh, cli/wizard, tests/merlin-dry-run-smoke.sh`
- Add opt-in redacted JSONL route trace writes to dry-run decisions. `Done: scripts/merlin-dry-run.sh, tests/merlin-dry-run-smoke.sh`
- Add non-executing approval request objects for risky routes before approval persistence/execution. `Done: scripts/merlin-dry-run.sh, tests/merlin-dry-run-smoke.sh`
- Persist pending approval requests to a redacted local JSONL audit log without enabling execution. `Done: scripts/merlin-dry-run.sh, tests/merlin-dry-run-smoke.sh`
- Add read-only approval review command before approve/deny behavior. `Done: scripts/merlin-approvals.sh, cli/wizard, tests/merlin-approvals-smoke.sh`
- Add non-executing approve/deny audit decisions before action execution exists. `Done: scripts/merlin-approvals.sh, cli/wizard, tests/merlin-approvals-smoke.sh`
- Add read-only Merlin status summary before runtime action execution. `Done: scripts/merlin-status.sh, cli/wizard, tests/merlin-status-smoke.sh`
- Add read-only Merlin dashboard status visibility without turning the static dashboard into a privileged control plane. `Done: dashboard/index.html, tests/dashboard-merlin-status-smoke.sh`
- Add a localhost-only read-only Merlin status API for dashboard-backed live state before any control endpoints exist. `Done: scripts/merlin-status-api.py, cli/wizard, tests/merlin-status-api-smoke.sh`
- Add guarded start/stop/status lifecycle commands for the read-only Merlin status API before installer auto-start. `Done: scripts/merlin-status-api.sh, cli/wizard, tests/merlin-status-api-smoke.sh`
- Wire `wizard start|stop|restart` to the read-only Merlin status API while leaving launchd auto-start unchanged. `Done: cli/wizard, tests/wizard-start-status-api-smoke.sh`
- Wire launchd core auto-start through `wizard start core` while keeping optional profiles explicit. `Done: launchd/com.homeai.stack.plist, tests/launchd-core-smoke.sh`
- Run the read-only Merlin status API as a dedicated foreground launchd job so launchd owns restart/lifecycle behavior. `Done: launchd/com.homeai.merlin-status-api.plist, launchd/install-launchd.sh, tests/launchd-core-smoke.sh`
- Run the execution-aware Merlin task API as a separate foreground launchd job on port 8766 while preserving the read-only port 8765 status API boundary. `Done: scripts/merlin-task-api.sh, launchd/com.homeai.merlin-task-api.plist, launchd/install-launchd.sh, tests/merlin-task-api-smoke.sh`
- Add v0 policy-gated execution boundary with only read-only `merlin_status` allowed and risky actions denied even after approval. `Done: scripts/merlin-execute.sh, cli/wizard, tests/merlin-execute-smoke.sh`
- Add plan-only Magic Mode runner that turns route dry-runs into auditable steps without executing any step. `Done: scripts/merlin-magic-plan.sh, cli/wizard, tests/merlin-magic-plan-smoke.sh`
- Add approved memory-write simulator before real Qdrant writes so consent/audit behavior is stable first. `Done: scripts/merlin-memory-write.sh, cli/wizard, tests/merlin-memory-write-smoke.sh`
- Add approved local Qdrant memory write adapter behind the simulator contract, with canonical collection checks, local Ollama embeddings only, redacted audit records, backup manifest coverage, and fake-adapter denial tests. `Done: scripts/merlin-memory-write.sh, configs/merlin/memory-collections.env, tests/merlin-memory-write-smoke.sh, tests/memory-config-smoke.sh`
- Live-validate approved local Qdrant memory write on the low-memory core profile after explicit canonical collection initialization and explicit `nomic-embed-text` install. `Done: merlin_user point 640cc4bb-5dc9-3c68-8a44-5d2560a15ab5, redacted audit mem_20260506_040805_654553`
- Add local-only Qdrant memory search adapter with local Ollama embeddings, raw results only in user output, redacted read audit logs, no memory writes, and CLI routing. `Done: scripts/merlin-memory-read.sh, cli/wizard, tests/merlin-memory-read-smoke.sh`
- Consolidate the repo to one canonical `configs/` root before Phase 2 config loader work. `Done: configs/merlin, configs/models, configs/mcp, tests/config-root-smoke.sh`
- Add Phase 2A Merlin config startup validator with no new runtime dependency. `Done: scripts/merlin-config-validate.py, wizard merlin config validate, tests/merlin-config-validate-smoke.sh`
- Add Qdrant vector dimension validation before local memory search/upsert so 768-dimensional Merlin memory cannot accidentally target the legacy 1536-dimensional `documents` collection. `Done: DimensionMismatchError guard in scripts/merlin-memory-read.sh and scripts/merlin-memory-write.sh`
- Add live Docker validation for optional `search` profile on a machine with enough memory.
