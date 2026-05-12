# 2026-05-11 Full Removal Manifest Progress

## Date/time

2026-05-11 20:28 EDT

## Branch

`main`

## Starting commit SHA

`1e0086d7703c40c30ddde382daec5fe828594bc8`

## Ending commit SHA

Pending commit.

## Target issue(s)

#37, #95, #134

## Scope

Add the foundation for honest full removal:

- write a local install manifest,
- record whether shared dependencies existed before Merlin,
- add explicit dependency purge flags,
- keep default uninstall conservative,
- make dependency removal fail closed without a manifest,
- document the update/upgrade ordering decision.

## Files changed

- `install.sh`
- `pkg/scripts/uninstall.sh`
- `README.md`
- `pkg/README.md`
- `tests/uninstall-smoke.sh`
- `docs/release/evidence/2026-05-11-full-removal-manifest-progress.md`

## Protected files touched

- `install.sh`
- `pkg/scripts/uninstall.sh`

Reason: install/uninstall trust is v1.0 release-hardening scope.

## Commands run

- `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh --profile core --skip-model-pulls --non-interactive`
- `cat ~/.merlin/install-manifest.json`
- `bash pkg/scripts/uninstall.sh --dry-run --yes --purge-dependencies --keep-files --keep-receipt`
- `bash tests/uninstall-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/installer-branding-smoke.sh`
- `git diff --check`

## Test output summary

- Install completed and wrote `~/.merlin/install-manifest.json`.
- Manifest recorded this Mac's Homebrew, Docker Desktop, and Ollama as
  `present_before_install: true` and `installed_by_merlin: false`.
- Dependency-purge dry-run kept shared dependencies because the manifest did
  not mark them as Merlin-installed.
- Missing-manifest dry-run path is covered by smoke test and fails closed.
- Manifest-present dry-run path is covered by smoke test and removes only a
  dependency marked `installed_by_merlin: true`.
- `bash tests/uninstall-smoke.sh`: PASS.
- `bash tests/pkg-readiness-smoke.sh`: PASS.
- `bash tests/installer-branding-smoke.sh`: PASS.
- `git diff --check`: PASS.

## Tests skipped and why

- Live dependency removal was not run because Docker Desktop, Homebrew, and
  Ollama existed before Merlin on this Mac and are shared tools.
- Full `.pkg` double-click install was not rerun in this slice.
- Developer ID signing/notarization remains deferred.

## Failures found

1. The first dependency-purge smoke test depended on the real user's HOME. Once
   the install wrote a manifest, the "missing manifest" assertion no longer
   simulated a missing manifest.
2. Update/upgrade is needed for v1.0 trust, but should follow install,
   uninstall, full-removal, and rollback foundations.

## Failure categories

- Test isolation
- Release sequencing
- Uninstall trust model

## Root cause or current hypothesis

1. Smoke tests must isolate HOME when testing user-state-dependent behavior.
2. A consumer-safe full removal path requires knowing whether shared
   dependencies were installed by Merlin or pre-existed.
3. Update packages are important, but an updater without a reliable uninstall
   and rollback path can strand non-technical users.

## Fix applied

- `install.sh` now writes `~/.merlin/install-manifest.json`.
- The manifest records:
  - install directory,
  - profile,
  - capabilities,
  - whether Homebrew/Docker/Ollama existed before install,
  - whether Merlin installed Homebrew/Ollama,
  - local-first privacy defaults.
- `pkg/scripts/uninstall.sh` now supports:
  - `--purge-dependencies`,
  - `--i-understand-shared-tools`.
- Dependency purge:
  - implies data/image/model purge,
  - fails closed without a manifest,
  - only removes dependencies marked `installed_by_merlin`,
  - keeps Homebrew automatic removal manual-only even if marked installed.
- README and package README document the manifest and preview-first dependency
  purge.
- `tests/uninstall-smoke.sh` now covers missing-manifest and manifest-present
  dependency purge behavior.

## Retest result

- Local install manifest exists and is valid JSON.
- Dependency purge dry-run on this Mac kept pre-existing dependencies.
- Smoke tests pass.

## Regression tests added

- Installer must define and write the manifest.
- README/package README must document the manifest and dependency purge preview.
- Uninstaller must expose explicit dependency purge and confirmation flags.
- Uninstaller must be manifest-gated.
- Missing manifest must fail closed.
- Manifest-marked Ollama removal must appear in dry-run.
- Pre-existing Docker/Homebrew must be kept in dry-run.

## Follow-up issues created or recommended

Recommended:

1. Package update/upgrade path:
   safe update check, download/build validation, backup, apply, health check,
   rollback.
2. Full removal UI:
   `Remove Merlin`, `Full Removal`, and `Full Removal + Dependencies`.
3. Track Docker Desktop installation when Merlin eventually installs it rather
   than merely requiring it.
4. Launchd label migration from `com.homeai.*` to `com.merlin.*`.

## Lesson learned

Full removal is not the same as destructive removal. The product must remove
everything Merlin owns while protecting shared tools unless the user explicitly
chooses otherwise.

## What not to repeat next time

Do not test user-state behavior against the real HOME when the test needs a
missing, fresh, or alternate user state.

## Local Trusted Beta impact

Improved. Merlin now records dependency ownership and has a guarded path toward
true full removal.

## Public Beta impact

Still blocked until the full removal path is exercised from the packaged app,
including admin prompts, receipt cleanup, and dependency choices.
