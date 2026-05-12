# 2026-05-11 - Package Launchd GUI Session Fix

## Target

Verify the package postinstall registers Merlin LaunchAgents in the installing
user's GUI bootstrap session so the status and task APIs persist after the
installer exits.

## Failure Found

After a keep-files uninstall followed by package reinstall, the guided package
verification initially passed:

- `Summary: 17 pass, 0 warn, 0 fail`

A later endpoint spot-check found:

| Endpoint | Result |
| --- | --- |
| `http://localhost:8888` | `200` |
| `http://localhost:3000` | `200` |
| `http://localhost:4000/health/readiness` | `200` |
| `http://localhost:6333/healthz` | `200` |
| `http://localhost:11434/api/tags` | `200` |
| `http://localhost:8765/healthz` | `000` |
| `http://localhost:8766/status/routes` | `000` |

`launchctl list` no longer showed:

- `com.merlin.status-api`
- `com.merlin.task-api`

Running `bash launchd/install-launchd.sh` manually from the user's shell made
the agents persist and restored both APIs. That narrowed the issue to package
postinstall registration context, not the LaunchAgent plists or API runtime.

## Root Cause

`pkg/scripts/postinstall` installed LaunchAgents with plain `sudo -u`. During
macOS package installation this can run outside the user's normal GUI bootstrap
session. The script printed successful registration, but the registration did
not reliably persist after the installer flow completed.

## Fix

Updated `pkg/scripts/postinstall` to use a dedicated GUI-session runner:

```bash
launchctl asuser "$INSTALLING_UID" sudo -u "$INSTALLING_USER" ...
```

The package now opens Docker Desktop and installs LaunchAgents through the
installing user's GUI session.

Regression coverage was added to `tests/pkg-readiness-smoke.sh` to require:

- `run_as_user_gui`
- `launchctl asuser`
- the explicit GUI-session launchd setup log line

## Verification

Commands:

```bash
bash tests/pkg-readiness-smoke.sh
bash tests/uninstall-smoke.sh
bash -n pkg/scripts/postinstall tests/pkg-readiness-smoke.sh
git diff --check
bash pkg/build-pkg.sh
bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg
```

Guided package install local evidence log:

- `docs/release/evidence/local/pkg-install-verification-2026-05-12-015601Z.log`

Package verification result:

- `Summary: 17 pass, 0 warn, 0 fail`

Delayed spot-check after the package verification:

| Check | Result |
| --- | --- |
| `com.merlin.status-api` LaunchAgent | registered |
| `com.merlin.task-api` LaunchAgent | registered |
| `http://localhost:8888` | `200` |
| `http://localhost:3000` | `200` |
| `http://localhost:4000/health/readiness` | `200` |
| `http://localhost:6333/healthz` | `200` |
| `http://localhost:11434/api/tags` | `200` |
| `http://localhost:8765/healthz` | `200` |
| `http://localhost:8766/status/routes` | `200` |

## Remaining Release Gap

The package install/upgrade path now has stronger evidence, but this was still
run on the same Mac after prior installs. A clean-machine package install and
full destructive purge validation remain required before public release claims.
