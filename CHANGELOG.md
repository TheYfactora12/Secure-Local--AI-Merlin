# Changelog

All notable changes to **Home AI Elite / Wizard AI Stack** are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased] — v1.0 Release Candidate

### In Progress
- Clean Mac smoke test (macOS 14+): Docker → `bash install.sh` → `wizard status` → all green
- GitHub Release with signed `.pkg` artifact and `WIZARD-AI-Installer-v4.zip`
- One-line install: `curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh | bash`

---

## [0.9.1] — 2026-05-02

### Security (install.sh v0.4.1)
- **`read -rs` silent input** for all cloud API key prompts — keys never appear on screen or in terminal history
- **Input validation** before any key is written to `.env`: rejects spaces, enforces minimum 8-char length, retries on bad input
- **`chmod 600 .env`** applied immediately on file creation — owner read/write only, no world/group access
- **Expanded insecure-default detection** in `rotate_secret()` — catches new `.env.example` placeholder string
- **`.env.example` hardened** with `⛔ INSECURE DEFAULT` markers, `openssl rand -hex 32` instructions on every required secret, direct URLs for all cloud API key portals
- **Auto-rotates 4 secrets**: `WEBUI_SECRET_KEY`, `LITELLM_MASTER_KEY`, `N8N_PASSWORD`, `SEARXNG_SECRET_KEY`

### Project
- **5 GitHub Issues created** from ROADMAP.md open items (was 0) — Issues #1–#5
- Issue #1: v1.0 Signed Release (critical)
- Issue #2: `wizard doctor` preflight (high)
- Issue #3: n8n Ollama retry logic (high)
- Issue #4: Qdrant memory schema + session bridge (high)
- Issue #5: Hardware guide + free stack map (medium)

---

## [0.9.0] — Agent + Routing Layer

### Added
- `n8n-workflows/01-smart-task-router.json` — classifies SENSITIVE / CODING / RESEARCH / GENERAL
- `n8n-workflows/02-daily-briefing.json` — 6AM InfoSec briefing workflow
- `n8n-workflows/03-wizard-memory-ingestor.json` — RAG: embed docs into Qdrant
- `n8n-workflows/04-wizard-training-capture.json` — self-scores exchanges, saves quality ≥7
- `n8n-workflows/05-wizard-health-monitor.json` — 15-min stack health check
- SENSITIVE task routing: hardcoded local-only, never reaches cloud APIs
- All workflows use `wizard` container hostname for internal routing

---

## [0.8.0] — Wizard Brain + Model Management

### Added
- **Brain renamed to Wizard** — consistent naming across all containers, scripts, workflows
- `config/models/models.json` — declarative model manifest (required/optional, role, RAM size)
- `install.sh` reads `models.json` — no script editing needed to add/remove models
- `dashboard/index.html` — Wizard HQ: live health dots, Ask panel, routing map, model status, activity log
- `cli/wizard` — full CLI: `wizard ask`, `wizard route`, `wizard pull`, `wizard train`, `wizard backup`, `wizard open`, `wizard status`
- CLI symlinked system-wide on install (`wizard` available anywhere in terminal)
- `backup/backup.sh` + `backup/restore.sh` — Qdrant memory + n8n workflow backup/restore
- `config/mcp/mcp-claude-desktop.json` — Claude Desktop MCP integration
- `config/mcp/vscode-continue.json` — VS Code Continue extension config

---

## [0.7.0] — Security Hardening

### Added
- `configs/nginx/nginx.conf` — Nginx TLS reverse proxy, HTTP→HTTPS redirect, rate limiting
- `configs/fail2ban/jail.local` — 5 failures = 1hr ban
- `configs/fail2ban/filter.d/open-webui.conf` + `n8n.conf` — service-specific filters
- `docker-compose.yml` — Nginx, Fail2ban, Watchtower added as services
- `launchd/com.homeai.backup.plist` — daily 2am backup timer
- `scripts/generate-certs.sh` — self-signed TLS cert generator
- `scripts/healthcheck.sh` — full stack health + optional webhook ping

---

## [0.6.0] — QC Hardening & Test Layer

### Added
- `tests/e2e-test.sh` — service health end-to-end validation
- `tests/README.md` — how to run tests, expected output, failure guide
- `.gitleaks.toml` — secret scanning config
- CI: `tests/` + `pkg/scripts/` syntax check
- CI: secret scan job (gitleaks + pattern check)

---

## [0.5.0] — macOS PKG Installer

### Added
- `pkg/build-pkg.sh` — sign & notarize a `.pkg` with `pkgbuild`
- Pre-install script: preflight checks (macOS version, RAM, disk space)
- Post-install script: runs `install.sh` + `bootstrap.sh` silently
- LaunchAgent installed by the pkg
- Uninstaller bundled inside the pkg

### Known Issue
- Real-hardware test on a clean Mac still needed (tracked: Issue #1)

---

## [0.4.0] — CI/CD + Safe Upgrades (install.sh v0.4)

### Added
- `.github/workflows/ci.yml` — ShellCheck, compose validate, JSON/YAML lint
- `scripts/upgrade.sh` — backup → pull → restart → health check → auto-rollback
- `.github/workflows/release.yml` — auto-tag GitHub releases on main

### Security (install.sh v0.4)
- `rotate_secret()` — auto-rotates `WEBUI_SECRET_KEY`, `LITELLM_MASTER_KEY`, `N8N_PASSWORD`, `SEARXNG_SECRET_KEY` if still at insecure defaults
- `prompt_key()` — interactive cloud API key entry with direct portal URLs
- `SEARXNG_SECRET_KEY` generation added (was missing in v0.3)

---

## [0.3.0] — First-Boot Automation (install.sh v0.3)

### Added
- `scripts/init-qdrant.sh` — auto-create 4 Qdrant collections on first boot
- `scripts/import-n8n-workflows.sh` — auto-import via n8n REST API
- `scripts/bootstrap.sh` — orchestrates full first-boot initialization
- `launchd/` — macOS auto-start on login (Docker + all services)
- `launchd/install-launchd.sh` — one-command launchd setup + uninstall

### Fixed
- Replaced fragile `sleep 3` Ollama startup wait with polling loop (60s timeout)

---

## [0.2.0] — Full Stack Config

### Added
- `install.sh` — RAM-aware installer: 4 model tiers (8/16/24/48+ GB), health checks, dashboard
- `configs/litellm/config.yaml` — local-first model router with cloud fallback
- `configs/searxng/settings.yml` — private web search (no telemetry)
- `configs/perplexica/config.toml` — AI-powered search frontend
- `n8n-workflows/ai-router.json` — starter automation workflow
- `mcp/install-mcp-servers.sh` — GitHub + Qdrant MCP connectors

---

## [0.1.0] — Foundation

### Added
- Repo scaffolding and folder structure
- `docker-compose.yml` — 8 services wired together (Ollama, Open WebUI, Perplexica, SearXNG, LiteLLM, n8n, Qdrant, OpenHands)
- `.env.example` — all variables documented with tier guidance
- `README.md` — architecture diagram, hardware tiers, quick-start commands
- `scripts/` — status, stop, restart, update, backup, add-model

---

> Maintained by: TheYfactora12 | Oxford, MA
> Repo: https://github.com/TheYfactora12/home-ai-elite
