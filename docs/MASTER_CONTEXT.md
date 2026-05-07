# Wizard AI Master Context

Last verified: 2026-05-07
Repo: `TheYfactora12/home-ai-elite`
Branch: `main`
Installer: `install.sh` v1.6

Use this file with `docs/MASTER_PROMPT.md` at the start of every Codex, Perplexity, or AI session to avoid drift.

## Session Operating Rule

Follow milestones in order. While working a milestone, also attack verified
stale or drift issues when they directly relate to the active milestone, active
issue, or files being changed. If the drift is real but belongs elsewhere, create
or update the GitHub issue with evidence and keep the current session on track.
Before marking a milestone complete, re-check related open issues and stale
findings so the milestone closes cleanly.

Current milestone position:

- `v1.0 — Stable Installer Release` is closed after fresh-data low/core install
  validation, launchd validation, package readiness, backup/restore, upgrade,
  and uninstall coverage.
- `v1.1 — Mobile Access + Remote-Safe Entry Points` is closed after
  `docs/MOBILE_ACCESS_PLAN.md` documented localhost-only defaults and opt-in
  LAN/mobile design.
- `v1.2 — Hardware Guide + Document Ingestion Planning` is closed after
  `docs/hardware-guide.md`, `docs/free-stack-map.md`, and
  `docs/DOCUMENT_INGESTION_PLAN.md` replaced the stale 16GB-minimum plan with
  current 8GB-first guidance.
- `v1.3 — Reliability + Memory + Router` is closed after #3 added n8n Ollama
  retry contracts and #35 made the n8n ModelRouter starter local-first and
  approval-gated.
- `v1.5 — Memory Benchmarking` is closed after #7 added the offline benchmark
  harness and `wizard benchmark run`.
- Next in order: `v1.6 — Pi Intelligence + Observability`. #36 is closed as
  the design-first parent. #8 is the active optional/profile-gated Langfuse
  parent and is unblocked by #36.
- #8 implementation order: local JSONL `wizard score` first, optional
  self-hosted Langfuse profile later. Do not add Langfuse to the default
  Compose stack.
- #8 JSONL trace inspection now follows the same baseline-first rule:
  `wizard trace <id>` reads local trace, approval, and outcome JSONL before
  any optional trace UI is introduced.
- #8 optional Langfuse lives only in `docker-compose.observability.yml` and
  starts only through `wizard start observability`. It remains off by default,
  localhost-only, separate from Open WebUI port `3000`, and guarded against
  low-RAM startup unless explicitly overridden.
- #86 adds `wizard observability export --dry-run` for local JSONL export
  planning. Live export must be explicit, localhost-only, and must refuse hosted
  Langfuse/cloud URLs.
- #87 adds an inactive optional n8n trace emitter workflow for local Langfuse:
  `n8n-workflows/07-local-langfuse-trace-emitter.json`. It emits only redacted
  metadata when the observability profile is active and leaves existing n8n
  workflows unchanged by default.
- Future commercial direction: `docs/architecture/AUTOMATION_RUNTIME_STRATEGY.md`
  captures a last-mile `v3.x — Native Automation Runtime` milestone to
  supplement or replace n8n after Merlin workflows prove the right owned
  runtime shape. Do not rebuild n8n inside v1.6.
- #35 is the canonical n8n ModelRouter rewrite issue. #6 is closed as
  stale/duplicate because it required automatic cloud escalation, which violates
  current local-first approval-gated policy.
- n8n ModelRouter starter workflows must not contain executable cloud provider
  HTTP nodes. Cloud branches are approval-required metadata only unless a
  future, explicit, policy-gated implementation is approved.
- #85 tracks the future question of whether Merlin should add staff skills
  beyond the current six modes. It belongs to v2.0 and must not expand v1.3.
- v1.5 #7 intentionally used offline deterministic benchmark fixtures first.
  Do not add live Qdrant/Ollama benchmark profiles without an explicit
  integration-test gate such as `MERLIN_INTEGRATION_TESTS=1`.
