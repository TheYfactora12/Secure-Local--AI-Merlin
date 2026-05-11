# 2026-05-11 Install/Uninstall Rehearsal

## Date/time

2026-05-11 13:10 EDT

## Branch

`main`

## Starting commit SHA

`6814b979942f45e83e32675b78a491a0204ab19b`

## Ending commit SHA

Pending commit.

## Target issue(s)

#37, #95, #134

## Scope

Run a local uninstall/install rehearsal with production-smoothness review:

- dry-run uninstall first,
- real purge uninstall,
- rebuild local `.pkg`,
- attempt package install path,
- run repo installer path when package install is blocked by admin prompt,
- validate live services, APIs, and browser dashboard,
- fix safe rough edges found during the test.

Developer ID signing/notarization remains intentionally deferred.

## Files changed

- `pkg/scripts/postinstall`
- `pkg/resources/readme.html`
- `pkg/README.md`
- `scripts/install-pkg-local.sh`
- `tests/installer-branding-smoke.sh`
- `tests/pkg-readiness-smoke.sh`
- `docs/release/evidence/2026-05-11-install-uninstall-rehearsal.md`
- `docs/release/evidence/assets/2026-05-11-install-rehearsal-browser-qa/`

## Protected files touched

- `pkg/scripts/postinstall`

Reason: the package postinstall surface still used a retired `homeai` install
log path. The change only renames the install log to Merlin AI branding.

## Commands run

- `pkgutil --pkgs | rg 'com\.(merlin\.ai|homeai\.elite)' || true`
- `bash pkg/scripts/uninstall.sh --dry-run --yes --purge-all`
- `docker ps --format '{{.Names}}\t{{.Status}}'`
- `bash pkg/scripts/uninstall.sh --yes --purge-all`
- `docker ps -a --format '{{.Names}}\t{{.Status}}'`
- `docker volume ls --format '{{.Name}}'`
- `sudo -n true`
- `bash pkg/build-pkg.sh`
- `sudo -n installer -pkg merlin-ai-0.8.6.pkg -target /`
- `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`
- `bash scripts/status.sh`
- `bash scripts/doctor.sh`
- `curl -fsS --max-time 5` checks against:
  - `http://localhost:8888`
  - `http://localhost:3000`
  - `http://localhost:4000/health/readiness`
  - `http://localhost:6333/healthz`
  - `http://localhost:11434/api/tags`
  - `http://localhost:8765/healthz`
  - `http://localhost:8766/status/routes`
