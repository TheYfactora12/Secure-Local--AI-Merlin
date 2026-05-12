# 2026-05-11 - Package Uninstall Verification

## Target

Verify package-installed Merlin AI can be uninstalled through the guarded
uninstaller path after a successful admin-password `.pkg` install.

## Starting Point

- Starting commit: `af1cd93aba7206b86e549aeb19e504c702e1a203`
- Package receipt existed:
  - `package-id: com.merlin.ai`
  - `version: 0.8.6`
- Paths existed:
  - `/usr/local/merlin-ai`
  - `~/merlin-ai`
  - `~/.merlin`
- Launchd agents were registered:
  - `com.merlin.docker`
  - `com.merlin.stack`
  - `com.merlin.status-api`
  - `com.merlin.task-api`
- Pre-uninstall services returned `200`:
  - Dashboard `http://localhost:8888`
  - Open WebUI `http://localhost:3000`
  - LiteLLM `http://localhost:4000/health/readiness`
  - Qdrant `http://localhost:6333/healthz`
  - Ollama `http://localhost:11434/api/tags`
  - Merlin status API `http://localhost:8765/healthz`
  - Merlin task API `http://localhost:8766/status/routes`

## Dry Run

Command:

```bash
bash pkg/scripts/uninstall.sh --dry-run --yes --keep-files
```

Result:

- Would stop services without removing Docker volumes.
- Would remove current `com.merlin.*` launchd agents.
- Would remove legacy `com.homeai.*` launchd agents.
- Would back up `~/merlin-ai/.env`.
- Would keep install directories because `--keep-files` was set.
- Would forget package receipts:
  - `com.merlin.ai`
  - `com.homeai.elite`
- Would not remove Ollama models, Docker stack images, Docker Desktop,
  Homebrew, or the Ollama app/binary.

## Real Uninstall

Command:

```bash
bash pkg/scripts/uninstall.sh --yes --keep-files
```

Result:

- Docker services stopped and containers were removed.
- Docker network `merlin-ai_ai-net` was removed.
- Current `com.merlin.*` launchd agents were removed.
- No current or legacy Merlin/Home AI launchd agents remained registered.
- No current or legacy Merlin/Home AI launchd plist files remained in
  `~/Library/LaunchAgents`.
- `~/merlin-ai/.env` was backed up to:
  - `~/merlin-ai-env-backup-20260511_214417.env`
- Install directories remained because `--keep-files` was set:
  - `/usr/local/merlin-ai`
  - `~/merlin-ai`
  - `~/.merlin`
- Merlin Docker service containers were no longer running:
  - `open-webui`
  - `swarm-dashboard`
  - `qdrant`
  - `litellm`
- Package receipt cleanup was attempted, but skipped because the shell did not
  have admin privileges:
  - `com.merlin.ai`
  - `com.homeai.elite`
- The uninstaller printed the required manual recovery command:

```bash
sudo pkgutil --forget com.merlin.ai
sudo pkgutil --forget com.homeai.elite
```

Post-uninstall endpoint checks:

| Endpoint | Result | Expected |
| --- | --- | --- |
| `http://localhost:8888` | `000` | yes |
| `http://localhost:3000` | `000` | yes |
| `http://localhost:4000/health/readiness` | `000` | yes |
| `http://localhost:6333/healthz` | `000` | yes |
| `http://localhost:11434/api/tags` | `200` | yes, Ollama is preserved |
| `http://localhost:8765/healthz` | `000` | yes |
| `http://localhost:8766/status/routes` | `000` | yes |

## Findings

- Keep-files uninstall path works for stopping/removing Merlin-managed launchd
  agents and Docker service containers.
- The current uninstaller behaves correctly in a non-admin shell by warning
  instead of failing when package receipt cleanup requires `sudo`.
- A consumer-grade uninstall path still needs an admin-friendly Terminal or GUI
  wrapper for package receipt cleanup so the user is prompted cleanly for their
  password instead of seeing manual `sudo pkgutil --forget` follow-up commands.

## Current Scope Boundary

This run intentionally did not remove:

- preserved install/runtime directories because `--keep-files` was set
- Ollama models
- Docker stack images
- Docker Desktop
- Homebrew
- the Ollama app/binary

Full purge remains a separate destructive validation pass and should only run
after explicit approval.

## Reinstall After Keep-Files Uninstall

Command launched in Terminal so macOS could prompt for the administrator
password:

```bash
bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg
```

Local ignored log:

- `docs/release/evidence/local/pkg-install-verification-2026-05-12-014710Z.log`

Result:

- `.pkg` upgrade/install succeeded after admin authentication.
- Package receipt was present.
- System package payload existed at `/usr/local/merlin-ai`.
- User runtime folder existed at `~/merlin-ai`.
- Dependency install manifest existed at `~/.merlin/install-manifest.json`.
- Launchd agents registered:
  - `com.merlin.docker`
  - `com.merlin.stack`
  - `com.merlin.status-api`
  - `com.merlin.task-api`
- Verification required four attempts while services warmed.
- Final verification result:
  - `Summary: 17 pass, 0 warn, 0 fail`

Final verified endpoints:

| Endpoint | Result |
| --- | --- |
| `http://localhost:8888` | pass |
| `http://localhost:3000` | pass |
| `http://localhost:4000/health/readiness` | pass |
| `http://localhost:6333/healthz` | pass |
| `http://localhost:11434/api/tags` | pass |
| `http://localhost:8765/healthz` | pass |
| `http://localhost:8766/status/routes` | pass |

The keep-files uninstall followed by package reinstall/verification loop is now
covered by local evidence. This is not a full purge reinstall; preserved runtime
files remained in place by design.