- Drift captured during v1.1: #80 tracks whether to add an explicit
  `webhook_execution` policy gate under `v1.7`.

## Decision

Wizard AI is a local-first AI platform: own Perplexity + Codex + Memory on user-owned hardware with zero required subscriptions.

Hardware principle: 8GB Macs are the entry point in low/core mode. The system scales upward by profile and hardware tier; the full stack is not expected to run on 8GB.

The supported install path is:

```bash
bash install.sh
```

Raw `docker compose up` is now macOS-safe by default because macOS-incompatible services are profile-gated. It is still not the preferred install path because it skips secret rotation, model pulls, Qdrant bootstrap, and n8n workflow import.

## Current Architecture

| Service | Port | Replaces |
| --- | ---: | --- |
| Wizard HQ | 8888 | Manual status checks |
| Open WebUI | 3000 | ChatGPT |
| Perplexica | 3002 | Perplexity AI |
| OpenHands | 3003 | GitHub Copilot/Codex |
| n8n | 5678 | Zapier |
| LiteLLM | 4000 | OpenAI API layer |
| SearXNG | 8080 | Google for AI search |
| Qdrant | 6333 | Pinecone |
| Ollama | 11434 | OpenAI API, local |
| Merlin status API | 8765 | Read-only dashboard status bridge |
| Merlin task API | 8766 | FastAPI task endpoint and Phase 2 status panels |

Port 8765 and port 8766 are separate by design:

- `scripts/merlin-status-api.py` serves port 8765. It is read-only, JSONL/status based, and must keep `execution_allowed=false`. Do not modify it for execution-aware features.
- `merlin/task_endpoint.py` serves port 8766. It owns `POST /task` plus `/status/routes`, `/status/approvals`, `/status/traces`, and `/status/memory`.

macOS:

- Ollama runs natively for Apple Metal GPU acceleration.
- Containers reach native Ollama through `http://host.docker.internal:11434`.
- Docker Ollama is profile-gated behind `docker-ollama`.
- fail2ban is profile-gated behind `linux-security`.
- Default `docker compose up` excludes both Docker Ollama and fail2ban.

Linux Docker-Ollama mode:

```bash
docker compose --profile docker-ollama --profile linux-security up -d
```

Merlin control-plane status:

- `wizard merlin dry-run "goal"` previews routing, model, profile, and approval requirements with no side effects.
- `wizard merlin config validate` validates Phase 2A Merlin config startup contracts from `configs/merlin/` with no new runtime YAML dependency.
- `wizard merlin approvals list|approve|deny` records approval audit state but still does not execute actions.
- `wizard merlin status` reports local profile, hardware tier, privacy mode, approvals, and services.
- `wizard merlin execute plan|execute --action merlin_status` is the v0 policy-gated execution boundary. It only allows read-only Merlin status and writes a redacted execution audit record on execute.
- `wizard merlin magic plan "goal"` drafts plan-only Magic Mode steps from the existing route dry-run. With `--write-plan`, it writes redacted plan JSONL and route/approval audit records; it still executes nothing.
- `wizard merlin memory plan|simulate|write --memory-type <type> --text <text>` is the approved memory-write boundary. Simulate writes redacted JSONL only. Write requires an approved `memory_write` approval id, an existing canonical Qdrant collection, and local Ollama embeddings before it upserts approved memory to local Qdrant.
- `wizard merlin memory search --query "..." --memory-type <type>` is the local-only memory-read boundary. It searches Qdrant with local Ollama embeddings and writes a redacted read audit record.
- `wizard merlin status-api start|status|stop` manages the localhost-only read-only status API.
- `wizard start` starts the selected profile, then starts the read-only Merlin status API if profile startup succeeds.
- `wizard stop` stops the status API before stopping Docker services.
- `wizard restart` stops and restarts the status API around Docker restart.
- launchd runs the read-only Merlin status API as its own foreground job: `com.homeai.merlin-status-api`.
- Dashboard reads `http://localhost:8765/status` when the status API is running.
- The status API is read-only: `GET /healthz`, `GET /status`, mutation methods rejected, `execution_allowed=false`.
- Canonical config root is `configs/`; root `config/` is forbidden. Merlin config lives in `configs/merlin/`.

