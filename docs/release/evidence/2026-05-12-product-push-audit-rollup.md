# Product Push Audit Rollup - 2026-05-12

## Target

- Issue focus: #95 Product push audit, installer retest plan, loading UX, and
  release readiness
- Related closed slice: #37 Public release onboarding and packaging hardening
- Deferred slice: #64 Developer ID signing/notarization

## Current Verdict

Merlin AI is moving north on the v1.0 release-hardening path, but this note
does not claim Local Trusted Beta, Public Beta, or Public Release readiness.

The repo now has evidence for the package install path, installed first-run
onboarding copy, recovery guidance, package uninstall/reinstall loop, and green
CI on the current head. The remaining #95 work is to keep the evidence pack
current and run a named release-candidate validation pass before any beta claim.

Update after this rollup: the release evidence table in
`docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md` is now filled with the current
May 12 package/onboarding verification result. Rows without May 12 evidence are
marked as blocked for beta signoff rather than left as TODO.

## Evidence Confirmed

| Area | Evidence | Result |
|---|---|---|
| Current head | `744f739` | Verified |
| Latest CI | GitHub Actions run `25712920056` | Passed |
| Package install | `docs/release/evidence/2026-05-12-package-check-system-recovery-install.md` | 17 pass, 0 warn, 0 fail |
| Installed dashboard copy | Same package evidence | `Check System`, `Service details`, `Startup checks`, recovery copy present |
| Onboarding polish package run | `docs/release/evidence/2026-05-12-package-onboarding-polish-install.md` | 17 pass, 0 warn, 0 fail |
| Package uninstall/reinstall | `docs/release/evidence/2026-05-11-package-uninstall-verification.md` | Keep-files uninstall and package reinstall verified |
| Upgrade/rollback path | `docs/release/evidence/2026-05-11-safe-upgrade-progress.md` | Documented and tested |
| README first-use guidance | `docs/release/evidence/2026-05-12-readme-first-five-minutes.md` | Documented and smoke-tested |

## #95 Skill-Team Status

| Role | Current assessment |
|---|---|
| Scrum / PM | Pass for scope discipline: #37 closed, #64 deferred, #95 remains evidence umbrella. |
| Product / UX | Pass for first-run clarity improvements; beta claim remains blocked until named evidence run is filled. |
| Frontend | Pass for simplified first-run dashboard checks and no static fake-ready wording. |
| Installer / macOS release | Pass for latest package verification; watch item remains destructive purge and broad-machine validation. |
| DevOps / CI | Pass: latest relevant runs on `main` are green. |
| Security / Privacy | Pass for local-first documented/default posture; continue no-cloud log review during release candidate validation. |
| QA | Watch: release candidate evidence table still needs final named tester/machine/result fill-in. |
| Commercial readiness | Watch: public release remains blocked on #64 and wider user validation. |

## Remaining Gaps

- Fill `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md` as a named release
  candidate run after running the remaining blocked rows: offline launch and
  Magic Mode/audit validation.
- Run or explicitly defer destructive purge validation. This must remain
  opt-in because Docker Desktop, Ollama, and Homebrew may be shared tools.
- Keep #64 open/deferred for Developer ID signing and notarization.
- Keep #106/#134 focused on v1.0 user value only; do not use them to reopen
  broad feature expansion.

## Next Recommended Issue

Continue #95 until the release candidate evidence table is filled. After that,
the next product-critical issue is #134: prove the user value loop without
expanding scope.
