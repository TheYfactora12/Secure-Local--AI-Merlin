# Dashboard Onboarding Polish Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Change Summary

- Reduced first-run chat screen noise by moving service chips behind a `Service details` disclosure.
- Reduced warming-card noise by moving per-service startup tiles behind a `Startup checks` disclosure.
- Preserved all live readiness IDs and JavaScript updates so the UI remains evidence-backed.
- Kept the primary first-run path focused on `Start Chatting`, with `See Details` available for recovery and service health.

## Local Visual Evidence

Captured against the repository dashboard on `localhost:8899`:

- `docs/release/evidence/local/dashboard-onboarding-polish-desktop.png`
- `docs/release/evidence/local/dashboard-onboarding-polish-mobile.png`

These local screenshot files are intentionally ignored by git.

## Commands Run

```bash
python3 -m http.server 8899 --directory dashboard
bash tests/dashboard-readiness-smoke.sh
bash tests/dashboard-first-run-smoke.sh
bash tests/dashboard-merlin-status-smoke.sh
bash tests/dashboard-tabs-smoke.sh
git diff --check
```

## Results

- Readiness smoke: passed.
- First-run smoke: passed.
- Merlin status smoke: passed.
- Tabs smoke: passed.
- Whitespace check: passed.
- Playwright probe confirmed desktop/mobile body width stayed within viewport and both disclosures are closed by default.

## Remaining Work

- Rebuild and reinstall the package before claiming this polish is present in installed runtime at `localhost:8888`.
