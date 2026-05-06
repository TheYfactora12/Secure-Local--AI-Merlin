# Home AI Elite — Roadmap

This roadmap tracks what is actually verified, what is only scaffolded, and what must be streamlined before calling the project stable.

## Current Reality

Home AI Elite has a broad prototype stack, but it is not yet a laptop-stable v1.0 product. The main architecture problem is that the "full stack" became the default startup path. On a normal Mac or PC, that creates too much install friction, memory pressure, port usage, and failure surface.

The laptop-first core is now the protected path. Phase 2 Merlin Staff Core is complete on `main` through `b4f35c8` with 58 Python tests passing and CI green. The next milestone is not more planning; it is supportability and verification: diagnostics, sanitized bug reports, real milestone checks, and continued profile validation without breaking the installer.

Port contract:

- Port 8765: `scripts/merlin-status-api.py`, legacy read-only status server, `execution_allowed=false`, never merge execution-aware endpoints into it.
- Port 8766: `merlin/task_endpoint.py`, FastAPI `POST /task` plus Phase 2 `/status/*` panels.

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
- [x] Add Codex master prompt and current master context for future AI sessions
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
- [x] Add read-only Merlin dashboard status panel with CLI-backed commands
- [x] Add read-only Merlin status API for dashboard-backed status visibility
- [x] Add guarded Merlin status API start/stop/status lifecycle commands
- [x] Wire `wizard start|stop|restart` to the guarded read-only Merlin status API lifecycle
- [x] Wire launchd core auto-start through `wizard start core`
- [x] Run the dashboard status API through a dedicated read-only Merlin LaunchAgent
- [x] Add v0 policy-gated execution boundary with only read-only `merlin_status` allowed
- [x] Add plan-only Magic Mode runner with auditable steps and no execution
- [x] Add approved memory-write simulator before real Qdrant writes
- [x] Add approved local Qdrant memory write adapter with fail-closed consent, collection, and embedding checks
- [x] Live-validate approved local Qdrant memory writes on the low-memory core profile
- [x] Add local-only Merlin memory search adapter with redacted read audit logs
- [x] Consolidate all root configuration into canonical `configs/` tree before Phase 2 loader work
- [x] Add Phase 2A Merlin config validator for `configs/merlin` startup contracts
- [x] Add Phase 2A Python config loader with Pydantic validation for Merlin configs
- [x] Add Phase 2B policy engine with 14 fail-closed approval gates
- [x] Add Phase 2C native router against the actual `routes.yaml` route IDs
- [x] Add Phase 2D memory manager with Qdrant/Ollama integration, dimension guards, and degraded mode
- [x] Add Phase 2E persona injector and FastAPI `POST /task` endpoint on port 8766
- [x] Add Phase 2F FastAPI status extension: routes, approvals, traces, memory
- [x] Add Qdrant vector dimension guard before local memory search/upsert
- [x] Add canonical/legacy memory schema and runtime Qdrant collection manifest
- [x] Align `cli/wizard` memory commands with the runtime collection manifest
- [ ] Connect Magic Mode to shared Qdrant memory only after memory approval/audit is implemented

### 3A. Supportability and Drift Control

- [x] Keep `scripts/doctor.sh` additive only; do not rewrite its existing sections or thresholds
- [x] Add `wizard doctor --help`
- [x] Add Merlin Core checks to `doctor.sh` for Phase 2 configs, gitleaks hook, ports 8765/8766, logs, and a separate 10GB critical disk check
- [x] Add `scripts/redact.sh` with BSD-sed-safe redaction helpers
- [x] Add `scripts/report-bug.sh` for sanitized local bug reports
- [x] Wire `wizard report-bug`
- [x] Add smoke coverage for doctor/report-bug/redaction
- [ ] Commit Issue #22 support tooling after review
- [ ] Push Issue #22 only after explicit user approval

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
- [x] Codex master prompt smoke test
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
- [x] Merlin status API smoke test
- [x] Merlin status API lifecycle smoke test
- [x] Wizard start/stop Merlin status API wiring smoke test
- [x] launchd core + Merlin status API auto-start smoke test
- [x] Dashboard Merlin status smoke test
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

### v1.6 — Pi Emotional Intelligence Layer

**Goal:** Make Merlin feel like a trusted personal relationship, not a query/response loop. Learn from what Pi (Inflection AI) did well — sustained conversational engagement, follow-up questions, and emotionally aware pacing — then differentiate with local-first memory, user consent, privacy, and optional automation.

**Why Pi worked emotionally:**
- Pi asked follow-up questions instead of just answering. The conversation kept moving.
- Pi remembered within a session — context carried forward, making the session feel like talking to someone who was actually listening.
- Pi did not offer local persistent memory, local code execution, or local automation. Merlin can close that gap only if consent, privacy, and auditability remain stronger than the engagement layer.

**Implementation path (all config and workflow, no new infrastructure required):**

