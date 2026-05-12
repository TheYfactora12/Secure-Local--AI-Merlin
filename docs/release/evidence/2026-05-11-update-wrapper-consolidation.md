# 2026-05-11 Update Wrapper Consolidation

## Date/time

2026-05-11 20:52 EDT

## Branch

`main`

## Starting commit SHA

`14fef174da84573998858810d18ff468de296e1c`

## Ending commit SHA

Pending commit.

## Target issue(s)

#37, #95, #134

## Scope

Consolidate update UX so Merlin has one trusted update mechanism.

`scripts/update.sh` now remains as a backwards-compatible command, but delegates
to the rollback-aware `scripts/upgrade.sh` path.

## Files changed

- `scripts/update.sh`
- `tests/update-upgrade-profile-smoke.sh`
- `README.md`
- `pkg/README.md`
- `docs/release/evidence/2026-05-11-update-wrapper-consolidation.md`

## Protected files touched

- `scripts/update.sh`

Reason: update behavior is v1.0 release trust surface.

## Commands run

- `bash tests/update-upgrade-profile-smoke.sh`
- `bash tests/upgrade-rollback-smoke.sh`
- `bash tests/uninstall-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/installer-branding-smoke.sh`
- `bash scripts/update.sh --dry-run --profile core`
- `bash -n scripts/update.sh scripts/upgrade.sh tests/update-upgrade-profile-smoke.sh`
- `git diff --check`

## Test output summary

- `bash tests/update-upgrade-profile-smoke.sh`: PASS.
- `bash tests/upgrade-rollback-smoke.sh`: PASS.
- `bash tests/uninstall-smoke.sh`: PASS.
- `bash tests/pkg-readiness-smoke.sh`: PASS.
- `bash tests/installer-branding-smoke.sh`: PASS.
- `bash scripts/update.sh --dry-run --profile core`: PASS.

## Tests skipped and why

- Live update was not run because this was a wrapper consolidation slice and
  the worktree had active edits.

## Failures found

1. Initial wrapper smoke expected fake `docker` command logs while running the
   wrapper in dry-run mode. Dry-run prints commands instead of executing fake
   Docker.
2. Initial fake Git only simulated one changed upgrade run; wrapper and direct
   upgrade needed deterministic alternating before/after SHAs.

## Failure categories

- Test design
- Update UX consolidation

## Root cause or current hypothesis

The test was still shaped around the old `update.sh` implementation, which
called Docker directly. After consolidation, update output must be tested as
upgrade dry-run output.

## Fix applied

- Replaced `scripts/update.sh` with a thin wrapper around `scripts/upgrade.sh`.
- Preserved `update.sh --help`.
- Added a plain-English line: "Merlin update uses the rollback-aware upgrade
  path."
- Updated smoke test to assert:
  - `update.sh` delegates to `upgrade.sh`,
  - wrapper output routes through rollback-aware dry-run,
  - core service selection remains constrained,
  - optional/heavy services stay out of core,
  - update/upgrade still avoid silent model pulls.
- README and package README now say `update.sh` is compatibility only.

## Retest result

Focused update, rollback, uninstall, package readiness, and installer branding
smokes pass.

## Regression tests added

- `update.sh` must `exec bash "$UPGRADE_SCRIPT" "$@"`.
- `update.sh` must explain rollback-aware behavior.
- Wrapper dry-run must route through the same core pull/up commands as
  `upgrade.sh`.

## Follow-up issues created or recommended

Recommended:

1. Run a live clean-tree `bash scripts/update.sh --profile core` evidence pass.
2. Add a dashboard "Update Merlin" button later that calls the same trusted
   update path through a backend gate.

## Lesson learned

Compatibility commands should preserve user muscle memory, but not preserve
weaker behavior. The old command name can stay; the safer engine must be shared.

## What not to repeat next time

Do not let update and upgrade diverge again.

## Local Trusted Beta impact

Improved. Users now have one update behavior with backup, health check, and
rollback.

## Public Beta impact

Still blocked until live clean-tree update evidence and package install evidence
are complete.
