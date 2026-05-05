# Home AI Elite — Roadmap

This roadmap tracks what is actually verified, what is only scaffolded, and what must be streamlined before calling the project stable.

## Current Reality

Home AI Elite has a broad prototype stack, but it is not yet a laptop-stable v1.0 product. The main architecture problem is that the "full stack" became the default startup path. On a normal Mac or PC, that creates too much install friction, memory pressure, port usage, and failure surface.

The next milestone is not more features. The next milestone is a reliable laptop-first core that can run before optional services are enabled. From there, the same repo should scale up based on hardware tier and install profile.

## Architecture Direction

### Install Philosophy

The installer should ask or infer what kind of machine it is running on, then enable the right amount of stack.

- [ ] Small laptop install: core services only, lowest memory pressure
- [ ] Developer laptop install: core + optional coding/search profiles
- [ ] Desktop/workstation install: full local stack with larger models
- [ ] Home server install: auto-start, backups, nginx, automation, and monitoring
- [ ] Advanced/manual install: user-selected profiles and ports

The same project should support all of these without maintaining separate forks.

### Default Core

These should be the only services required for the first successful install:

- [ ] Native Ollama on macOS for Metal acceleration
- [ ] Open WebUI for the primary chat UI
- [ ] LiteLLM for model routing
- [ ] Qdrant for memory/RAG storage
- [ ] Wizard dashboard/status page
- [ ] `wizard doctor` or equivalent preflight check

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

Status: Mostly done, needs simplification.

- [x] Repository structure exists
- [x] Docker Compose stack exists
- [x] `.env.example` exists
- [x] Basic scripts exist: status, stop, restart, update, backup, add-model
- [x] README explains intended architecture
- [ ] Compose default should be reduced to a laptop-safe core
- [ ] Ports and service list should match docs consistently

### v0.2 — Full Stack Prototype

Status: Scaffolded, not yet reliable as a default laptop install.

- [x] Perplexica config exists
- [x] SearXNG config exists
- [x] LiteLLM config exists
- [x] OpenHands service exists
- [x] RAM-aware installer logic exists
- [ ] Heavy services must move behind Compose profiles
- [ ] Image tags using `latest`, `main`, or `main-latest` need pinning or documented upgrade policy
- [ ] Full stack startup needs clean Mac/PC validation after core mode works
- [ ] Installer should support profile selection by hardware tier and user choice

### v0.3 — First-Boot Automation

Status: Partial.

- [x] Qdrant init script exists
- [x] Bootstrap script exists
- [x] n8n workflow import script exists
- [x] launchd scripts exist
- [ ] n8n workflow import is not truly automatic unless `N8N_API_KEY` exists
- [ ] Bootstrap should support core-only, search, automation, and coding profiles
- [ ] launchd should not auto-start the entire heavy stack by default
- [ ] Bootstrap should be idempotent for each profile independently

### v0.4 — macOS Package, Backup, Restore

Status: Scaffolded, not release-ready.

- [x] `.pkg` build script exists
- [x] Package preinstall/postinstall scripts exist
- [x] Backup and restore scripts exist
- [ ] `.pkg` is not verified as signed, notarized, and clean-machine tested
- [ ] Backup/restore scripts need path cleanup and collection alignment with current Qdrant schema
- [ ] Preflight backup/restore needs a real restore test

### v1.0 — Stable Laptop Release

Status: Not done.

v1.0 means a normal laptop can install, start, stop, update, and recover the system without manual debugging.

- [ ] Core profile installs and starts cleanly on this laptop
- [ ] Docker Desktop and Ollama prerequisites are detected with clear instructions
- [ ] `wizard doctor` checks Docker, Ollama, ports, disk, RAM, `.env`, models, and service health
- [ ] Core install completes within a documented time budget
- [ ] Installer supports selectable profiles: core, search, automation, coding, security, ops, full
- [ ] Hardware tier detection chooses conservative defaults without blocking manual override
- [ ] `scripts/update.sh` and `scripts/upgrade.sh` support macOS native Ollama and do not start Docker Ollama accidentally
- [ ] Backup and restore are tested against the current running stack
- [ ] End-to-end test covers core mode first, then optional profiles separately
- [ ] README shows laptop-first install, not full-stack-first install
- [ ] Signed/notarized `.pkg` is tested on a clean macOS machine
- [ ] GitHub release includes tested artifacts and changelog

## Immediate Priority

### 1. Create Laptop Core Mode

- [x] Add profile config so default startup intent does not include OpenHands, n8n, Perplexica, SearXNG, nginx, fail2ban, or watchtower
- [ ] Add `HOME_AI_PROFILE` or equivalent install option
- [ ] Add installer prompts/options for core, developer, workstation, server, and custom installs
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
- [ ] Check selected models are installed or give exact pull commands
- [x] Print one clear next command

### 3. Define Merlin/Magic Mode Architecture

- [ ] Keep agent orchestration optional until core mode is stable
- [ ] Define Magic Mode task routing: general, search, code, automation, memory
- [ ] Define approval rules for code execution, shell commands, file writes, and network access
- [ ] Decide whether orchestration lives in n8n, a Python controller, LangGraph-style graphs, or a hybrid
- [ ] Add trace/log output for routing decisions
- [ ] Connect Magic Mode to shared Qdrant memory only after memory schema is stable

### 4. Fix Backup/Restore

- [ ] Remove stale `$HOME/wizard-ai` path
- [ ] Back up current `.env` from repo root
- [ ] Back up actual configured Qdrant collections
- [ ] Back up n8n only when automation profile is enabled
- [ ] Add restore dry-run mode
- [ ] Test restore from a real generated backup

### 5. Make Tests Match Profiles

- [ ] Core test: Ollama, Open WebUI, LiteLLM, Qdrant, dashboard
- [ ] Search test: Perplexica, SearXNG
- [ ] Automation test: n8n health and workflow import
- [ ] Coding test: OpenHands startup and LiteLLM connection
- [ ] Upgrade test: backup, pull, restart, health check, rollback path

## Later Roadmap

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

- [ ] Define Qdrant payload schema
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
