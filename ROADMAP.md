# WIZARD AI Stack — Roadmap

## ✅ v0.1 — Foundation
- [x] Repo scaffolding & folder structure
- [x] `docker-compose.yml` — 8 services wired together
- [x] `.env.example` — all variables documented
- [x] `README.md` — architecture, hardware tiers, commands
- [x] `scripts/` — status, stop, restart, update, backup, add-model

## ✅ v0.2 — Full Stack Config
- [x] `install.sh` — RAM-aware, 4 model tiers, health checks, dashboard
- [x] `configs/litellm/config.yaml` — local-first model router
- [x] `configs/searxng/settings.yml` — private web search
- [x] `configs/perplexica/config.toml` — AI-powered search frontend
- [x] `n8n-workflows/ai-router.json` — starter automation workflow
- [x] `mcp/install-mcp-servers.sh` — GitHub + Qdrant MCP connectors

## ✅ v0.3 — First-Boot Automation
- [x] `scripts/init-qdrant.sh` — auto-create 4 Qdrant collections
- [x] `scripts/import-n8n-workflows.sh` — auto-import via REST API
- [x] `scripts/bootstrap.sh` — orchestrates full first-boot init
- [x] `launchd/` — macOS auto-start on login (Docker + all services)
- [x] `launchd/install-launchd.sh` — one-command setup + uninstall

## ✅ v0.4 — CI/CD + Safe Upgrades
- [x] `.github/workflows/ci.yml` — ShellCheck, compose validate, JSON/YAML lint
- [x] `scripts/upgrade.sh` — backup → pull → restart → health check → auto-rollback
- [x] `.github/workflows/release.yml` — auto-tag GitHub releases on main

## ✅ v0.5 — macOS PKG Installer
- [x] `pkg/build-pkg.sh` — sign & notarize a `.pkg` with pkgbuild
- [x] Pre-install script: preflight checks (macOS version, RAM, disk space)
- [x] Post-install script: runs install.sh + bootstrap.sh silently
- [x] LaunchAgent installed by the pkg
- [x] Uninstaller bundled inside the pkg
> ⚠️  Real-hardware test on a clean Mac still needed to fully close this out.

## ✅ v0.6 — QC Hardening & Test Layer
- [x] `tests/e2e-test.sh` — service health end-to-end validation
- [x] `tests/README.md` — how to run tests, expected output, failure guide
- [x] `.gitleaks.toml` — secret scanning config
- [x] CI: `tests/` + `pkg/scripts/` syntax check added
- [x] CI: secret scan job (gitleaks + pattern check)

## ✅ v0.7 — Security Hardening
- [x] `configs/nginx/nginx.conf` — Nginx TLS reverse proxy, HTTP→HTTPS redirect, rate limiting
- [x] `configs/fail2ban/jail.local` — Fail2ban: 5 failures = 1hr ban
- [x] `configs/fail2ban/filter.d/open-webui.conf` + `n8n.conf`
- [x] `docker-compose.yml` — Nginx, Fail2ban, Watchtower added
- [x] `launchd/com.homeai.backup.plist` — daily 2am backup timer
- [x] `scripts/generate-certs.sh` — self-signed TLS cert generator
- [x] `scripts/healthcheck.sh` — full stack health + optional webhook ping

## ✅ v0.8 — Wizard Brain + Model Management (DONE)
- [x] Brain renamed to **Wizard** — consistent across all containers, scripts, and workflows
- [x] `config/models/models.json` — declarative model manifest (required/optional, role, size)
- [x] `install.sh` reads `models.json` — no script editing needed to add/remove models
- [x] `dashboard/index.html` — Wizard HQ: live health dots, Ask panel, routing map, model status, activity log
- [x] `cli/wizard` — full CLI: `wizard ask`, `wizard route`, `wizard pull`, `wizard train`, `wizard backup`, `wizard open`, `wizard status`
- [x] CLI symlinked system-wide on install (available as `wizard` anywhere in terminal)
- [x] `backup/backup.sh` + `backup/restore.sh` — Qdrant memory + n8n workflow backup/restore
- [x] `config/mcp/mcp-claude-desktop.json` — Claude Desktop MCP integration ready to paste
- [x] `config/mcp/vscode-continue.json` — VS Code Continue extension config

## ✅ v0.9 — Agent + Routing Layer (DONE)
- [x] `n8n-workflows/01-smart-task-router.json` — Wizard classifies SENSITIVE/CODING/RESEARCH/GENERAL, routes accordingly
- [x] `n8n-workflows/02-daily-briefing.json` — 6AM InfoSec briefing (Perplexity news + local checklist)
- [x] `n8n-workflows/03-wizard-memory-ingestor.json` — RAG: embed docs into Qdrant via nomic-embed-text
- [x] `n8n-workflows/04-wizard-training-capture.json` — Wizard self-scores exchanges, saves quality ≥7 to memory
- [x] `n8n-workflows/05-wizard-health-monitor.json` — 15-min health check on brain + memory
- [x] SENSITIVE tasks: hardcoded local-only — never reach cloud APIs regardless of key configuration
- [x] All workflows use Wizard brain container hostname (`wizard`) for internal routing

## 🔲 v1.0 — Signed Release (NEXT)
- [ ] Signed + notarized `.pkg` tested on clean macOS 14+ machine
- [ ] `install.sh` updated to reference new `cli/`, `dashboard/`, `backup/`, `config/` paths
- [ ] Full install-to-verify under 30 minutes — documented and timed
- [ ] GitHub Release with `.pkg` artifact and `WIZARD-AI-Installer-v4.zip` attached
- [ ] One-line install command in README: `curl -fsSL https://raw.githubusercontent.com/TheYfactora12/home-ai-elite/main/install.sh | bash`
- [ ] CHANGELOG.md covering v0.1 → v1.0
- [ ] Security review: no hardcoded secrets, all ports documented, firewall rules verified
- [ ] Clean Mac smoke test: Docker → wizard start → wizard status → all green

## 🔲 v1.1 — Intelligence Upgrades (FUTURE)
- [ ] Wizard voice interface (Whisper STT → Mistral → TTS output)
- [ ] Wizard scheduled tasks (n8n cron → Wizard executes → result to memory)
- [ ] Wizard fine-tuning pipeline (export training data from Qdrant → Unsloth/LoRA)
- [ ] Multi-machine Wizard sync (Qdrant replication across 2+ local machines)
- [ ] Wizard mobile companion (iOS shortcut → n8n webhook → Wizard brain)

---
> **Rule:** Any new feature, bug found, or variation discovered gets added here before code is written.
> Maintained by: TheYfactora12 | Oxford, MA