## Phase 2 Complete

Phase 2 is complete on `main` through commit `b4f35c8`, with the Merlin Staff Core offline pytest suite expanded to 80 tests locally after Issue #60 swarm-context wiring.

| Phase | Commit | Files |
| --- | --- | --- |
| 2A Config Loader | `99645ca` | `merlin/config_loader.py`, `tests/test_config_loader.py` |
| 2B Policy Engine | `e6ffa8c` | `merlin/policy_engine.py`, `tests/test_policy_engine.py` |
| Policy gate fix | `3c8222f` | explicit `secret_access` gate in policy |
| 2C Native Router | `cbbd41c` | `merlin/router.py`, `tests/test_router.py` |
| 2D Memory Manager | `dfcd500` | `merlin/memory_manager.py`, memory tests |
| Router trace correction | `d608de0` | actual route schema fields |
| 2E Persona + Task Endpoint | `1503dab` | `persona_injector.py`, `task_endpoint.py`, endpoint tests |
| 2F Status Extension | `b4f35c8` | `status_extension.py`, status extension tests |

Phase 2 runtime package:

- `merlin/config_loader.py` validates the Merlin YAML config set.
- `merlin/policy_engine.py` enforces 14 fail-closed approval gates.
- `merlin/router.py` routes into the real 5 route IDs, selects all 6 staff modes, carries approval gates, applies low-memory model fallback, and writes route audit events.
- `merlin/swarm_coordinator.py` converts a `RouteDecision` into immutable `SwarmContext` for persona/staff prompt wiring.
- `merlin/memory_manager.py` talks to local Ollama embeddings and Qdrant with dimension guards.
- `merlin/persona_injector.py` builds Merlin system prompts with guardian ethos and Pi warmth.
- `merlin/task_endpoint.py` exposes FastAPI on port 8766.
- `merlin/status_extension.py` adds route, approval, trace, and memory status panels to the FastAPI app.

Later GitHub roadmap normalization assigned the duplicate/new Phase 2 tracking issues #50 through #60 to `v2.0 — Merlin Staff Core`. Issues #50 through #60 are closed after verification against the implemented files, tests, and CI. Do not create a duplicate `Merlin Staff — Core` milestone.

## RAM Tiers

Do not change these without a dedicated issue and validation run.

| RAM | Tier | Models |
| --- | --- | --- |
| 8-15 GB | low | `qwen2.5:7b`, `nomic-embed-text` |
| 16-23 GB | base | `qwen2.5:7b`, `qwen2.5-coder:7b`, `deepseek-r1:7b` |
| 24-47 GB | mid | `qwen2.5:32b`, `qwen2.5-coder:14b`, `deepseek-r1:14b` |
| 48+ GB | high | `llama3.3:70b`, `qwen2.5:32b`, `deepseek-r1:32b` |

## Closed Bug/Architecture Issues

All BUG-01 through BUG-18 fixes are written, pushed, and verified on `main`.

Recently verified closures:

- #11 BUG-10: litellm/open-webui macOS `depends_on: ollama` startup blocker.
- #13 BUG-12: blank `.env` keys no longer report as `SET`.
- #16 BUG-15: open-webui same root cause as BUG-10.
- #18 BUG-17: LiteLLM config pre-flight guard.
- #19 BUG-18: bootstrap failure messaging is actionable.
- #20 ARCH: raw `docker-compose.yml` is macOS-safe without requiring install-time dependency surgery.
- #23 macOS real install test bugs: native Ollama/bootstrap/validation gaps fixed.

## Open Work, Priority Order

1. Finish the active `v1.6` observability queue: #88 first, then #89.
2. Keep #8 open until the remaining v1.6 child work is complete and CI is green.
3. Keep signing/notarization deferred to #64; the v1.0 low/core installer path is green on this 8GB Mac.
4. Continue optional live tests for search, automation, coding, and upgrade profiles on hardware with enough memory.

