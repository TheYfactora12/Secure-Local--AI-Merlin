# 2026-05-10 Merlin AI Reset Progress

## Date/time

2026-05-10 21:25:38 EDT

## Branch

`main`

## Starting commit SHA

`fe4a1b2f5e28a83f3768e962ce025a169ce1407c`

## Ending commit SHA

`1b552f6e3f4af75fb9008da0f51258b6e19e35b6`

## Target issues

#37, #95, #134, #122, #123, #106. Developer ID #64 deferred.

## Scope

Rename active product surfaces to Merlin AI, reset v1.0 scope to the five focus
areas, verify installer/dashboard/package/docs smokes, and record failures.

## Files changed

Primary areas:

- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `install.sh`
- `dashboard/index.html`
- `pkg/`
- `launchd/`
- `scripts/`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
- `docs/CODEX_MASTER_PROMPT_V3.md`
- `docs/product/`
- `tests/`
- `.github/workflows/`

## Protected files touched

- `install.sh`
- `pkg/build-pkg.sh`
- `pkg/scripts/postinstall`
- `pkg/scripts/uninstall.sh`
- `launchd/*.plist`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`

Reason: required product rename/reset and smoke alignment. No cloud defaults,
model-pull defaults, approval boundaries, or uninstall semantics were
intentionally weakened.

## Commands run

- `gh repo view --json nameWithOwner,url,defaultBranchRef`
- `gh issue list --state open --limit 100 --json number,title,labels,milestone,state`
- `rg -n "Home AI Elite|HOME AI ELITE|Wizard AI|WIZARD AI|home-ai-elite"`
- `git diff --check`
- `bash -n install.sh`
- `bash install.sh --help`
- `bash -n pkg/scripts/postinstall`
- `bash -n pkg/scripts/uninstall.sh`
- `bash -n pkg/build-pkg.sh`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/release-readiness-readme-smoke.sh`
- `bash tests/product-north-star-smoke.sh`
- `bash tests/codex-master-prompt-v3-smoke.sh`
- `bash tests/master-prompt-smoke.sh`
- `bash tests/future-ideas-smoke.sh`
- `bash tests/merlin-ai-expansion-boundaries-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-native-chat-smoke.sh`
- `bash tests/dashboard-merlin-status-smoke.sh`
- `bash tests/dashboard-tabs-smoke.sh`
- `bash tests/dashboard-readiness-smoke.sh`
- `bash tests/dashboard-model-readiness-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `bash tests/dashboard-settings-policy-smoke.sh`
- `bash tests/dashboard-browser-qa-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`
- `bash tests/uninstall-smoke.sh`
- `bash tests/pkg-local-sign-smoke.sh`
- `bash tests/pkg-signing-preflight-smoke.sh`
- `bash tests/backup-profile-smoke.sh`
- `bash tests/installer-model-pull-policy-smoke.sh`
- `bash tests/merlin-status-api-smoke.sh`
- `bash tests/release-workflow-smoke.sh`
- `bash tests/sast-gitleaks-smoke.sh`
- `bash tests/launchd-core-smoke.sh`
- `bash tests/wizard-start-status-api-smoke.sh`
- `bash tests/core-install-budget-smoke.sh`
- `bash tests/future-ideas-smoke.sh` after adding the Rooms future backlog.

## Test output summary

- `git diff --check`: PASS after trailing-whitespace fix.
- Shell syntax checks: PASS.
- Installer/package/uninstall/signing smokes: PASS.
- README/product/roadmap/master-prompt/future-boundary smokes: PASS after
  aligning stale assertions.
- Dashboard static smokes: PASS.
- Merlin status API smoke: PASS, read-only and redacted.
- Release workflow smoke: PASS.
- Launchd/static lifecycle smokes: PASS.
- Core install budget smoke: PASS. Core install elapsed 68s; follow-on core
  live smoke reported 18 passed, 0 warnings, 0 failures.
- `tests/sast-gitleaks-smoke.sh`: SKIP locally because the `gitleaks` CLI is not
  installed; CI gitleaks gate is configured.

## Tests skipped and why

- Full clean-machine package install/uninstall/reinstall/upgrade was not run in
  this pass because the current workspace is the active development machine and
  already has services/state. A full clean Mac retest remains required before
  Local Trusted Beta or public beta claims.
- Developer ID/notarization live validation skipped by product decision; #64 is
  deferred until final product surface is complete.

## Failures found

1. `git diff --check` failed on trailing whitespace in
   `docs/scrum/SCRUM_MANAGEMENT.md` and `tests/README.md`.
2. `tests/product-north-star-smoke.sh` failed after product copy changed:
   missing exact phrase `Merlin is the visible assistant`.
3. `tests/merlin-ai-expansion-boundaries-smoke.sh` failed because it expected a
   stale exact line and old roadmap section names.
4. `tests/dashboard-first-run-smoke.sh` failed because it expected the old long
   talk-mode sentence after the UI switched to shorter copy.
5. `tests/backup-profile-smoke.sh` failed because backup volume naming derived
   from the local checkout folder, which still produced old stack prefixes in a
   renamed product pass.

## Failure categories

- Documentation mismatch
- CI/static smoke gap
- Test design gap
- Roadmap/governance drift
- Installer/support naming compatibility

## Root cause or current hypothesis

The product reset renamed the active product and simplified scope faster than
the static smokes and helper scripts were updated. One helper, `scripts/backup.sh`,
also used local folder basename as implicit Compose project name, which made
brand/volume naming depend on clone directory instead of product identity.

## Fix applied

- Removed trailing whitespace and reran `git diff --check`.
- Updated product north star wording and smoke assertions.
- Updated expansion boundary wording and smoke assertions.
- Updated dashboard smoke to enforce local audio consent without the old long
  sentence.
- Changed `scripts/backup.sh` default Compose project name to `merlin-ai` unless
  `COMPOSE_PROJECT_NAME` is explicitly set.

## Retest result

All failed commands above passed after their scoped fixes.

## Regression test added or reason not added

- Added `tests/codex-master-prompt-v3-smoke.sh`.
- Added `tests/future-ideas-smoke.sh`.
- Added `tests/merlin-ai-expansion-boundaries-smoke.sh`.
- Added/updated product, README, dashboard, backup, installer-branding, and
  master-prompt smokes to guard the reset.

## Follow-up issues created or recommended

Recommended:

1. Rename internal compatibility identifiers from `HOME_AI_*` and
   `com.homeai.*` to Merlin-safe names with migration tests.
2. Run clean Mac package install/uninstall/reinstall/upgrade evidence after
   the Merlin AI reset lands.
3. Decide final GitHub repo slug: current remote is
   `TheYfactora12/Secure-Local--AI-Merlin`; target may be `merlin-ai`.

## Lesson learned

Brand resets must include static smoke updates and helper-script defaults, not
only visible copy. Directory-derived names are fragile during product rename.

## What not to repeat next time

Do not mechanically rename archive/evidence history. Preserve historical logs
and only update active source/docs unless explicitly rewriting history.

## Next recommended step

Triage open GitHub issues against the five v1.0 focus areas, then push a focused
cleanup commit once the user approves the issue actions.

Update after issue triage: 8 open issues remain. #37, #95, #106, and #134 are
active v1.0/release-readiness items. #81 through #84 remain open but deferred
for patent/IP governance. Rooms architecture was captured in
`docs/product/FUTURE_IDEAS.md` as issue-ready future backlog, not opened as
active issues, to protect the reset goal of fewer than 10 open issues and no
new feature work before v1.0 proof.

## Local Trusted Beta impact

Improved. Merlin AI now has aligned active branding, README, roadmap, dashboard
onboarding copy, installer/package copy, and local smoke evidence. Full clean Mac
installer retest is still required.

## Public Beta impact

Improved documentation clarity only. Public Beta remains blocked until clean
install/uninstall/reinstall/upgrade evidence and support/onboarding proof exist.
