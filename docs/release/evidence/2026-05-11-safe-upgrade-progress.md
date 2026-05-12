# 2026-05-11 Safe Upgrade Progress

## Date/time

2026-05-11 20:43 EDT

## Branch

`main`

## Starting commit SHA

`b40b5627742d44a28ae11fb7baf6d76d18d113ef`

## Ending commit SHA

Pending commit.

## Target issue(s)

#37, #95, #134

## Scope

Tighten the v1.0 update/upgrade trust path:

- keep `upgrade.sh` as the rollback-aware update path,
- back up the new Merlin install manifest before update,
- expand post-upgrade health checks to the core trust surface,
- ensure update/upgrade does not silently pull AI models,
- document the safe update path for users.

## Files changed

- `scripts/upgrade.sh`
- `tests/update-upgrade-profile-smoke.sh`
- `tests/upgrade-rollback-smoke.sh`
- `README.md`
- `pkg/README.md`
- `docs/release/evidence/2026-05-11-safe-upgrade-progress.md`

## Protected files touched

- `scripts/upgrade.sh`

Reason: v1.0 update safety and rollback evidence.

## Commands run

- `bash tests/update-upgrade-profile-smoke.sh`
- `bash tests/upgrade-rollback-smoke.sh`
- `bash scripts/upgrade.sh --dry-run --profile core`
- `git diff --check`

## Test output summary

- `bash tests/update-upgrade-profile-smoke.sh`: PASS.
- `bash tests/upgrade-rollback-smoke.sh`: PASS.
- `bash scripts/upgrade.sh --dry-run --profile core`: PASS.
- Dry-run showed backup commands for:
  - git SHA,
  - `docker-compose.yml`,
  - `.env`,
  - `~/.merlin/install-manifest.json`,
  - image digests.
- Dry-run did not pull AI models.

## Tests skipped and why

- Live upgrade was not run because the repo had active local edits during this
  slice and the dry-run was enough to validate command construction.
- Live rollback was not run because rollback smoke already uses fake Docker/Git
  to exercise the failure path without disrupting the running local stack.

## Failures found

1. The first rollback smoke assertion looked for the manifest backup in the fake
   command log, but `cp` is not faked/logged in that smoke.

## Failure categories

- Test design
- Upgrade evidence coverage

## Root cause or current hypothesis

The rollback smoke logs fake `docker`, `git`, and `curl` calls. It does not log
real `cp`, so manifest backup coverage needed a static contract assertion.

## Fix applied

- `upgrade.sh` backs up `~/.merlin/install-manifest.json`.
- `upgrade.sh` health checks now include:
  - Merlin Dashboard,
  - Open WebUI,
  - LiteLLM readiness,
  - Qdrant,
  - local Ollama.
- Update/upgrade smoke checks:
  - core profile remains profile-aware,
  - manifest backup is present,
  - Dashboard/LiteLLM/Ollama health checks are present,
  - no `ollama pull` occurs in update/upgrade.
- Rollback smoke checks manifest backup as a script contract.
- README and package README document rollback-aware upgrade commands.

## Retest result

- Focused smokes pass.
- Upgrade dry-run prints the manifest backup command and keeps AI model pulls
  explicit.

## Regression tests added

- Manifest backup contract in update/upgrade smoke.
- Expanded core health-check endpoint contract.
- No silent model pull assertion.

## Follow-up issues created or recommended

Recommended:

1. Run live `bash scripts/upgrade.sh --profile core` from a clean working tree.
2. Add a user-facing update button later that calls the rollback-aware path.
3. Decide whether `scripts/update.sh` should become a thin wrapper around
   `scripts/upgrade.sh` to avoid two update stories.

## Lesson learned

Safe update is not just pulling newer containers. It must preserve local config,
dependency ownership, and a rollback point before touching the running stack.

## What not to repeat next time

Do not maintain two user-facing update stories long term. Users should see one
safe update action.

## Local Trusted Beta impact

Improved. The rollback-aware update path now includes the dependency ownership
manifest and broader service health checks.

## Public Beta impact

Still blocked until a live upgrade run is captured from a clean tree and the
package install/uninstall evidence is completed.
