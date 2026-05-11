# 2026-05-10 Onboarding Proof Progress

## Date/time

2026-05-10 22:43:37 EDT

## Branch

`main`

## Starting commit SHA

`c0f412b10634bb3414fae472230392017d3644c9`

## Ending commit SHA

`57419f5e15463d255f8f206b30d36588867e1d5c`

## Target issue(s)

#37, #95, #106, #134

## Scope

Advance the v1.0 first-run onboarding proof on `localhost:8888` without adding
new runtime features:

- show "Merlin AI is running",
- make privacy status plain English,
- make the three first actions obvious,
- show included service status in user language,
- keep optional services marked optional/off instead of failed,
- preserve read-only dashboard behavior and policy-gated chat routing.

## Files changed

- `dashboard/index.html`
- `tests/dashboard-first-run-smoke.sh`
- `docs/release/evidence/2026-05-10-onboarding-proof-progress.md`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/*`

## Protected files touched

None.

## Commands run

- `git status --short --branch`
- `rg --files dashboard docs tests scripts pkg`
- `rg -n "localhost:8888|Dashboard|Merlin AI is running|Start Chatting|Open WebUI|n8n|Qdrant|Ollama|Your AI is private|Home AI Elite" README.md dashboard docs install.sh pkg scripts tests .github`
- `sed -n '1,220p' dashboard/index.html`
- `sed -n '1,220p' tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-first-run-smoke.sh`
- `bash tests/dashboard-security-center-smoke.sh`
- `git diff --check`
- `curl -fsS --max-time 5 http://localhost:8888 | rg -n "Merlin AI is running|Open the local chat workspace|first-run-dashboard|optional off"`
- `python3 scripts/dashboard-browser-qa.py --check-deps`
- `.venv-test/bin/python scripts/dashboard-browser-qa.py --check-deps`
- `.venv-test/bin/python scripts/dashboard-browser-qa.py --output-dir docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa`
- `PYTHON_BIN=.venv-test/bin/python bash scripts/setup-browser-qa.sh`
- `bash tests/dashboard-browser-qa-smoke.sh`
- `bash tests/installer-branding-smoke.sh`
- `bash tests/pkg-readiness-smoke.sh`

## Test output summary

- `bash tests/dashboard-first-run-smoke.sh`: PASS.
- `bash tests/dashboard-security-center-smoke.sh`: PASS.
- `git diff --check`: PASS.
- Live `curl http://localhost:8888` confirmed the dashboard serves the updated
  onboarding copy and status IDs.
- `.venv-test/bin/python scripts/dashboard-browser-qa.py --check-deps`: PASS.
- `PYTHON_BIN=.venv-test/bin/python bash scripts/setup-browser-qa.sh`: PASS;
  Playwright `1.59.0` and Chromium dependencies were already installed in the
  repo virtualenv.
- `.venv-test/bin/python scripts/dashboard-browser-qa.py --output-dir docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa`:
  PASS. Desktop and mobile screenshots plus `summary.json` were written. The
  mobile pass includes a visible compact first-run banner so the onboarding
  proof is not hidden behind the collapsed side panel.
- `bash tests/dashboard-browser-qa-smoke.sh`: PASS.
- `bash tests/installer-branding-smoke.sh`: PASS.
- `bash tests/pkg-readiness-smoke.sh`: PASS.

## Browser evidence

- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/desktop-1280-empty.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/desktop-1280-typed.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/desktop-1280-rooms.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/desktop-1280-rooms-guard.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/mobile-375-empty.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/mobile-375-typed.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/mobile-375-rooms.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/mobile-375-rooms-guard.png`
- `docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa/summary.json`

## Tests skipped and why

- Full `.pkg` double-click onboarding test was not run in this pass.
- Authenticated Open WebUI chat was not run; first-run admin setup belongs to a
  separate browser workflow.
- Developer ID/notarization remains deferred by product decision.

## Failures found

1. `python3 scripts/dashboard-browser-qa.py --check-deps` failed because the
   global/system Python environment did not have Playwright installed.

## Failure category

- Test design gap
- CI/static smoke gap
- Documentation mismatch

## Root cause or current hypothesis

The repo already has `.venv-test` with Python Playwright installed, but the
global `python3` command points at a different Python environment. Browser QA is
repeatable when run through `.venv-test/bin/python` or via
`PYTHON_BIN=.venv-test/bin/python bash scripts/setup-browser-qa.sh`.

## Fix applied

- Ran the browser QA dependency setup using the repo virtualenv:
  `PYTHON_BIN=.venv-test/bin/python bash scripts/setup-browser-qa.sh`.
- Ran the browser QA through `.venv-test/bin/python`.
- Recorded the correct command path in this evidence note.

## Retest result

- `.venv-test/bin/python scripts/dashboard-browser-qa.py --check-deps`: PASS.
- `.venv-test/bin/python scripts/dashboard-browser-qa.py --output-dir docs/release/evidence/assets/2026-05-10-onboarding-proof-browser-qa`:
  PASS.

## Regression test added or reason not added

Updated `tests/dashboard-first-run-smoke.sh` so first-run onboarding must keep:

- local chat action to `http://localhost:3000`,
- automation action to `http://localhost:5678`,
- status IDs for dashboard, chat, local model, router, memory, automation,
  coding agent, MCP config, private search, and web search,
- optional services marked `optional off`.

No new test was needed for the Playwright interpreter gap because
`tests/dashboard-browser-qa-smoke.sh` already verifies the setup script and the
browser QA harness. The lesson is recorded here as command guidance.

## Follow-up issues created or recommended

Recommended:

1. Add a contributor note that browser QA should run with
   `.venv-test/bin/python scripts/dashboard-browser-qa.py` or the setup script
   with `PYTHON_BIN=.venv-test/bin/python`.
2. Run the same onboarding proof through the `.pkg` install path on a clean Mac.

## Lesson learned

Browser QA should use the repo-managed Python environment, not whatever
`python3` happens to resolve to on the machine.

## What not to repeat next time

Do not classify missing Playwright in the global Python interpreter as a product
failure when the repo virtualenv is already provisioned. Use the repo command
first and document the interpreter path.

## Next recommended step

Commit the dashboard onboarding proof and evidence, wait for CI, then move to
the package receipt/branding cleanup issue before the `.pkg` clean-machine test.

## Local Trusted Beta impact

Improved. The dashboard first screen now gives a non-technical user the three
expected first actions and honest local service status, with desktop/mobile
browser screenshot evidence.

## Public Beta impact

Public Beta remains blocked until `.pkg` install evidence, first-run Open WebUI
account setup guidance, package receipt branding cleanup, and non-technical
user validation are complete.
