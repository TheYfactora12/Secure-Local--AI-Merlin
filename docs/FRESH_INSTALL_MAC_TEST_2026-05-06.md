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

Status update after fixes:

- #41 fixed in `1d97eac`.
- #42 and #44 fixed in `c496614`.
- #43 and #45 fixed in `1055522`.
- #46 fixed in `71e2bf3`.
- #48 found during rerun from `bb04e1a`; fixed in `73e56f2`.
- #49 found during unsigned package validation; fixed after package postinstall was changed to use a filtered runtime-template copy.
- A full fresh-install rerun from `73e56f2` completed successfully for the `core` profile on the 8GB Mac.

### 1. Uninstaller Fails In Non-Interactive Shell On Sudo Cleanup

Severity: High for package/release cleanup.
GitHub issue: #41.
Status: fixed in `1d97eac`; rerun fresh uninstall before release sign-off.

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
Status: fixed in `c496614`; Open WebUI now runs with offline/HF-offline/local-first defaults. Clean Open WebUI volume was recreated and reached healthy state.

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
Status: fixed in `c496614`; clean Open WebUI volume reached healthy state and HTTP `:3000` responded after local-first defaults were applied.

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
Status: partially fixed in `1055522`; rerun from `bb04e1a` found follow-up #48. The installer starts the read-only status API during the installer session, but the direct background process is not a reliable persistent service in non-interactive execution. Port 8766 task API remains manual by design.

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

Follow-up #48 fix direction:

- In non-interactive mode, do not claim the direct background status API is persistent.
- Print `bash scripts/merlin-status-api.sh start` for manual current-session startup.
- Print `bash launchd/install-launchd.sh` for persistent login startup.
- Keep the execution-aware Task API on port 8766 manual and separate.

Rerun result from `73e56f2`:

- Installer no longer prints unavailable bare `wizard` commands when `/usr/local/bin` is not writable.
- Installer no longer claims the read-only Merlin Status API is persistently running in non-interactive mode.
- Installer prints the manual status API start command and the launchd persistent startup command.
- `wizard doctor` exits with zero failures; status/task API warnings are expected because both are manual in this non-interactive test path.

### 5. `wizard` CLI Is Not On PATH After Non-Interactive Install

Severity: Medium for user onboarding.
GitHub issue: #45.
Status: fixed in `1055522`; installer prints the direct CLI path when the `wizard` symlink is unavailable.

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
Status: fixed in `71e2bf3`; low-tier required/recommended set is now `qwen2.5:7b` plus `nomic-embed-text`.

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

The installer and unsigned package path are close but not yet a stable v1.0 release.

## Unsigned Package Validation

Package tested: `home-ai-elite-0.8.6.pkg`.

Package build/preflight status:

- `bash tests/pkg-readiness-smoke.sh` passed.
- `bash tests/pkg-signing-preflight-smoke.sh` passed.
- `bash tests/release-workflow-smoke.sh` passed.
- `bash pkg/release-preflight.sh` passed for unsigned builds and warned that signing/notarization credentials are not configured on this Mac.
- `bash pkg/build-pkg.sh` produced an unsigned package.
- Payload scan found no `.env`, `.wizard-bootstrapped`, `certs/`, `logs/`, nested `.pkg` artifacts, `pkg/build/`, caches, or `node_modules`.
- `pkgutil --check-signature` correctly reported `Status: no signature`.

Initial unsigned package install found #49:

- A stale `/usr/local/home-ai-elite/.wizard-bootstrapped` marker could be copied into `~/home-ai-elite`.
- That caused first-boot bootstrap to be skipped even after user-level uninstall removed `~/home-ai-elite` and Docker volumes.

Fix applied:

- Package payload excludes runtime markers and logs.
- Package postinstall copies from `/usr/local/home-ai-elite` to `~/home-ai-elite` with filtered `rsync`, not raw `cp -R`.
- Static package readiness checks now require the filtered copy and runtime-marker exclusions.

Rerun result after #49 fix:

- Unsigned `.pkg` install succeeded.
- Package receipt registered as `com.homeai.elite` version `0.8.6`.
- First-boot bootstrap ran correctly.
- Qdrant collections initialized from the memory manifest.
- `wizard doctor` exited with zero failures.
- Expected warnings remain: missing local gitleaks hook, low-tier caution, Task API manual on port 8766.

Release blockers from this test, after fixes:

1. Core fresh uninstall/install on this 8GB Mac is green after #41 through #48.
2. Unsigned `.pkg` install path is green after #49.
3. Signed/notarized package release gate remains separate.
4. Live Qdrant backup/restore verification is green on the package-installed stack.
5. Upgrade release verification remains required before v1.0.
6. Optional launchd persistence should be tested separately from non-interactive core install.

## Backup / Restore Validation

Command:

```bash
bash tests/qdrant-restore-live-smoke.sh
```

Result:

- Qdrant was reachable.
- Disposable collection `merlin_restore_smoke_1778111918_16032` was created.
- A seed point with vector and payload was inserted.
- Backup archive was created.
- The disposable collection was deleted and recreated empty before restore.
- Restore completed.
- Restored payload and vector were verified.
- Summary: 8 passed, 0 failures.

Warnings observed:

- n8n workflow export was skipped because n8n may be disabled or require an API key.
- `.env.bak` was included for manual recovery only; restore did not overwrite `.env`.

## Recommended Next Fix Order

1. Run upgrade verification.
2. Test optional launchd persistence for the read-only status API.
3. Move to signed/notarized package release gate once upgrade and launchd checks are green.
