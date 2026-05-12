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

## Follow-Up Failure

A later spot-check after commit `8c8485f` found the APIs had stopped again:

| Endpoint | Result |
| --- | --- |
| `http://localhost:8888` | `200` |
| `http://localhost:3000` | `200` |
| `http://localhost:4000/health/readiness` | `200` |
| `http://localhost:6333/healthz` | `200` |
| `http://localhost:11434/api/tags` | `200` |
| `http://localhost:8765/healthz` | `000` |
| `http://localhost:8766/status/routes` | `000` |

`launchctl list` no longer showed `com.merlin.status-api` or
`com.merlin.task-api`. The GUI-session fix improved initial package
registration, but was not sufficient to prove long-lived API persistence.

## Rejected Second Fix

An attempted fix changed API LaunchAgents to invoke the existing idempotent
lifecycle managers:

- `scripts/merlin-status-api.sh start`
- `scripts/merlin-task-api.sh start`

Manual validation rejected that approach. The launchd jobs exited after invoking
the managers, and macOS later cleaned up the child API processes. That produced
the same user-visible failure: ports `8765` and `8766` went down after initially
responding.

## Second Fix

The API LaunchAgents were restored to foreground mode:

- `scripts/merlin-status-api.sh run`
- `scripts/merlin-task-api.sh run`

The package postinstall path was changed again so it does not depend on a nested
`sudo -u` bootstrap. It now passes explicit target-user launchd variables to
`launchd/install-launchd.sh`:

- `MERLIN_LAUNCHD_HOME`
- `MERLIN_LAUNCHD_USER`
- `MERLIN_LAUNCHD_UID`

`launchd/install-launchd.sh` now uses those values to write the LaunchAgent
files into the installing user's `~/Library/LaunchAgents`, target the installing
user's `gui/<uid>` domain, and correct LaunchAgent file ownership.

A package retest then exposed another important detail: invoking
`launchd/install-launchd.sh` as root with target-user variables still produced
`Bootstrap failed: 5` and `Expecting a LaunchDaemons path` warnings. That means
the package script must both enter the user's GUI session and pass the explicit
target-user values. The final postinstall runner now uses:

```bash
launchctl asuser "$INSTALLING_UID" sudo -u "$INSTALLING_USER" \
  HOME="$INSTALLING_HOME" \
  MERLIN_LAUNCHD_HOME="$INSTALLING_HOME" \
  MERLIN_LAUNCHD_USER="$INSTALLING_USER" \
  MERLIN_LAUNCHD_UID="$INSTALLING_UID" \
  bash launchd/install-launchd.sh
```

Static regression coverage was added to:

- `tests/pkg-readiness-smoke.sh`
- `tests/launchd-core-smoke.sh`

The tests now enforce the explicit target-user launchd path and foreground API
LaunchAgent model.

## Final Package Retest

Before the retest, existing Merlin LaunchAgents were removed with:

```bash
bash ~/merlin-ai/launchd/install-launchd.sh --uninstall
```

Then the package was rebuilt and installed through the guided verifier:

```bash
bash pkg/build-pkg.sh
bash scripts/run-pkg-install-verification.sh merlin-ai-0.8.6.pkg
```

Local ignored log:

- `docs/release/evidence/local/pkg-install-verification-2026-05-12-021526Z.log`

Package verification result:

- `Summary: 17 pass, 0 warn, 0 fail`

Delayed spot-check after package verification:

| Check | Result |
| --- | --- |
| `com.merlin.status-api` LaunchAgent | running |
| `com.merlin.task-api` LaunchAgent | running |
| Status API last exit code | never exited |
| Task API last exit code | never exited |
| `http://localhost:8888` | `200` |
| `http://localhost:3000` | `200` |
| `http://localhost:4000/health/readiness` | `200` |
| `http://localhost:6333/healthz` | `200` |
| `http://localhost:11434/api/tags` | `200` |
| `http://localhost:8765/healthz` | `200` |
| `http://localhost:8766/status/routes` | `200` |

The final install log section showed the target-user GUI-domain path registered
the API agents without the earlier `Bootstrap failed: 5` warnings:

- `Installing launchd auto-start agents into user GUI domain`
- `Registered: com.merlin.status-api`
- `Registered: com.merlin.task-api`

## Remaining Release Gap

The package install/upgrade path now has stronger evidence, but this was still
run on the same Mac after prior installs. A clean-machine package install and
full destructive purge validation remain required before public release claims.