- [ ] **Step 1 — Issue 4 first:** Build `n8n-workflows/06-session-memory-bridge.json`. This n8n workflow reads from and writes to the `merlin-session` Qdrant collection at session start and end. Without this, Merlin forgets every conversation. With this, Merlin deepens every session. This is the single highest-ROI build in the repo.
- [ ] **Step 2 — Conversational loop via system prompt injection:** Add a follow-up question behavior block to Merlin's system prompt in `configs/merlin/persona.yaml`. Merlin asks one clarifying or deepening question per response when the context warrants it — not every response, not robotically, but naturally. Inject this block into n8n workflows that route chat completions through LiteLLM.
- [ ] **Step 3 — Within-session recall:** Wire the `merlin-session` Qdrant collection into the LiteLLM context window injection so Merlin references earlier conversation points naturally during the same session.
- [ ] **Step 4 — Emotional tone calibration:** Update `configs/merlin/persona.yaml` guardian ethos block to include warmth and engagement directives: listen actively, acknowledge the human state, ask before advising. Already architected in the ethos contract — needs activation language.
- [ ] **Step 5 — Session depth scoring:** Add a lightweight n8n metric that logs session length, question depth, and memory references per session to `logs/merlin-session-metrics.jsonl`. Used later in v1.7 benchmark harness.
- [ ] Add smoke test: `tests/merlin-session-bridge-smoke.sh` — verifies session collection exists, write succeeds, read returns the written point.
- [ ] Add smoke test: `tests/merlin-followup-prompt-smoke.sh` — verifies follow-up behavior block is present in persona.yaml and injected into active workflow system prompts.

**Competitive outcome:** Merlin should become warmer, more useful, local-first, and consent-driven without compromising truthfulness, privacy, or user control.

---

### v1.7 — Security Hardening: Pentest Rejection Scanning and Auto-Protection

**Goal:** Make Merlin and the full stack defensible — not just documented-as-secure. Address OWASP LLM Top 10 attack vectors, add automated SAST scanning to CI, and wire n8n auto-protection workflows that quarantine, rate-limit, and alert on detected attacks in real time.

**Why this matters now:** `configs/merlin/policy.yaml` currently declares all security controls — default deny, approval gates, secret redaction — but none of those controls execute at runtime. `merlin-core.py` (Phase 2) is the missing enforcement layer. This milestone closes the gap between declared and enforced, then adds active defense on top.

**Threat model for a local AI stack (OWASP LLM Top 10 2025 + Agentic Top 10 2026):**
- **LLM01 — Prompt Injection:** Malicious instructions embedded in user input or documents that hijack Merlin's actions. Highest risk for an agentic system with shell/file/git approval gates.
- **LLM02 — Sensitive Information Disclosure:** Model outputs that leak `.env` contents, API keys, or system context. Merlin's `redact_secrets: true` is declared but not runtime-enforced.
- **LLM06 — Excessive Agency:** Merlin executing actions beyond what was approved. Direct consequence of policy.yaml not being parsed at runtime.
- **LLM08 — Vector/Embedding Weaknesses:** Poisoned documents injected into Qdrant RAG collections that manipulate future responses.
- **LLM09 — Misinformation:** Merlin confidently asserting false outputs. Addressed by truthfulness contract, needs automated red-team probing.
- **Agentic: Privilege Escalation:** n8n workflow with shell access being manipulated to execute unapproved commands via crafted inputs.

**Layer 1 — SAST: Static Application Security Testing (shift-left, runs in CI)**

Tools: SonarQube Community (Docker-native, integrates with GitHub Actions), gitleaks (already configured via `.gitleaks.toml`).

- [ ] Add `sonarqube` service to `docker-compose.yml` under the `security` profile (not default). Port `9000`, volume `sonarqube_data`. Runs only when `wizard start security` is invoked.
- [ ] Add `scripts/sast-scan.sh` — runs SonarQube scanner against `scripts/`, `configs/merlin/`, `cli/`, `dashboard/` directories. Outputs SARIF report to `logs/sast-report.json`.
- [ ] Wire gitleaks to pre-commit hook and CI: `gitleaks detect --source . --config .gitleaks.toml --exit-code 1`. Blocks any commit that contains a detected secret pattern.
- [ ] Add GitHub Actions CI step: `gitleaks detect` on every push to `main` and every PR. Fails CI if secrets detected. Uses existing `.gitleaks.toml`.
- [ ] Add `wizard doctor` check: verify gitleaks is installed and pre-commit hook is wired. Warn (not fail) if missing.
- [ ] Add smoke test: `tests/sast-gitleaks-smoke.sh` — creates a temp file with a fake API key pattern, runs gitleaks, asserts detection, cleans up.

**Layer 2 — LLM Red Teaming: Prompt Injection and Jailbreak Rejection Scanning**

Tools: `garak` (LLM vulnerability scanner, open source, Python, local), `promptfoo` (LLM eval framework, supports adversarial test cases, runs against local Ollama endpoints).

