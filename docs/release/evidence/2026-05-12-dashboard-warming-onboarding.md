# Dashboard Warming Onboarding Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Change Summary

- Added a first-run Merlin warming panel to `dashboard/index.html`.
- The panel checks local dashboard, chat, local model, router, memory, and privacy posture before enabling "Start Chatting".
- The UI keeps the Merlin orb as the center of the chat experience while moving readiness detail into a compact startup surface.
- Added mobile overflow guards so the dashboard clamps to the viewport and keeps tab overflow inside the tab strip.

## Evidence

Local screenshots were captured against the repository dashboard on `localhost:8899`:

- `docs/release/evidence/local/dashboard-warming-desktop.png`
- `docs/release/evidence/local/dashboard-warming-mobile.png`

These screenshot files are local evidence and are intentionally ignored by git.

## Commands Run

```bash
python3 -m http.server 8899 --directory dashboard
.venv-playwright/bin/python -m playwright install chromium
.venv-playwright/bin/python <dashboard warming desktop/mobile screenshot probe>
bash tests/dashboard-first-run-smoke.sh
bash tests/dashboard-merlin-status-smoke.sh
bash tests/dashboard-tabs-smoke.sh
bash tests/dashboard-browser-qa-smoke.sh
git diff --check
```

## Results

- Desktop Playwright probe: `bodyScroll=1440`, startup card visible, progress `3 / 6`, Start Chatting disabled until chat readiness is available.
- Mobile Playwright probe: `bodyScroll=390`, startup card visible, progress `3 / 6`, Start Chatting disabled until chat readiness is available.
- Dashboard first-run smoke: passed.
- Dashboard Merlin status smoke: passed.
- Dashboard tabs smoke: passed.
- Dashboard browser QA smoke: passed.
- Whitespace check: passed.

## Remaining Work

- Rebuild and reinstall the package before claiming this change is present in the installed runtime at `localhost:8888`.
- Installer retest is required because the package artifact must include the updated dashboard files.
- Wizard-hat/orb animation can be improved later, but no animation is required for this readiness hardening slice.
