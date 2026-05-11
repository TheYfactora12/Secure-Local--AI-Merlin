# 2026-05-11 Package Receipt Cleanup Progress

## Date/time

2026-05-11 12:42:18 EDT

## Branch

`main`

## Starting commit SHA

`6c2f5522213bc16728f90d2677c94dc516cb7f28`

## Ending commit SHA

Pending commit.

## Target issue(s)

#37, #95, #134

## Scope

Fix the package receipt/branding cleanup item before the next package-path clean
install test:

- new macOS packages should register as Merlin AI, not Home AI Elite,
- uninstall should still clean legacy Home AI Elite receipts for old installs,
- unsigned package builds should work under `set -euo pipefail`,
- generated test/evidence artifacts should not be bundled into the `.pkg`.

## Files changed

- `pkg/build-pkg.sh`
- `pkg/scripts/uninstall.sh`
- `tests/pkg-readiness-smoke.sh`
- `tests/uninstall-smoke.sh`
- `docs/release/evidence/2026-05-11-package-receipt-cleanup-progress.md`

## Protected files touched

- `pkg/build-pkg.sh`
- `pkg/scripts/uninstall.sh`

Reason: this is package/uninstall release hardening. The changes are limited to
package identity, receipt cleanup, unsigned package command construction, and
build payload excludes.

## Commands run