## Reasoning Summary

The current architecture keeps the default user path local-first and low-friction while preserving Linux server security options through explicit profiles. macOS avoids Docker Ollama conflicts by using native Ollama; Linux can still run Ollama in Docker when profiles are enabled.

## Whole-Stack RC Validation

#63 passed on 2026-05-06 after fixing the release-candidate findings documented in `docs/archive/WHOLE_STACK_RC_VALIDATION_2026-05-06.md`:

- Installer now creates `.venv` from `requirements-merlin.txt` for Merlin Python runtime dependencies.
- Task API now starts through `merlin.task_endpoint:app` so `/status/*` routes are registered live.
- Bootstrap re-runs when Qdrant collections are missing despite `.wizard-bootstrapped`.
- Bootstrap creates canonical Merlin collections by default.
- Task API sends the local LiteLLM authorization header from environment or `.env` without logging secrets.

#62 passed on 2026-05-07 after the separate launchd-managed task API was added.
The fresh-data low/core release gate is documented in
`docs/archive/WHOLE_STACK_RC_VALIDATION_2026-05-07.md`: uninstall with
`--keep-files --remove-data`, non-interactive core reinstall with model pulls
skipped, launchd reinstall, doctor, offline Python suite, session memory bridge
static tests, core live smoke, 8765 read-only health, 8766 status panels, and
live `/task` all passed.

## Phase 3A Started

#65 starts Phase 3 with `merlin/outcome_observer.py`. The observer records
task outcomes as redacted JSONL by default, stores only `task_hash` instead of
raw user input, creates routing-gap review items for low-confidence successful
outcomes, and writes to `merlin_audit` only when an explicit approval id is
provided. `merlin/task_endpoint.py` now records success, rejected, and degraded
outcomes without changing routing behavior.

#66 adds Phase 3B retrieval-augmented routing. The router reads approved
outcome history from `logs/merlin-outcomes.jsonl` or `MERLIN_OUTCOME_LOG`,
ignores records without `approval_id`, applies 30-day recency decay, and blends
`final_score = 0.6 * keyword_score + 0.4 * retrieval_score` only when approved
history exists. Cold-start routing remains unchanged, unknown input still
falls back to `general` at confidence `0.0`, and no memory writes or config
edits occur during classification.

The next engineering priority is supportability: diagnostics, sanitized bug reports, and drift-proof docs so another AI or human can continue without breaking the installer or crossing security boundaries. Signed release work can wait until the local core loop and support loop remain green.

## Risks / Unknowns

- Native macOS Ollama availability depends on the host service staying up.
- `host.docker.internal` plus `host-gateway` must be retested on future Docker Desktop and Linux Docker engine changes.
- The status API is intentionally read-only and must not become a privileged control plane without a separate policy-gated execution layer.
- The FastAPI task API is intentionally separate on port 8766. Do not bridge it into `scripts/merlin-status-api.py`.
- The v0 execution layer only allows `merlin_status`; approval alone must not unlock shell, file, network, memory write, service, model download, cloud, or OpenHands actions.
- Magic Mode is plan-only: steps can be drafted and audited, but no step adapter can execute until separately implemented and tested.
- Memory write simulation is not persistence. It stores only redacted audit metadata and must not be treated as learned memory.
- launchd starts the core profile through `wizard start core` and runs the read-only status API as a separate foreground LaunchAgent. Do not rely on a short-lived launchd shell to daemonize the API.
- n8n is still a Phase 1 workflow/execution surface and remains parallel to the Phase 2 Python control plane. Do not decommission it until replacements are proven route by route.
- Optional live profile tests still need hardware/time validation.
- Memory quality and regression safety still need stronger test coverage before Magic Mode writes memory.

## Next Actions

1. Commit and push the uninstaller launchd warning fix with the v1.0 validation notes.
2. Keep verifying `ci-success` requires both `gitleaks-scan` and `merlin-staff-core-pytest`.
3. Close #1 only after CI is green and the completion comment records fresh install, package, backup/restore, upgrade, launchd, and clean reinstall validation.

