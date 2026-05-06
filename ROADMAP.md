# Home AI Elite — Roadmap

This roadmap tracks what is actually verified, what is only scaffolded, and what must be streamlined before calling the project stable.

## Current Reality

Home AI Elite has a broad prototype stack, but it is not yet a laptop-stable v1.0 product. The main architecture problem is that the "full stack" became the default startup path. On a normal Mac or PC, that creates too much install friction, memory pressure, port usage, and failure surface.

The next milestone is not more features. The next milestone is a reliable laptop-first core that can run before optional services are enabled. From there, the same repo should scale up based on hardware tier and install profile.

## Architecture Direction

### Install Philosophy

The installer should ask or infer what kind of machine it is running on, then enable the right amount of stack.

- [x] Small laptop install: core services only, lowest memory pressure
- [x] Developer laptop install: core + optional search profile
- [x] Desktop/workstation install: core + search + automation profile
- [x] Home server install: core + search + automation + security + ops profile
- [x] Advanced/manual install: user-selected capability profiles

The same project should support all of these without maintaining separate forks.

### Default Core

These should be the only services required for the first successful install:

- [x] Native Ollama on macOS for Metal acceleration
- [x] Open WebUI for the primary chat UI
- [x] LiteLLM for model routing
- [x] Qdrant for memory/RAG storage
- [x] Wizard dashboard/status page
- [x] `wizard doctor` or equivalent preflight check

### Optional Profiles

These should not be required for first boot:

- [ ] Search profile: Perplexica + SearXNG
- [ ] Automation profile: n8n + workflow import
- [ ] Coding profile: OpenHands
- [ ] Security/proxy profile: nginx + fail2ban
- [ ] Ops profile: watchtower + launchd auto-start + scheduled backups
- [ ] Packaging profile: signed macOS `.pkg`

### Hardware Tiers

The installer should map machine resources to sane defaults.

| Tier | Target | Default behavior |
|---|---|---|
| Low | 8-15 GB RAM | Core only, 7B models, no OpenHands by default |
| Base | 16-23 GB RAM | Core + optional search, 7B coder model |
| Mid | 24-47 GB RAM | Core + search + automation, 14B/32B models where practical |
| High | 48+ GB RAM | Full stack available, larger models, background services allowed |
| Server | Always-on desktop/server | Full stack with launchd/backup/nginx/monitoring profiles |

Hardware tier should choose safe defaults, but the user should be able to override profiles explicitly.

### Profile Matrix

| Profile | Purpose | Should run by default? |
|---|---|---|
| `core` | Chat, model routing, memory, dashboard | Yes |
| `search` | Perplexica + SearXNG | No |
| `automation` | n8n + workflow import | No |
| `coding` | OpenHands | No |
| `security` | nginx + fail2ban | Server installs only |
| `ops` | watchtower + launchd + scheduled backups | Server installs only |
| `full` | Everything enabled intentionally | Never by accident |

## Milestone Status

### v0.1 — Core Scaffold

Status: Core path verified on an 8 GB Mac; optional paths still need separate validation.

- [x] Repository structure exists
- [x] Docker Compose stack exists
- [x] `.env.example` exists
- [x] Basic scripts exist: status, stop, restart, update, backup, add-model
- [x] README explains intended architecture
- [x] Compose/default install path is reduced to a laptop-safe core profile
- [ ] Ports and service list should match docs consistently

### v0.2 — Full Stack Prototype

Status: Scaffolded, not yet reliable as a default laptop install.

- [x] Perplexica config exists
- [x] SearXNG config exists
- [x] LiteLLM config exists
- [x] OpenHands service exists
- [x] RAM-aware installer logic exists
- [x] Heavy services are gated behind install/start profiles for the normal core path
- [x] Image tags using `latest`, `main`, or `main-latest` need pinning or documented upgrade policy
- [ ] Full stack startup needs clean Mac/PC validation after core mode works
- [x] Installer supports profile selection by hardware tier and user choice

### v0.3 — First-Boot Automation

Status: Partial.

- [x] Qdrant init script exists
- [x] Bootstrap script exists
- [x] n8n workflow import script exists
- [x] launchd scripts exist
- [x] Qdrant init uses the Merlin memory collection manifest for current/legacy collections
- [ ] n8n workflow import is not truly automatic unless `N8N_API_KEY` exists
- [x] Bootstrap supports core-only behavior and skips optional automation imports unless enabled
- [x] launchd should not auto-start the entire heavy stack by default
- [ ] Bootstrap should be idempotent for each profile independently

