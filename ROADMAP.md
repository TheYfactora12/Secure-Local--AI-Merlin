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

## 🔲 v0.5 — macOS PKG Installer
- [ ] `pkg/build-pkg.sh` — sign & notarize a `.pkg` with pkgbuild
- [ ] Pre-install script: preflight checks (macOS version, RAM, disk space)
- [ ] Post-install script: runs install.sh + bootstrap.sh silently
- [ ] LaunchAgent installed by the pkg
- [ ] Uninstaller bundled inside the pkg

## 🔲 v0.6 — Production Hardening
- [ ] Nginx reverse proxy with HTTPS (self-signed + Let's Encrypt)
- [ ] Fail2ban for Open WebUI brute-force protection
- [ ] Watchtower for automatic Docker image updates
- [ ] Automated daily backups with retention policy
- [ ] Healthcheck webhook (ping uptime monitor on success)

## 🔲 v0.7 — Model Management UI
- [ ] Web UI for model browsing, pulling, deletion
- [ ] One-click model tier switching (8GB / 16GB / 32GB / 64GB)
- [ ] Bandwidth-aware pull scheduler