## Validation

Last verified: 2026-05-07.

- Phase 2F merged at `b4f35c8`; local Phase 2 Python suite reported 58 passing tests.
- CI was green for the Phase 2F merge run.
- Phase 3 live end-to-end validation is documented in `docs/archive/PHASE3_LIVE_E2E_VALIDATION_2026-05-07.md`: core stack, task API, local LiteLLM/Ollama `/task`, approval-gated memory skip, explicit approved `skill_outcomes` write, and `wizard skills` readback all passed.
- launchd persistence validation is documented in `docs/archive/LAUNCHD_PERSISTENCE_VALIDATION_2026-05-07.md`: `com.homeai.stack` starts the core profile, `com.homeai.merlin-status-api` remains running on port 8765 with `execution_allowed=false`, `com.homeai.merlin-task-api` remains running on port 8766, and `tests/core-live-smoke.sh` passed with 18 checks and 0 failures.
- Issue #75 added a separate Merlin Task API LaunchAgent and lifecycle manager. Port 8766 is now launchd-managed without merging execution-aware behavior into the read-only status API on port 8765.
- Fresh 8GB Mac core reinstall is green after #48; #48 fixed non-interactive status API startup messaging so the installer no longer implies persistent port 8765 without launchd or manual start.
- Unsigned `.pkg` install is green after #49; #49 filtered package runtime copy so stale `.wizard-bootstrapped`, logs, caches, `.venv`, and build artifacts are not copied into the user runtime.
- GitHub Actions run `25467394670` passed for commit `88d4f96`.
- Live backup/restore verification passed on the package-installed stack with `bash tests/qdrant-restore-live-smoke.sh`: disposable Qdrant collection backed up, deleted, restored, and vector payload verified with 8 checks and 0 failures.
- Live core upgrade verification passed after #61. The first run exposed optional `searxng` startup in core mode; #61 profile-gated optional Compose services, removed the hard `open-webui` to `searxng` dependency, added `tests/compose-profile-gating-smoke.sh`, and closed with CI run `25468170156` passing. Rerun of `bash scripts/upgrade.sh --profile core` completed and kept running services core-only: `litellm`, `open-webui`, `qdrant`, and `dashboard`.
- Live launchd persistence validation passed: `bash launchd/install-launchd.sh` registered `com.homeai.docker`, `com.homeai.stack`, and `com.homeai.merlin-status-api`; after the timers, `launchctl print gui/501/com.homeai.merlin-status-api` reported `state = running`, `GET /healthz` returned `execution_allowed=false`, and running Docker services remained core-only.
- Live clean uninstall/reinstall validation passed from source snapshot `/private/tmp/home-ai-elite-source-20260506_202108`: `pkg/scripts/uninstall.sh --yes --remove-data` removed `~/home-ai-elite`, backed up `.env`, and preserved Docker Desktop/Homebrew/Ollama. Docker cleanup initially skipped because the engine was not visible, so old Compose volumes were removed explicitly before reinstall. Fresh non-interactive core reinstall then passed with local-first defaults, no cloud keys, no model pulls, and core-only running services.
- Uninstaller validation found one release-quality follow-up: launchd `bootout` failures were previously suppressed, which could leave an already-loaded status API agent alive even after the plist was removed. The uninstaller now warns with the exact manual `launchctl bootout gui/<uid>/<label>` command when unload fails, and `tests/uninstall-smoke.sh` covers that behavior.
- Local self-signed package signing is now wrapped by `scripts/sign-pkg.sh`. It expects a Keychain identity named `Home AI Elite Local Signing`, signs an existing unsigned package with `productsign`, verifies with `pkgutil --check-signature`, and is covered by `tests/pkg-local-sign-smoke.sh`.
- Issue #22 support tooling is merged and pushed at `47f30df`: additive doctor checks, redaction helper, sanitized report generator, wizard wiring, and doctor/report-bug/redaction smokes.
- Issue #24 CI gate is merged and pushed at `c6f6652`; GitHub Actions run `25451110988` passed.
- Issue #25 Layer 1 is merged and pushed at `d4ece3d`; GitHub Actions run `25454666989` passed with `gitleaks-scan` and `merlin-staff-core-pytest` both required by `ci-success`.