### v0.4 — macOS Package, Backup, Restore

Status: Scaffolded, not release-ready.

- [x] `.pkg` build script exists
- [x] Package preinstall/postinstall scripts exist
- [x] Backup and restore scripts exist
- [x] Unsigned local `.pkg` builds successfully and excludes local secrets/generated certs
- [ ] `.pkg` is not verified as signed, notarized, and clean-machine tested
- [x] Backup/restore scripts no longer use the stale `$HOME/wizard-ai` path
- [x] Backup covers the current configured/legacy Qdrant collections without renaming live data
- [x] Restore supports dry-run before writing Qdrant points
- [x] Preflight backup/restore has a real disposable restore test against a running Qdrant stack

### v1.0 — Stable Laptop Release

Status: Not done.

v1.0 means a normal laptop can install, start, stop, update, and recover the system without manual debugging.

- [x] Core profile installs and starts cleanly on this laptop
- [x] Same-machine clean reset works with guarded uninstaller + fresh core reinstall
- [x] Same-machine unsigned `.pkg` install works with `v0.8.6` package artifact
- [x] Docker Desktop and Ollama prerequisites are detected with clear instructions
- [x] `wizard doctor` checks Docker, Ollama, ports, disk, RAM, `.env`, models, and service health
- [x] Core install completes within a documented time budget
- [x] Installer supports selectable profiles: core, search, automation, coding, security, ops, full
- [x] Hardware tier detection chooses conservative defaults without blocking manual override
- [x] `scripts/update.sh` and `scripts/upgrade.sh` support macOS native Ollama and do not start Docker Ollama accidentally
- [x] Backup and restore are tested against the current running Qdrant stack
- [x] End-to-end live validation covers core mode on this 8 GB Mac
- [x] README shows laptop-first install, not full-stack-first install
- [ ] Signed/notarized `.pkg` is tested on a clean macOS machine
- [x] GitHub release includes tested artifacts and changelog

## Immediate Priority

### 1. Create Laptop Core Mode

- [x] Add profile config so default startup intent does not include OpenHands, n8n, Perplexica, SearXNG, nginx, fail2ban, or watchtower
- [x] Add `HOME_AI_PROFILE` or equivalent install option
- [x] Add installer options for core, developer, workstation, server, and custom installs
- [x] Add `scripts/start-core.sh`
- [x] Add `scripts/start-search.sh`
- [x] Add `scripts/start-automation.sh`
- [x] Add `scripts/start-coding.sh`
- [x] Add `scripts/start-full.sh`
- [x] Update `wizard start` to start core mode by default
- [x] Add `wizard start full` for users who intentionally want everything

### 2. Add `wizard doctor`

- [x] Check Docker CLI availability
- [x] Check Docker Desktop/running state
- [x] Check native Ollama availability on macOS
- [x] Check RAM and disk
- [x] Check localhost binding safety
- [x] Check `.env` required keys
- [x] Check recommended models are installed or give exact pull commands
- [x] Print one clear next command

### 3. Define Merlin/Magic Mode Architecture

- [ ] Keep agent orchestration optional until core mode is stable
- [x] Add Merlin persona seed for local-first AI engineering team behavior
- [x] Add Merlin guardian ethos with consent and safety boundaries
- [x] Define Magic Mode task routing: general, search, code, automation, memory
- [x] Define approval rules for code execution, shell commands, file writes, and network access
- [x] Decide whether orchestration lives in n8n, a Python controller, LangGraph-style graphs, or a hybrid
- [x] Add trace/log output schema for routing decisions
- [x] Add read-only Merlin route dry-run command
- [x] Add opt-in redacted JSONL trace writes for Merlin dry-run decisions
- [x] Add non-executing approval request object for risky Merlin routes
- [x] Persist pending Merlin approval requests to redacted local JSONL audit log
- [x] Add read-only Merlin approval list command
- [x] Add non-executing Merlin approval approve/deny audit commands
- [x] Add read-only Merlin status command for profile, hardware, services, and approvals
- [x] Add canonical/legacy memory schema and runtime Qdrant collection manifest
- [x] Align `cli/wizard` memory commands with the runtime collection manifest
- [ ] Connect Magic Mode to shared Qdrant memory only after memory approval/audit is implemented

### 4. Fix Backup/Restore

- [x] Remove stale `$HOME/wizard-ai` path
- [x] Back up current `.env` from repo root
- [x] Back up actual configured Qdrant collections
- [x] Back up n8n only when automation profile is enabled
- [x] Add restore dry-run mode
- [x] Test restore from a real generated backup

