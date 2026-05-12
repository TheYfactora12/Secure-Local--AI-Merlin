# Merlin AI — Your Private AI Stack for macOS

Your private AI. On your Mac. Forever.

Merlin AI installs a fully private local AI stack on Apple Silicon so a normal
Mac user can chat, automate, and inspect status without a cloud account,
subscription, or terminal expertise after setup.

[![Version](https://img.shields.io/badge/version-0.2-blue)](#)
[![License](https://img.shields.io/badge/license-BSL_1.1-green)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13%2B-black)](#requirements)

## What Is Merlin?

- A one-command installer for private AI on your Mac.
- A local assistant that uses owned hardware by default.
- A control screen that shows what is running, what is private, and what to do next.

## What's Included

| Included app | Plain-English purpose |
|---|---|
| Merlin Dashboard | Shows whether your private AI is running and where to start. |
| Open WebUI | The current local chat workspace behind Merlin. |
| Ollama | Runs local AI models on Apple Silicon. |
| LiteLLM | Routes model requests locally first. |
| Qdrant | Stores local search/memory data for retrieval features. |
| n8n | Optional local automation workflows. |
| OpenHands | Optional local coding/task agent. |
| Perplexica | Optional private search workspace. |
| SearXNG | Optional metasearch engine for private search. |
| MCP | Local model/context routing support. |

## Requirements

- Mac with Apple Silicon: M1, M2, M3, or M4.
- macOS 13 or newer.
- Docker Desktop installed and running.
- 16 GB RAM recommended. 8 GB can use the low/core path.
- 50 GB free disk space recommended.

## Install

```bash
git clone https://github.com/TheYfactora12/Secure-Local--AI-Merlin.git
cd Secure-Local--AI-Merlin
bash install.sh
```

## After Install

Merlin opens the local dashboard at:

```text
http://localhost:8888
```

Start here:

1. **Start Chatting** opens the local chat workspace.
2. **Automate** opens optional local workflows.
3. **Dashboard** shows service status and recovery guidance.

Merlin is private by default. Nothing leaves this Mac unless you explicitly add
and enable a cloud provider later.

## Uninstall

```bash
bash pkg/scripts/uninstall.sh
```

For a full purge, including local Merlin data the user confirms removing:

```bash
bash pkg/scripts/uninstall.sh --purge-all
```

For the strongest removal path, Merlin records a local install manifest at
`~/.merlin/install-manifest.json`. A future UI should expose this as a plain
English choice. From Terminal, preview dependency removal first:

```bash
bash pkg/scripts/uninstall.sh --dry-run --purge-dependencies
```

Real dependency removal requires an explicit shared-tool confirmation because
Docker Desktop, Ollama, and Homebrew may be used by other apps.

Uninstall is a product trust feature. The user must always be able to remove
Merlin and its downloaded pieces intentionally.

## v1.0 Focus

Merlin AI v1.0 has only five jobs:

1. Install everything in one shot.
2. Tell the user it worked.
3. Keep everything private by default.
4. Recover gracefully when something breaks.
5. Uninstall cleanly.

Rooms, voice, Home Assistant, Linux, Windows, professional compliance mode,
advanced agents, and native automation runtime work are future roadmap items
unless they directly support those five jobs.

## Useful Commands

```bash
bash scripts/status.sh
bash scripts/doctor.sh
bash scripts/update.sh --dry-run --profile core
bash scripts/upgrade.sh --dry-run --profile core
bash scripts/upgrade.sh --profile core
bash tests/installer-branding-smoke.sh
bash tests/pkg-readiness-smoke.sh
bash tests/uninstall-smoke.sh
```

## Update Safely

Use `scripts/upgrade.sh` for rollback-aware updates. It backs up local config,
the Merlin install manifest, and current image digests before pulling updates.
After restart, it checks the local core services. If the health check fails, it
rolls back to the previous git revision and preserved compose config.

`scripts/update.sh` remains available for compatibility and delegates to the
same rollback-aware upgrade path.

Merlin updates do not pull AI models silently. Local model downloads remain an
explicit user choice.

## Release State

Merlin AI is being prepared for controlled local testing. It is not public beta
or public release until clean install, onboarding, privacy, recovery, and
uninstall evidence is recorded.

- Evidence runbook: [`docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`](docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md)
- Current roadmap: [`docs/MERLIN_IMPLEMENTATION_ROADMAP.md`](docs/MERLIN_IMPLEMENTATION_ROADMAP.md)
- Product north star: [`docs/product/PRODUCT_NORTH_STAR.md`](docs/product/PRODUCT_NORTH_STAR.md)
- Failure learning loop: [`docs/operations/FAILURE_LEARNING_LOOP.md`](docs/operations/FAILURE_LEARNING_LOOP.md)

## Contributing

Before opening a PR, keep the change inside the v1.0 focus or clearly mark it
future. Do not add cloud defaults, telemetry, hidden model downloads, browser
execution controls, or installer behavior changes without focused tests.