- Current local validation for the Qdrant memory adapter work:
  - `bash tests/merlin-memory-write-smoke.sh`
  - `bash tests/memory-config-smoke.sh`
  - `bash tests/master-prompt-smoke.sh`
  - `bash -n cli/wizard scripts/merlin-memory-write.sh tests/merlin-memory-write-smoke.sh tests/memory-config-smoke.sh tests/master-prompt-smoke.sh`
  - `git diff --check`
- Most recent checked GitHub Actions run before this patch passed for commit `232038c`.
- `wizard start|stop|restart` is wired to the guarded read-only Merlin status API lifecycle for manual starts.
- launchd source now includes a dedicated read-only Merlin status API foreground agent for persistent login auto-start.
- `tests/wizard-start-status-api-smoke.sh` passed.
- `tests/merlin-status-api-smoke.sh` passed with localhost-bind permission.
- Full local static smoke suite passed.
- Dashboard contains the read-only Merlin Control Status panel and points to `wizard merlin status-api start`.
- Live launchd reinstall registered `com.homeai.docker`, `com.homeai.stack`, and `com.homeai.merlin-status-api`.
- `launchctl print gui/501/com.homeai.merlin-status-api` reported `state = running` and `last exit code = (never exited)`.
- `wizard merlin status-api status`, `GET /healthz`, and `GET /status` passed against `http://127.0.0.1:8765`.
- `GET /status` reported profile `core`, hardware tier `low`, RAM `8`, privacy `local_only`, cloud disabled, all core services running, and `execution_allowed=false`.
- `bash tests/core-live-smoke.sh` passed with 18 checks, 0 warnings, and 0 failures.
- `wizard merlin execute execute --action merlin_status` is the only v0 executable action; it prints read-only status and writes `logs/merlin-executions.jsonl`.
- `tests/merlin-execute-smoke.sh` verifies dry-run/execute separation, audit logging, CLI routing, and denial of risky actions even after approval.
- `wizard merlin magic plan "goal"` drafts plan-only steps and can write redacted plan records to `logs/merlin-magic-plans.jsonl`.
- `tests/merlin-magic-plan-smoke.sh` verifies Magic Mode remains plan-only, writes no raw goals, and produces approval-blocked plans for risky routes.
- `wizard merlin memory simulate --memory-type preference --text "..." --approval-id <id>` writes only redacted simulated memory audit records to `logs/merlin-memory-writes.jsonl`.
- `wizard merlin memory write --memory-type preference --text "..." --approval-id <id>` can upsert approved memory to local Qdrant with local Ollama embeddings. It does not create collections, pull models, start services, call cloud APIs, or store raw text in the JSONL audit log.
- `tests/merlin-memory-write-smoke.sh` verifies approved `memory_write` gate validation, fail-closed denial, no raw audit logging, no Qdrant/embedding calls during plan/simulate/denial, and a fake local Qdrant/Ollama write path for approved `write`.
- `wizard merlin memory search --query "..." --memory-type preference` can retrieve approved memory from local Qdrant with local Ollama embeddings. It writes redacted read audit records to `logs/merlin-memory-reads.jsonl` and performs no memory writes, cloud calls, service starts, or tool execution.
- `tests/merlin-memory-read-smoke.sh` verifies local embedding search, Qdrant read behavior, CLI routing, no memory writes, and no raw query or raw memory text in read audit logs.
- `tests/merlin-config-validate-smoke.sh` verifies the Phase 2A config validator, route/policy cross-checks, memory dimension contract checks, and rejection of the legacy root `config/` directory.
- Live memory validation on 2026-05-06 initialized canonical Qdrant collections with `MERLIN_CREATE_CANONICAL_COLLECTIONS=true bash scripts/init-qdrant.sh`, explicitly installed local `nomic-embed-text`, approved `approval_dryrun_20260506_040756_17686`, wrote point `640cc4bb-5dc9-3c68-8a44-5d2560a15ab5` into `merlin_user`, and verified the JSONL audit record `mem_20260506_040805_654553` stayed redacted.
- Live memory search validation on 2026-05-06 ran `wizard merlin memory search --query "local-first profile-aware" --memory-type preference --limit 3`, retrieved point `640cc4bb-5dc9-3c68-8a44-5d2560a15ab5`, and verified read audit record `mread_20260506_041535_472003` stored hashes only.
- PR #10 / `installer-hardening` is closed and `origin/installer-hardening` is an ancestor of `origin/main`; it is not an active blocker.
- Phase 3A outcome observer is complete in #65 through `b1be9e9`; it records hashed task outcomes to JSONL and optionally writes approved audit events.
- Phase 3B retrieval-augmented routing is complete in #66 at `1487176`; CI run `25473476135` passed. Routing now exposes keyword/retrieval scores and only approved outcome history can influence retrieval scoring.
- Phase 3C preference extractor is complete in #67. It is review-only: `merlin/preference_extractor.py` returns candidate preferences with confidence, category, redacted evidence, and write eligibility, but performs no memory writes or model/cloud calls.
- Phase 3C preference approval bridge is complete in #79. `wizard preferences list|review|approve` now provides the human approval surface for extracted preferences, writing only through `MemoryManager.write_approved_preference()` and passing preference text through environment variables instead of inline Python interpolation.
- Phase 3D session reflector is complete in #68. It is review-only: `merlin/session_reflector.py` summarizes existing outcome/preference records with task counts, routes, low-confidence routes, staff modes, hardware tier, duration, and 90-day expiry, while performing no memory writes or model/cloud calls.
- Phase 3D hardening is complete in #69. Session reflections now include outcome mix, reflection quality, review recommendation, and an explicit redacted JSONL preview writer; normal reflection remains side-effect free.
- Phase 3E skill scores are complete in #70. `TaskOutcome` now includes skill domain/rating, approved outcomes can write consent-gated `skill_outcomes`, `skill_scorer.py` computes read-only reports, `route_task()` applies non-blocking skill bias, and `wizard skills` prints the local score table.

