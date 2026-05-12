# 2026-05-11 - Package Rebuild and Admin Prompt Boundary

## Target

Continue #37/#95 package hardening after the launchd Merlin label migration.
Validate the rebuilt `.pkg` contains the current Merlin launchd labels and that
the local installer helper fails cleanly when no interactive admin password can
be entered.

## Starting Point

- Starting commit: `255afe300a7e97ed67a31f8622ccd94291610e88`
- Branch: `main`
- Working tree: clean before this evidence note.
- Live local services returned `200` for:
  - Dashboard `http://localhost:8888`
  - Open WebUI `http://localhost:3000`
  - LiteLLM readiness `http://localhost:4000/health/readiness`
  - Qdrant `http://localhost:6333/healthz`
  - Ollama `http://localhost:11434/api/tags`
  - Merlin status API `http://localhost:8765/healthz`
  - Merlin task API `http://localhost:8766/status/routes`

## Commands Run

```bash
git status --short --branch
git rev-parse HEAD
sed -n '1,240p' pkg/build-pkg.sh
sed -n '1,220p' pkg/scripts/preinstall
sed -n '1,260p' pkg/scripts/postinstall
bash pkg/build-pkg.sh
pkgutil --check-signature merlin-ai-0.8.6.pkg
pkgutil --payload-files merlin-ai-0.8.6.pkg | rg 'launchd/com\.(merlin|homeai)|\.venv-test|\.pytest_cache|\.DS_Store|docs/release/evidence/assets|\.pkg$'
pkgutil --expand merlin-ai-0.8.6.pkg /tmp/merlin-pkg-expand-70766
sed -n '1,120p' /tmp/merlin-pkg-expand-70766/Distribution
sed -n '1,120p' /tmp/merlin-pkg-expand-70766/merlin-ai-0.8.6-component.pkg/PackageInfo
bash tests/pkg-readiness-smoke.sh
bash tests/installer-branding-smoke.sh
bash scripts/install-pkg-local.sh merlin-ai-0.8.6.pkg
bash scripts/verify-pkg-install.sh
```

## Results

- `bash pkg/build-pkg.sh`: PASS
  - Built `merlin-ai-0.8.6.pkg`
  - Final package size: 7.3 MB
  - Staged payload size: 9.8 MB
- `pkgutil --check-signature merlin-ai-0.8.6.pkg`: expected unsigned state:
  - `Status: no signature`
- Payload launchd files:
  - `./usr/local/merlin-ai/launchd/com.merlin.task-api.plist`
  - `./usr/local/merlin-ai/launchd/com.merlin.stack.plist`
  - `./usr/local/merlin-ai/launchd/com.merlin.status-api.plist`
  - `./usr/local/merlin-ai/launchd/com.merlin.backup.plist`
  - `./usr/local/merlin-ai/launchd/com.merlin.docker.plist`
- Package metadata:
  - Distribution `pkg-ref id="com.merlin.ai"`
  - Component `identifier="com.merlin.ai"`
  - Version `0.8.6`
  - Payload `numberOfFiles="401"`
- `bash tests/pkg-readiness-smoke.sh`: PASS
- `bash tests/installer-branding-smoke.sh`: PASS
- `bash scripts/install-pkg-local.sh merlin-ai-0.8.6.pkg`: expected FAIL in
  this non-interactive shell with safe copy:
  - "Merlin AI needs your Mac administrator password to install system files."
  - "Merlin does not store it."
  - "Cannot ask for a password because this is not an interactive Terminal."
  - Suggested Terminal helper command or double-click package path.
- Added `scripts/verify-pkg-install.sh` as a non-destructive post-package
  verification command. It checks:
  - macOS package receipt `com.merlin.ai`
  - system payload `/usr/local/merlin-ai`
  - user runtime `~/merlin-ai`
  - `/tmp/merlin-ai-install.log`
  - `~/.merlin/install-manifest.json`
  - `com.merlin.*` launchd agents
  - Dashboard, Open WebUI, LiteLLM, Qdrant, Ollama, Merlin status API, and
    Merlin task API health endpoints.
- Running `bash scripts/verify-pkg-install.sh` before a true package install
  correctly reports missing package receipt, missing `/usr/local/merlin-ai`,
  missing `~/merlin-ai`, and missing `/tmp/merlin-ai-install.log`, while showing
  currently running source-installed services as reachable. This is expected and
  documents the exact post-install verification gap.

## Failures Found

- The true `.pkg` install still cannot be completed from this Codex shell
  because macOS admin password entry requires an interactive Terminal or Finder
  installer session.
- The new verification script reports package-level failures until the package
  has actually been installed through the admin-password path.

## Failure Category

- Test environment limitation / privileged GUI install path not yet validated.

## Root Cause / Hypothesis

The package helper is correctly refusing to ask for a password when stdin is not
interactive. This is safer than attempting non-interactive `sudo` or hiding a
failed install behind raw macOS Installer output.

## Remaining Risk

- A human still needs to run either:

```bash
bash scripts/install-pkg-local.sh merlin-ai-0.8.6.pkg
```

or double-click `merlin-ai-0.8.6.pkg` in Finder, enter the admin password, then
verify `/tmp/merlin-ai-install.log`, `~/merlin-ai`, launchd registration, and
core service health.

## Rollback

This evidence pass did not change installer behavior. Remove the generated
ignored package artifact if needed:

```bash
rm -f merlin-ai-0.8.6.pkg
rm -rf pkg/build
```
