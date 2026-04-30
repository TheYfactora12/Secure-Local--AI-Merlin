# Home AI Elite Roadmap

## v0.1 — Current (bootstrap)
- [x] Interactive install.sh with prompts and manual checkpoints
- [x] Preflight checks (RAM, disk, ports)
- [x] Docker Compose for Open WebUI, Qdrant, n8n
- [x] Optional OpenHands container
- [x] scripts/ for bootstrap, status, stop, restart, backup, update, uninstall
- [x] Starter AGENTS.md template
- [x] Starter n8n AI router workflow (Ollama / Perplexity / OpenAI branching)
- [x] MCP install helpers for filesystem, GitHub, Qdrant
- [x] Codex MCP config template

## v0.2 — Next
- [ ] Qdrant collection auto-initialization on first run
- [ ] n8n starter workflow auto-import via CLI
- [ ] Port conflict auto-resolution or alternate port prompts
- [ ] launchd plist for auto-start on login
- [ ] Model selection menu showing available Ollama models
- [ ] Health check with auto-restart on failure

## v0.3 — Growing
- [ ] Perplexity Computer skill file generator
- [ ] Overnight loop workflow template
- [ ] Signed macOS .pkg installer wrapper
- [ ] Model benchmark helper (toks/sec test on installed models)
- [ ] Restore from backup mode

## v1.0 — Full release
- [ ] Cross-platform support (Linux)
- [ ] GUI setup wizard (Electron or Tauri)
- [ ] Auto-update via GitHub Releases
- [ ] Plugin architecture for additional services
