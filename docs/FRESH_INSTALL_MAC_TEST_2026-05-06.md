# Fresh Install Mac Test — 2026-05-06

## Test Summary

- Machine: macOS 26.4.1, Apple Silicon, 8GB RAM.
- Test profile: `core`.
- Installer command: `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`
- Source snapshot used to preserve repo during uninstall: `/private/tmp/home-ai-elite-source-20260506_163305`
- Sanitized bug report: `logs/merlin-bug-report-2026-05-06T203804Z.md`

## Reset Performed

The project uninstaller was run with:

```bash
bash pkg/scripts/uninstall.sh --yes --remove-data
```

Confirmed reset behavior:

- Docker containers were stopped and removed.
- Docker volumes `home-ai-elite_qdrant-storage` and `home-ai-elite_open-webui` were removed.
- Docker network `home-ai-elite_ai-net` was removed.
- Launchd cleanup ran for Home AI Elite agents.
- Existing `.env` was backed up.
- `/Users/kevinmedeiros/home-ai-elite` was removed, then restored from the clean source snapshot without `.env`, logs, `.venv`, `.wizard-bootstrapped`, or caches.

## Installer Result

The fresh core install completed with exit code 0.

Working after install:

- Docker containers for dashboard, LiteLLM, Qdrant, and Open WebUI were created.
- Native Ollama was detected and used on macOS.
- `.env` was created from `.env.example`.
- Internal secrets were generated.
- `.env` permissions were set to `600`.
- Qdrant initialized all legacy/current collections from the memory manifest.
- Model pulls were skipped as requested.
- Low hardware tier was detected correctly for 8GB RAM.
- `bash cli/wizard doctor` exited with 0 failures.

## Fresh Install Findings

### 1. Uninstaller Fails In Non-Interactive Shell On Sudo Cleanup

Severity: High for package/release cleanup.
GitHub issue: #41.

Evidence:

- Uninstaller completed Docker/data cleanup and removed the user install directory.
- It then failed when removing `/usr/local/home-ai-elite` because sudo required a terminal/password:

```text
sudo: a terminal is required to read the password
sudo: a password is required
```

Impact:

- `/usr/local/home-ai-elite` remains after a non-interactive uninstall.
- `pkgutil` receipt cleanup also remains blocked.
- A release/package uninstall can appear partially successful while leaving system-level artifacts behind.

Recommended fix:

- Make non-interactive uninstall skip sudo-only system cleanup with a warning unless an explicit privileged mode is used.
- Add a clear manual command for admin cleanup.
- Add a smoke test that asserts `--yes` mode never hard-fails after user-level cleanup.

### 2. Open WebUI Does External Hugging Face Fetch On First Boot

Severity: High for local-only-by-default claim.
GitHub issue: #42.

Evidence:

Open WebUI logs during first boot:

```text
Fetching 30 files: 0%|          | 0/30
Warning: You are sending unauthenticated requests to the HF Hub.
```

Impact:

- Even with cloud API keys empty and model pulls skipped, first boot still performs external network activity from Open WebUI.
- On slow/offline/restricted networks, Open WebUI stays unhealthy and returns an empty HTTP reply.
- This conflicts with the product promise of no external data transmission by default unless documented and controlled.

Recommended fix:

- Decide whether Open WebUI first-boot asset/model fetch is allowed dependency bootstrap or must be disabled.
- Prefer disabling or prebundling the startup dependency for `core` profile.
- Add a release gate proving `core` can start without external network after Docker images are present.

### 3. Open WebUI Health Timeout During Fresh Install

Severity: Medium.
GitHub issue: #44.

Evidence:

- Installer reported:

```text
Open WebUI not responding — check: docker compose logs
```

- Docker reported `open-webui` as `unhealthy`.
- Direct HTTP check returned:

```text
curl: (52) Empty reply from server
```

Impact:

- Installer exits successfully while a primary user-facing service is unhealthy.
- First-time user sees "Wizard AI is ready" even though chat UI may not be ready.

Recommended fix:

- Treat Open WebUI as "warming" separately from "ready".
- If Open WebUI is still fetching startup files, report an explicit warm-up/network message.
- Consider extending the wait or adding a post-install doctor warning that is clearer than "ready".

### 4. Merlin Status API And Task API Do Not Start In Fresh Non-Interactive Install

Severity: Medium for Merlin v1.
GitHub issue: #43.

Evidence:

Doctor warnings:

```text
Merlin Status API not reachable (http://localhost:8765/healthz)
Merlin Task API not reachable (http://localhost:8766/status/routes)
Port 8765 is closed
Port 8766 is closed
```

Direct checks confirmed both ports closed.

Impact:

- Phase 2 Merlin status/task panels exist but are not started by the core installer in non-interactive mode.
- `wizard merlin ask` and new provider/status panels cannot work until services are manually started.

Recommended fix:

- Add a guarded, explicit start path for Merlin APIs that does not require launchd.
- Update installer final output to say whether Merlin APIs are installed, started, skipped, or require manual start.
- Add a `wizard merlin start` or documented command before making this a v1 stable gate.

### 5. `wizard` CLI Is Not On PATH After Non-Interactive Install

Severity: Medium for user onboarding.
GitHub issue: #45.

Evidence:

Installer warning:

```text
/usr/local/bin is not writable; skipping system-wide wizard symlink in non-interactive mode
Use directly for now: /Users/kevinmedeiros/home-ai-elite/cli/wizard
```

Follow-up check found no `wizard` command on PATH and no `/usr/local/bin/wizard`.

Impact:

- Installer final instructions still say to run `wizard status`, but that command is unavailable.
- Non-technical users will hit "command not found" immediately after install.

Recommended fix:

- If symlink creation is skipped, final instructions should use the actual available command: `bash cli/wizard ...` or `/Users/.../cli/wizard`.
- Add an option to install a user-local symlink under a writable directory such as `~/.local/bin`.

### 6. Doctor Low-Tier Model Warning May Conflict With Skip-Model-Pulls

Severity: Low.
GitHub issue: #46.

Evidence:

Doctor warning:

```text
Missing low tier recommended model(s): mistral:7b
```

Impact:

- Fresh install intentionally skipped model pulls, but doctor warns about a missing recommended model.
- This is acceptable as a warning, but may confuse users on 8GB machines where extra model pulls should be conservative.

Recommended fix:

- Clarify whether `mistral:7b` is required, recommended, or optional for low tier.
- For 8GB low tier, prefer one required model plus optional suggestions.

## Current Release Assessment

The installer is close but not yet a stable v1.0 release.

Release blockers from this test:

1. Non-interactive uninstall leaves sudo-only cleanup failure.
2. Open WebUI first boot performs external Hugging Face fetch despite local-only defaults.
3. Installer can report success while Open WebUI is unhealthy.
4. Merlin APIs are not started or clearly surfaced after fresh install.
5. `wizard` command instructions are inaccurate when symlink creation is skipped.

## Recommended Next Fix Order

1. Fix non-interactive uninstall sudo behavior.
2. Decide and enforce Open WebUI local-only startup behavior.
3. Improve installer readiness messaging for Open WebUI warm-up/unhealthy state.
4. Add explicit Merlin API start command and installer messaging.
5. Fix CLI post-install instructions when `wizard` symlink is skipped.
