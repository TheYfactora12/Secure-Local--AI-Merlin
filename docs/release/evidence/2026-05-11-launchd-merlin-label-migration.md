# 2026-05-11 - Launchd Merlin Label Migration

## Target

Migrate active macOS launchd agents from retired `com.homeai.*` labels and
`/tmp/homeai-*` logs to current Merlin labels and logs without breaking legacy
uninstall cleanup.

## Starting Point

- Starting commit: `564651d04fcdc2afab953b7ab422051ab60f6326`
- Ending commit: this evidence note is included in the migration commit.
- Branch: `main`
- Local core services were reachable on ports `8888`, `3000`, `4000`, `6333`,
  and `11434`.
- Merlin API agents were not reachable before migration:
  - `http://localhost:8765/healthz` returned connection failure.
  - `http://localhost:8766/status/routes` returned connection failure.

## Changes

- Renamed active launchd plists:
  - `com.merlin.docker.plist`
  - `com.merlin.stack.plist`
  - `com.merlin.status-api.plist`
  - `com.merlin.task-api.plist`
  - `com.merlin.backup.plist`
- Updated active labels to `com.merlin.*`.
- Updated active logs to `/tmp/merlin-*.log`.
- Updated `launchd/install-launchd.sh` to remove legacy `com.homeai.*`
  registrations and plists before registering current Merlin agents.
- Updated package uninstaller to remove both current `com.merlin.*` and legacy
  `com.homeai.*` launchd agents.
- Updated launchd docs, canonical context, and launchd smoke tests.

## Commands Run

```bash
git status --short --branch
git rev-parse HEAD
rg -n "com\.homeai|homeai-|Home AI Elite|home-ai-elite" launchd pkg scripts tests README.md docs install.sh uninstall.sh dashboard
for url in http://localhost:8888 http://localhost:3000 http://localhost:4000/health/readiness http://localhost:6333/healthz http://localhost:11434/api/tags http://localhost:8765/healthz http://localhost:8766/status/routes; do ...; done
bash tests/launchd-core-smoke.sh
bash tests/merlin-task-api-smoke.sh
bash tests/wizard-start-status-api-smoke.sh
bash tests/uninstall-smoke.sh
bash launchd/install-launchd.sh
sleep 45
launchctl list | grep merlin
curl http://localhost:8765/healthz
curl http://localhost:8766/status/routes
bash tests/pkg-readiness-smoke.sh
bash -n launchd/install-launchd.sh pkg/scripts/uninstall.sh tests/launchd-core-smoke.sh tests/merlin-task-api-smoke.sh tests/uninstall-smoke.sh tests/wizard-start-status-api-smoke.sh
plutil -lint launchd/com.merlin.docker.plist launchd/com.merlin.stack.plist launchd/com.merlin.status-api.plist launchd/com.merlin.task-api.plist launchd/com.merlin.backup.plist
git diff --check
```

## Results

- `bash tests/launchd-core-smoke.sh`: PASS
- `bash tests/merlin-task-api-smoke.sh`: PASS
- `bash tests/wizard-start-status-api-smoke.sh`: PASS
- `bash tests/uninstall-smoke.sh`: PASS
- `bash tests/pkg-readiness-smoke.sh`: PASS
- `bash -n ...`: PASS
- `plutil -lint ...`: PASS for all current Merlin plists
- `git diff --check`: PASS
- Live launchd install registered:
  - `com.merlin.docker`
  - `com.merlin.stack`
  - `com.merlin.status-api`
  - `com.merlin.task-api`
- Live API check after warmup:
  - `200 http://localhost:8765/healthz`
  - `200 http://localhost:8766/status/routes`

## Failures Found

- Before the fix, the stack had healthy Docker/browser services but no reachable
  Merlin status/task APIs on `8765` and `8766`.
- Active launchd source still used retired Home AI labels and logs.

## Root Cause / Hypothesis

The retired launchd labels created product drift and made it harder to reason
about the running local agents. Migrating active labels to `com.merlin.*` while
cleaning legacy labels first makes the current state visible and reduces stale
agent collision risk.

## Remaining Risk

- Legacy `com.homeai.*` strings intentionally remain in uninstall and launchd
  migration code so older installs can be cleaned.
- Historical docs and evidence may still mention Home AI / `com.homeai.*` as
  past state; they were not rewritten as current truth.

## Rollback

Revert this commit to restore the previous `com.homeai.*` launchd source files.
Then run:

```bash
bash launchd/install-launchd.sh --uninstall
bash launchd/install-launchd.sh
```