### 5. Make Tests Match Profiles

- [x] Memory config smoke test: manifest and restore dry-run
- [x] Doctor model smoke test: installed/missing model reporting
- [x] Wizard memory config smoke test
- [x] Installer profile mapping smoke test
- [x] Core live smoke test: Ollama, Open WebUI, LiteLLM, Qdrant, dashboard
- [x] Qdrant live restore smoke test with a disposable collection
- [x] Update/upgrade profile smoke test
- [x] Backup profile selection smoke test
- [x] Upgrade rollback smoke test
- [x] Installer model-pull policy smoke test
- [x] Core install budget smoke test
- [x] Package readiness smoke test
- [x] Package signing preflight smoke test
- [x] Uninstaller smoke test
- [x] launchd core-profile auto-start smoke test
- [x] Release workflow smoke test
- [x] Static smoke tests run in CI
- [x] Search static test: Perplexica + SearXNG profile wiring
- [ ] Search live test: Perplexica, SearXNG
- [x] Automation static test: n8n and workflow import safety
- [x] Merlin persona smoke test
- [x] Merlin policy approval-gate smoke test
- [x] Merlin routing smoke test
- [x] Merlin orchestration decision smoke test
- [x] Merlin trace schema smoke test
- [x] Merlin dry-run control-plane smoke test
- [x] Merlin dry-run trace-write smoke test
- [x] Merlin approval request smoke test
- [x] Merlin approval persistence smoke test
- [x] Merlin approval list smoke test
- [x] Merlin approval decision smoke test
- [x] Merlin status smoke test
- [ ] Automation live test: n8n health and workflow import
- [x] Coding static test: OpenHands profile safety and LiteLLM wiring
- [ ] Coding live test: OpenHands startup and LiteLLM connection
- [x] Upgrade static test: backup, pull, restart, health check, rollback path
- [ ] Upgrade live test: backup, pull, restart, health check, rollback path

## Later Roadmap

## Latest Core Validation

Validated on 2026-05-05 on this 8 GB Mac:

- `install.sh --profile core --skip-model-pulls --non-interactive` completed successfully.
- `pkg/scripts/uninstall.sh --yes --keep-files --remove-data --keep-receipt` reset core containers and Docker volumes without deleting the repo.
- Fresh reinstall regenerated `.env`, reran bootstrap, and recreated Qdrant memory collections.
- Unsigned `v0.8.6` package installed locally through macOS Installer, ran postinstall, started the core profile, installed core-only launchd agents, and passed live validation.
- `tests/core-install-budget-smoke.sh` completed the core installer in 95 seconds against a 600 second budget, then passed live core smoke.
- Docker Desktop core services were running: dashboard `:8888`, Open WebUI `:3000`, LiteLLM `:4000`, and Qdrant `:6333`.
- Native Ollama was running through Homebrew service.
- Approved model `qwen2.5:7b` was installed and answered locally through Ollama.
- LiteLLM listed configured model aliases and routed `qwen7b` to local Ollama successfully.
- `wizard doctor` / `scripts/doctor.sh` finished with 43 passes, 2 warnings, and 0 failures.

Remaining warnings are expected for the low-memory profile: recommended optional models are not all installed, and heavier profiles remain unverified on this laptop.

### v1.1 — Search and Automation Quality

- [ ] Verify Perplexica + SearXNG end to end
- [ ] Add search quality test queries
- [ ] Add n8n retry/timeout patterns for Ollama calls
- [ ] Add workflow validation command
- [ ] Document expected limitations vs cloud Perplexity

### v1.2 — Agent and Coding Workflow

- [ ] Verify OpenHands against a local repository
- [ ] Make GitHub token setup explicit and optional
- [ ] Add coding profile resource warnings
- [ ] Add model recommendation for code tasks

### v1.3 — Memory Quality

- [x] Define canonical/legacy Merlin memory collection schema
- [ ] Define final Qdrant payload schema for canonical collections
- [ ] Add memory cleanup command
- [ ] Add memory ingest and recall tests
- [ ] Add benchmark harness for recall quality

### v1.4 — Packaging and Release

- [ ] Signed and notarized `.pkg`
- [ ] Clean Mac smoke test
- [ ] One-line install verified
- [ ] Release artifact attached to GitHub release
- [ ] Changelog finalized

### v1.5 — Expanded Modalities

Only after the laptop core is stable:

- [ ] Voice interface
- [ ] Document ingestion
- [ ] Image generation profile
- [ ] Multi-machine sync
- [ ] Mobile shortcut/webhook companion