- `bash launchd/install-launchd.sh`
- `.venv-test/bin/python scripts/dashboard-browser-qa.py --url http://localhost:8888/index.html --no-serve-static --output-dir docs/release/evidence/assets/2026-05-11-install-rehearsal-browser-qa`
- `bash scripts/install-pkg-local.sh --help`
- `bash scripts/install-pkg-local.sh`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`

## Test output summary

- Uninstall dry-run showed Docker volume/image purge, launchd cleanup,
  Merlin model purge, current receipt cleanup, and legacy receipt cleanup.
- Real purge removed core containers, Docker volumes, network, and stack images.
- Real purge did not forget package receipts because non-interactive sudo was
  unavailable in this session.
- Local `.pkg` rebuilt successfully as `merlin-ai-0.8.6.pkg`, 7.3 MB.
- Automated package install command was blocked by macOS admin elevation:
  `sudo: a password is required`.
- Repo installer path completed successfully after purge.
- Initial doctor after repo install: 46 checks passed, 7 warnings, 0 failures.
- After launchd warmup: 50 checks passed, 3 warnings, 0 failures.
- Live URL checks passed for Dashboard, Open WebUI, LiteLLM, Qdrant, Ollama,
  Merlin Status API, and Merlin Task API.
- Browser QA passed and generated desktop/mobile screenshots.
- `bash tests/installer-branding-smoke.sh`: PASS.
- `bash tests/pkg-readiness-smoke.sh`: PASS.

## Tests skipped and why

- Full double-click `.pkg` install was not completed because this Codex session
  cannot enter the required macOS admin password.
- Developer ID signing/notarization was skipped because it remains deferred.
- Real receipt forgetting was not completed because non-interactive sudo was
  unavailable.

## Failures found

1. Automated `.pkg` install via `sudo -n installer` cannot proceed without an
   admin password.
2. Real uninstall could not forget the current/legacy package receipts without
   admin privileges.
3. Package postinstall and package readme still referenced
   `/tmp/homeai-install.log`.
4. LaunchAgent IDs and launchd log paths still use `com.homeai.*` and
   `/tmp/homeai-*.log`.
5. Core install intentionally skips model pulls, so chat is installed but no
   local chat model is loaded until the user pulls one.

## Failure categories

- Installer elevation UX
- Uninstall admin cleanup
- Branding cleanup
- Launchd migration
- First-run model readiness

## Root cause or current hypothesis

1. macOS package install and receipt cleanup require administrator elevation.
   The raw automated command fails in non-interactive sessions.
2. The brand reset updated product copy but did not rename all runtime log
   paths.
3. LaunchAgent labels predate the Merlin AI rename. Renaming them safely needs
   a migration that unloads/removes legacy agents before registering new labels.
4. The v1.0 package path skips model downloads by design for install speed and
   disk control, but the user experience still needs a clear first-model prompt.

## Fix applied

- Changed package postinstall install log path to
  `/tmp/merlin-ai-install.log`.
- Updated package first-run readme to point to `/tmp/merlin-ai-install.log`.
- Added `scripts/install-pkg-local.sh`, a local package install helper that:
  - explains why the Mac administrator password is needed,
  - states Merlin does not store the password,
  - uses a Merlin-branded `sudo` prompt in interactive Terminal,
  - gives a clean explanation when run from a non-interactive session.
- Added regression checks to installer/package readiness smokes.

## Retest result

- Rebuilt package after the log-path fix: PASS.
- Installer branding smoke: PASS.
- Package readiness smoke: PASS.
- Local package helper help output: PASS.
- Local package helper non-interactive failure message: PASS and human-readable.
- Live installed stack remains running after fixes.

## Regression tests added

- `tests/installer-branding-smoke.sh` now checks:
  - Merlin-branded install log path,
  - package readme log path,
  - executable local package install helper,
  - clear password prompt copy.
- `tests/pkg-readiness-smoke.sh` now checks:
  - helper shell syntax,
  - Merlin-branded install log path,
  - clear `sudo -p` prompt,
  - clear non-interactive failure message.

## Follow-up issues created or recommended

Recommended:

1. Add a focused launchd migration issue:
   rename `com.homeai.*` agents/logs to `com.merlin.*`, unload legacy agents,
   and update uninstall/tests in the same PR.
2. Add first-model onboarding:
   after install, show "Add your first local model" with low-tier default.
3. Run true `.pkg` double-click install with a human entering admin password.
4. Add a clean receipt-forget verification step after an admin-authorized
   uninstall.

## Lesson learned

The core stack can come up cleanly after purge, but production smoothness is
not just service health. The installer has to explain every privileged step in
plain English, and old internal names in logs/agents reduce trust even when the
services work.

## What not to repeat next time

Do not treat command-line `sudo` failure as acceptable UX. Provide either the
macOS Installer prompt or a Merlin-branded terminal helper with clear fallback
instructions.

## Evidence assets

`docs/release/evidence/assets/2026-05-11-install-rehearsal-browser-qa/`

## Local Trusted Beta impact

Improved. Core uninstall/install behavior was exercised, the stack came up, all
local service URLs responded, APIs warmed successfully, browser QA passed, and
two installer-smoothness fixes were added.

## Public Beta impact

Still blocked. Public beta needs a human-run `.pkg` install/uninstall with
admin password prompts captured, launchd branding migration, first-model
onboarding, and clean receipt cleanup evidence.