- `git status --short --branch`
- `rg -n "com\.homeai\.elite|homeai\.elite|Home AI Elite|home-ai-elite|HOME_AI|package-id|pkgutil|identifier" install.sh pkg scripts tests docs README.md .github cli launchd`
- `rg -n "com\.merlin|merlin\.ai|Merlin AI|PKG_IDENTIFIER|PACKAGE_ID|pkg id|receipt|forget" pkg scripts tests install.sh docs README.md`
- `sed -n '1,220p' pkg/build-pkg.sh`
- `sed -n '1,380p' pkg/scripts/uninstall.sh`
- `sed -n '1,180p' tests/uninstall-smoke.sh`
- `sed -n '1,180p' tests/pkg-readiness-smoke.sh`
- `bash -n pkg/build-pkg.sh && bash -n pkg/scripts/uninstall.sh && bash -n tests/pkg-readiness-smoke.sh && bash -n tests/uninstall-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/uninstall-smoke.sh`
- `git diff --check`
- `bash pkg/scripts/uninstall.sh --dry-run --yes --keep-files | rg -n "pkgutil --forget|package receipt"`
- `bash pkg/build-pkg.sh`
- `rg -n "com\.merlin\.ai|com\.homeai\.elite|pkg-ref|identifier" pkg/build/distribution.xml`
- `pkgutil --payload-files merlin-ai-0.8.6.pkg | rg '^\./usr/local/merlin-ai/(\.venv-test|\.pytest_cache|\.DS_Store|docs/release/evidence/assets)' || true`
- `pkgutil --payload-files merlin-ai-0.8.6.pkg | sed -n '1,40p'`
- `pkgutil --check-signature merlin-ai-0.8.6.pkg`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/pkg-local-sign-smoke.sh`
- `bash pkg/release-preflight.sh`

## Test output summary

- `bash tests/pkg-readiness-smoke.sh`: PASS.
- `bash tests/uninstall-smoke.sh`: PASS.
- `bash tests/installer-branding-smoke.sh`: PASS.
- `bash tests/pkg-local-sign-smoke.sh`: PASS.
- `git diff --check`: PASS.
- `bash pkg/release-preflight.sh`: PASS with expected warnings that Developer
  ID/notarization credentials are not configured on this machine.
- `bash pkg/build-pkg.sh`: PASS after the unsigned build fix.
- Rebuilt unsigned package: `merlin-ai-0.8.6.pkg`, 7.3 MB.
- Generated distribution now contains package id `com.merlin.ai`.
- Payload inspection found no `.venv-test`, `.pytest_cache`, `.DS_Store`, or
  `docs/release/evidence/assets` paths in the rebuilt package.
- `pkgutil --check-signature merlin-ai-0.8.6.pkg`: `Status: no signature`,
  expected for unsigned local build.

## Tests skipped and why

- Full `.pkg` double-click install was not run in this pass.
- Developer ID signing/notarization was not run because it remains deferred and
  local credentials are not configured.
- Legacy receipt removal was dry-run verified only; forgetting real receipts
  requires admin privileges and a real installed receipt state.

## Failures found

1. Package builder used the retired receipt identifier `com.homeai.elite` for
   new builds.
2. Unsigned package build failed with:
   `pkg/build-pkg.sh: line 216: sign_args[@]: unbound variable`.
3. The first generated package payload included local/generated artifacts:
   `.venv-test`, `.pytest_cache`, `.DS_Store`, and release evidence screenshots.
   The package was 136 MB before cleanup.

## Failure category

- Package build
- Package signing/notarization
- Uninstall
- Documentation mismatch
- CI/static smoke gap
- Release packaging hygiene

## Root cause or current hypothesis

1. Brand reset updated paths/copy but did not update the package receipt
   identifier.
2. Bash with `set -u` treats expansion of an empty array as an unbound variable
   in this environment, so the unsigned `pkgbuild` path could not share a
   command line that expands `sign_args`.
3. `pkg/build-pkg.sh` excluded some runtime artifacts but not test virtualenvs,
   pytest cache, Finder metadata, or generated evidence screenshot assets.

## Fix applied

- Changed package builder current id from `com.homeai.elite` to
  `com.merlin.ai`.
- Changed uninstaller current id to `com.merlin.ai` and added
  `LEGACY_PKG_IDS=("com.homeai.elite")` so old receipts are still cleaned.
- Split signed and unsigned `pkgbuild` command paths so unsigned builds do not
  expand `sign_args`.
- Excluded `.venv-test/`, `.pytest_cache/`, `.DS_Store`, and
  `docs/release/evidence/assets/` from package payload staging.

## Retest result

- Receipt dry-run prints both:
  - `sudo pkgutil --forget com.merlin.ai`
  - `sudo pkgutil --forget com.homeai.elite`
- Rebuilt package distribution references `com.merlin.ai`.
- Rebuilt package size dropped from 136 MB to 7.3 MB.
- Payload inspection found no generated test/evidence artifacts.
- Package readiness and uninstall smoke tests pass.

## Regression test added or reason not added

Updated:

- `tests/pkg-readiness-smoke.sh` verifies `com.merlin.ai`, rejects the old
  builder id, verifies payload excludes, and guards unsigned `pkgbuild` from
  `sign_args` expansion.
- `tests/uninstall-smoke.sh` verifies dry-run receipt cleanup covers both the
  new Merlin AI receipt and the legacy Home AI receipt.

## Follow-up issues created or recommended

Recommended:

1. Run a full `.pkg` double-click install/uninstall test on a clean Mac using
   the rebuilt package.
2. Decide whether package payload should also exclude developer-only directories
   such as `tests/`, `.github/`, and deep release evidence Markdown before a
   public beta package.

## Lesson learned

Package build tests need at least one real local package build when package
identity or payload rules change. Static checks caught intended text, but the
real `pkgbuild` run exposed both the empty-array failure and payload bloat.

## What not to repeat next time

Do not rely only on static package smokes for packaging changes. Rebuild the
package and inspect both `distribution.xml` and `pkgutil --payload-files` before
claiming package-path improvement.

## Next recommended step

Commit this package cleanup and wait for CI. Then run the full `.pkg` user-path
install/uninstall test when ready.

## Local Trusted Beta impact

Improved. New packages now carry Merlin AI package identity, legacy receipts are
still handled, unsigned package builds work, and the generated package is much
cleaner.

## Public Beta impact

Public Beta remains blocked until full package install/uninstall evidence,
signing/notarization strategy, and non-technical user validation are complete.
