# Continuous Failure Learning Loop

Last updated: 2026-05-08

## Purpose

Every failed test, install, package run, service start, UI check, or confusing
user experience must become reusable project knowledge. Merlin AI should get
faster to diagnose and safer to release after every failure.

This rule applies to Local Trusted Beta work, installer validation, dashboard
readiness, package signing, CI, and all future release gates.

## Failure Response Rule

When a failure happens:

1. Stop broad implementation.
2. Preserve logs/output.
3. Classify the failure.
4. Identify root cause or state uncertainty.
5. Check whether the failure touches protected areas.
6. Decide whether the fix belongs in current issue scope.
7. If in scope, make the smallest safe fix.
8. Add or update a regression test.
9. Retest.
10. Document the lesson learned.
11. Create or recommend a focused issue for anything outside scope.

Do not stack multiple speculative fixes. Do not rewrite systems to fix one
failure. Do not hide failures in final responses or evidence notes.

## Required Failure Capture Fields

For every failure, record:

- what was being tested
- exact command or user action
- expected result
- actual result
- error output or screenshot reference
- failure category
- suspected root cause
- files or systems involved
- risk level
- fix attempted
- retest result
- regression test added or reason not added
- follow-up issue created or recommended
- lesson learned
- what not to repeat next time
- whether the failure changes roadmap, docs, tests, or release readiness

## Failure Categories

- Installer flow
- Package build
- Package signing/notarization
- Non-interactive mode
- Postinstall
- Uninstall
- Reinstall
- Upgrade
- Launchd/autostart
- Docker dependency
- Ollama/native model runtime
- LiteLLM/model router
- Qdrant/memory vault
- Open WebUI/chat workspace
- Wizard HQ/dashboard
- Status API 8765
- Task API 8766
- No-cloud/default privacy
- Surprise model download
- Secret/log redaction
- Port conflict
- Low-memory/8GB behavior
- UX/readiness confusion
- Documentation mismatch
- CI/static smoke gap
- Test design gap
- Roadmap/governance drift

## Failure Decision Checklist

For every failure, decide:

- Is this a true defect?
- Is this expected degraded behavior?
- Is this a documentation gap?
- Is this a test gap?
- Is this a user-experience gap?
- Is this a release blocker?
- Is this a future issue?
- Is this safe to fix now?
- Should we stop and create an issue instead?

If unsure, stop broad implementation and write the issue.

## Installer Failure Learning Rule

Installer failures are high-risk. If any installer, package, postinstall,
uninstall, reinstall, upgrade, launchd, or non-interactive mode failure occurs:

1. Stop broad changes.
2. Capture exact command and output.
3. Classify whether the failure is installer logic, package resource, package
   script, permissions, macOS trust/signing, Docker dependency, model runtime,
   service startup, documentation mismatch, user error, or environment-specific.
4. Confirm whether `install.sh` was changed.
5. Confirm whether `pkg/scripts/postinstall` was changed.
6. Confirm whether uninstall behavior was affected.
7. Confirm whether `HOME_AI_SKIP_MODEL_PULLS=true` remains protected.
8. Confirm whether non-interactive install still works.
9. Confirm whether no cloud/API default behavior changed.
10. Add or update installer/package smoke tests if reproducible.
11. Record retest results.
12. Create or recommend a focused issue if not fixed in current scope.

Installer failures must be recorded in the dated evidence log.

## Evidence Log Requirement

Every build/test session must create or update a dated evidence note:

```text
docs/release/evidence/YYYY-MM-DD-<issue-or-scope>-progress.md
```

The note must include:

- Date/time
- Branch
- Starting commit SHA
- Ending commit SHA if changed
- Target issue(s)
- Scope
- Files changed
- Protected files touched
- Commands run
- Test output summary
- Tests skipped and why
- Failures found
- Failure category
- Root cause or current hypothesis
- Fix applied
- Retest result
- Regression test added or reason not added
- Follow-up issues created or recommended
- Lesson learned
- What not to repeat next time
- Next recommended step
- Local Trusted Beta impact
- Public Beta impact

No "done" without an evidence log. No "tested" without commands. No "fixed"
without retest. No "ready" without pass/fail evidence.

## Smarter After Every Failure Rule

After each failed test or failed install, improve the project in at least one of
these ways:

1. Add a regression test.
2. Improve an existing smoke test.
3. Improve a runbook.
4. Improve an error message.
5. Improve a dashboard readiness state.
6. Improve troubleshooting docs.
7. Create a focused follow-up issue.
8. Add a known failure pattern entry.
9. Add a do-not-repeat note.
10. Update the evidence pack.

If none of these are appropriate, explain why in the evidence note.

## Known Failure Pattern Format

Use this format when adding a reusable failure pattern:

```markdown
### Failure Pattern: <short name>

**Date first seen:**
YYYY-MM-DD

**Category:**
Installer / Dashboard / API / Memory / CI / etc.

**Symptoms:**
What the user or test saw.

**Command or action:**
Exact command or action that exposed it.

**Expected:**
What should have happened.

**Actual:**
What happened.

**Likely root cause:**
Best known explanation.

**Confirmed root cause:**
Fill in once proven.

**Fix:**
What fixed it.

**Regression test:**
Test added or updated.

**Retest result:**
Pass/fail and date.

**Do not repeat:**
What future Codex sessions must avoid.

**Related issue/PR/commit:**
Links or identifiers.
```

## Failure-To-Issue Rule

If a failure is not fixed immediately, create or recommend a GitHub issue with:

- Title
- Goal
- Evidence
- Steps to reproduce
- Expected result
- Actual result
- Affected files/systems
- Suspected root cause
- Risk level
- Scope
- Out of scope
- Acceptance criteria
- Manual test
- Automated test idea
- Rollback guidance
- Related issue/PR/commit

If GitHub write access is unavailable, put the exact issue title and body in the
final response.

## Release Readiness Impact Rule

Every failure must be classified as one of:

- No release impact
- Local Trusted Beta blocker
- Public Beta blocker
- Public Release blocker
- Unknown, needs investigation

If a failure affects install, uninstall, reinstall, upgrade, no-cloud defaults,
surprise model downloads, service startup, Wizard HQ readiness, privacy, or
local-only behavior, it is at least a Local Trusted Beta blocker until evidence
proves otherwise.

Do not downgrade blocker status without evidence.

## Junior Engineer Safety Rule

Treat every release-readiness run like a junior engineer is making changes at
2 AM:

- Verify before editing.
- Prefer docs/specs before risky code.
- Prefer small PRs.
- Do not refactor while debugging.
- Do not change protected files casually.
- Do not hide failed tests.
- Do not say "probably."
- If unsure, stop and write the issue.
- If a fix feels broad, split it.
- If a test fails, learn from it.
- If the same failure happens twice, add a regression test or runbook entry.
