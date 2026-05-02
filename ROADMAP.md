# home-ai-elite Roadmap

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
> ⚠️  Security hardening items (Nginx, Fail2ban, Watchtower, backup timer) moved to v0.7.

## 🔲 v0.7 — Security Hardening (NEXT)
- [ ] Nginx reverse proxy + self-signed TLS for all local services
- [ ] Fail2ban protecting Open WebUI (brute-force login protection)
- [ ] Watchtower for automatic Docker image security updates
- [ ] `launchd/com.homeai.backup.plist` — daily backup timer (7-day retention)
- [ ] Healthcheck webhook to uptime monitor (Uptime Kuma or similar)
- [ ] `scripts/healthcheck.sh` — sends ping on stack health pass

## 🔲 v0.8 — Model Management UI
- [ ] Local web UI for model browsing, pulling, deletion
- [ ] One-click model tier switching (8GB / 16GB / 32GB / 64GB profiles)
- [ ] Bandwidth-aware pull scheduler (avoid large pulls during work hours)
- [ ] Model usage dashboard (which models called, how often, latency)

## 🔲 v0.9 — MCP + Agent Layer
- [ ] Fully tested MCP server installs (GitHub, Qdrant, filesystem, fetch)
- [ ] Claude Desktop config auto-generated from `.env`
- [ ] n8n agent workflow: triage → route → respond → log to Qdrant
- [ ] Perplexica connected to local Ollama (zero cloud dependency mode)
- [ ] SearXNG verified as Perplexica backend (no OpenAI required)

## 🔲 v1.0 — Signed Release
- [ ] Signed + notarized `.pkg` tested on clean macOS 14+ machine
- [ ] Full install-to-verify under 30 minutes documented and timed
- [ ] GitHub Release with `.pkg` artifact attached
- [ ] One-line install command published in README
- [ ] CHANGELOG.md covering v0.1 → v1.0
- [ ] Security review: no hardcoded secrets, all ports documented, firewall rules
