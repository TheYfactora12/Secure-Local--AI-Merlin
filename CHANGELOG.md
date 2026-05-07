# Changelog

All notable changes to Home AI Elite are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased] — v2.0 Merlin Staff Core

### In Progress
- **#56 — Phase 2A:** Persona Injector + Staff Mode Selector
- **#57 — Phase 2B:** Policy Engine + Audit Trail
- **#58 — Phase 2C:** Memory Bridge + Session Context (MSC-4)
- **#59 — Phase 2D:** Staff Mode Integration Tests
- **#60 — Phase 2E:** Staff Router + Swarm Coordinator Integration

### What v2.0 Delivers
- 6 fully operational Merlin staff modes (Architect, AI Engineer, Software Engineer, Security Reviewer, Product Designer, Operator)
- Policy-gated model routing per staff mode
- Full audit trail on every routing decision written to `merlin-audit` collection
- Low-memory fallback to `mistral:7b` with warnings
- Cloud model hard block unless explicitly approved

---

## [1.0.0] — 2026-05-06 — Merlin Core Baseline

**v1.0 milestone closed.** All 9/9 acceptance issues resolved.

### Added
- `install.sh` — production-grade local AI installer with RAM tier detection
- Profile-aware startup: `core`, `search`, `automation`, `coding`, `security`, `ops`, `full`
- `wizard doctor` — health check CLI with degraded mode detection
- Merlin config validation on startup
- Hardware tier detection and warnings (8GB / 16GB / 32GB+ Mac tiers)
- Local-only mode by default — no cloud calls without explicit user opt-in
- Provider registry skeleton
- Model router skeleton using LiteLLM aliases
- Dashboard status cards with live service health
- Controlled memory design with Qdrant — write requires approval
- Magic Mode v1 — plan-only, no execution without gate
- Approval model — all shell/file/git/network/cloud actions require explicit approval
- Redacted audit log format — secrets never appear in logs
- `wizard merlin ask` — thin local wrapper over task path
- Route and approval display in CLI output
- Fresh install smoke test (macOS, M-series, 2026-05-06)
- CI gate passing on all 9 milestone issues

### Fixed
- **#48** — Non-interactive status API honesty fix (degraded state now accurately reported)
- **#49** — Package postinstall stale runtime markers cleared

### Architecture Decisions (v1.0)
- Wrap Ollama, LiteLLM, Open WebUI, Qdrant, n8n — do not replace
- Config root: `configs/` — `config/` intentionally forbidden until Phase 2
- n8n remains optional workflow surface only — not Merlin’s primary brain
- Magic Mode execution gates: shell, file, git, network, cloud, memory writes all blocked without approval

### Known Limitations (carried to v2.0)
- No backend API for dashboard (static only)
- No auth or service control model in dashboard
- n8n/OpenHands safety approval layer not yet unified
- Memory schema and Qdrant collection naming inconsistent across services
- Hardware tier limits not yet enforced in dashboard or CLI

---

## [0.x] — Pre-Release

Pre-release development. No formal versioning.
Core installer, Docker services, Ollama model support, LiteLLM routing, n8n workflows, and dashboard scaffolding established during this phase.

See `docs/archive/` for baseline review snapshots and pre-v1.0 stress test outputs.