Earlier live validation on 2026-05-05:

- Core install path completed with `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`.
- `tests/core-install-budget-smoke.sh` completed the core installer in 95 seconds against a 600 second budget, then passed live core smoke.
- Docker Desktop core services were running: Wizard HQ `:8888`, Open WebUI `:3000`, LiteLLM `:4000`, and Qdrant `:6333`.
- Native Ollama was running through Homebrew service.
- Approved low-tier model `qwen2.5:7b` was installed.
- Ollama local generation returned `Merlin core online`.
- LiteLLM `/v1/models` listed configured aliases and `/v1/chat/completions` with `qwen7b` returned `Merlin gateway online`.
- `scripts/doctor.sh` completed with 43 passes, 2 warnings, and 0 failures.
- Unsigned local package build produced `home-ai-elite-0.6.1.pkg`; payload check found no `.env` or generated certs. Package is not signed/notarized.
- `pkg/release-preflight.sh` confirms package tools are installed, but this Mac has no Developer ID Installer identity and no Apple notarization environment set.

Earlier validation on 2026-05-04:

- `docker compose config --quiet` passed.
- Default `docker compose config --services` excludes `ollama` and `fail2ban`.
- `docker compose --profile docker-ollama --profile linux-security config --services` includes both `ollama` and `fail2ban`.
- `bash -n` passed for changed shell scripts.
- `scripts/status.sh` showed Wizard HQ on `http://localhost:8888`.
- `tests/e2e-test.sh` passed with 14 checks and 0 failures.
- GitHub Actions were green for commit `4932356`:
  - CI `25297415649`
  - Release `25297415662`
