# Do Not Break

Last updated: 2026-05-06

This file is the protection list for Home AI Elite.

## Protected Assets

- `install.sh`
- `docker-compose.yml`
- `.env.example`
- `scripts/profile-lib.sh`
- `scripts/doctor.sh`
- `cli/wizard`
- `configs/merlin/`
- `scripts/merlin-status-api.py`
- `.github/workflows/ci.yml`
- `.gitleaks.toml`
- `tests/config-root-smoke.sh`

## Contracts

1. The installer remains the supported install path.
2. `core` remains the laptop-safe default profile.
3. macOS uses native Ollama for Apple Silicon acceleration.
4. Docker services bind to localhost by default.
5. Root `config/` must not exist; `configs/` is canonical.
6. Port 8765 remains read-only status only.
7. Port 8766 owns Merlin task/status panels.
8. Cloud calls remain off by default.
9. Model downloads remain opt-in.
10. Risky actions require approval gates.
11. Memory writes require approval.
12. Secrets are never committed, logged, or shown in dashboard/report output.
13. Qdrant `documents` dimension mismatch is intentional and guarded.
14. n8n and OpenHands remain optional profiles.
15. CI must remain green before merge.

## No-Go Changes Without Explicit Approval

- Rewriting the installer.
- Changing default install profile from `core`.
- Enabling cloud fallback by default.
- Starting OpenHands or n8n automatically on low-memory machines.
- Rebinding local services to public interfaces.
- Removing approval gates.
- Auto-writing memory from normal chat.
- Merging 8765 read-only status with 8766 task execution.
- Replacing Ollama, LiteLLM, Open WebUI, Qdrant, Docker Compose, n8n, or OpenHands.
- Adding heavy agent frameworks as required dependencies.