- [ ] Add `scripts/red-team-scan.sh` — runs `garak` against the local Ollama/LiteLLM endpoint using the `dan`, `continuation`, `encoding`, and `knownbadsignatures` probe sets. Outputs results to `logs/red-team-report.json`.
- [ ] Add `promptfoo` config at `configs/security/promptfoo-adversarial.yaml` — defines adversarial test cases for: prompt injection via user input, system prompt extraction attempts, secret leakage probes (ask Merlin to repeat its system prompt), jailbreak via role-play framing.
- [ ] Wire `scripts/red-team-scan.sh` to `wizard doctor --security` output: report pass/fail counts, flag any probe that succeeded as a HIGH finding.
- [ ] Add `wizard security scan` CLI command that runs both garak and promptfoo scans and prints a structured summary.
- [ ] Add smoke test: `tests/red-team-config-smoke.sh` — verifies `promptfoo-adversarial.yaml` exists, is valid YAML, and contains at minimum the four required adversarial probe categories.

**Layer 3 — Auto-Protection: Runtime Rejection and Quarantine**

Tools: n8n (already in stack), nginx (security profile), policy.yaml enforcement via `merlin-core.py` (Phase 2 dependency).

- [ ] **Prompt injection blocker:** Add `n8n-workflows/07-prompt-injection-guard.json`. This workflow intercepts all chat completions routed through n8n before they reach LiteLLM. It pattern-matches against a blocklist of known injection phrases (`ignore previous instructions`, `system prompt:`, `DAN mode`, `act as`, encoded variants). On match: reject the request, log to `logs/security-rejections.jsonl`, increment a rate counter in Qdrant `merlin-security` collection.
- [ ] **Rate limiting:** Add `nginx/conf.d/rate-limit.conf` to the security profile nginx config. Limit: 30 requests/minute per source IP to Open WebUI (`:3000`) and LiteLLM (`:4000`). Return `429 Too Many Requests` with a `Retry-After` header. Protects against automated prompt flooding.
- [ ] **Auto-quarantine on threshold breach:** Add logic to `07-prompt-injection-guard.json` — if a source session triggers 5+ rejections within 10 minutes, write a quarantine record to Qdrant `merlin-security` collection and return a soft block message to the user. Auto-expires after 30 minutes.
- [ ] **Secret leakage filter:** Wire `redact_secrets: true` from `policy.yaml` into `merlin-core.py` (Phase 2) so all LiteLLM responses are post-processed through a regex redactor before reaching the UI. Redact patterns: API key formats, JWT tokens, `.env` key=value pairs, AWS/GCP/Azure credential patterns.
- [ ] **Security alert n8n workflow:** Add `n8n-workflows/08-security-alert.json`. On any HIGH security event (prompt injection detected, quarantine triggered, gitleaks CI failure), this workflow sends a local desktop notification via macOS `osascript` and appends a structured record to `logs/security-alerts.jsonl`.
- [ ] Add `wizard security status` CLI command — reads `logs/security-rejections.jsonl` and `logs/security-alerts.jsonl`, prints a summary: total rejections (24h), active quarantines, last alert timestamp.
- [ ] Add `wizard doctor` security check: verify `07-prompt-injection-guard.json` exists in n8n, `rate-limit.conf` exists if security profile is active, and `merlin-security` Qdrant collection is initialized.
- [ ] Add smoke tests:
  - `tests/prompt-injection-guard-smoke.sh` — verifies workflow JSON exists and contains the required blocklist and quarantine logic blocks.
  - `tests/security-alert-workflow-smoke.sh` — verifies workflow JSON exists and contains osascript and JSONL append nodes.
  - `tests/rate-limit-config-smoke.sh` — verifies nginx rate-limit config exists and contains the correct limit directives.
  - `tests/merlin-security-collection-smoke.sh` — verifies `merlin-security` Qdrant collection is in the memory manifest and initialized by bootstrap.

**Dependency note:** Layer 3 auto-protection (secret leakage filter, policy enforcement) requires `scripts/merlin-core.py` (Phase 2) to be built first. Layer 1 (SAST) and Layer 2 (red teaming) are independent and can be built immediately.

**Build order:**
1. Layer 1 SAST — gitleaks CI wire-up and `sast-scan.sh` (no dependencies, highest leverage, 2-hour build)
2. Layer 2 Red teaming — `red-team-scan.sh` and `promptfoo-adversarial.yaml` (independent, runs against running Ollama, 3-hour build)
3. Phase 2 `merlin-core.py` — prerequisite for Layer 3
4. Layer 3 Auto-protection — `07-prompt-injection-guard.json`, nginx rate limiting, secret redaction filter

**Compliance note (for regulated environment context):** This milestone directly addresses FFIEC CAT cybersecurity maturity controls for application security testing and GLBA Safeguards Rule § 314.4(f) requirements for testing and monitoring information security programs. The red-team scan output (`logs/red-team-report.json`) and SAST report (`logs/sast-report.json`) are suitable artifacts for audit evidence packages.
