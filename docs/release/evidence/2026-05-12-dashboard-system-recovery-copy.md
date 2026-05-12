# Dashboard System Recovery Copy Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Change Summary

- Added plain-English System tab guidance for users who click `See Details` after Merlin stays warming.
- Added a privacy-preserving warning: do not add API keys or cloud providers to fix startup.
- Added support evidence guidance so users know what local logs and checks to send.
- Kept the dashboard read-only; no browser start/stop/restart controls were added.

## Commands Run

```bash
bash tests/dashboard-readiness-smoke.sh
bash tests/dashboard-merlin-status-smoke.sh
bash tests/dashboard-first-run-smoke.sh
bash tests/dashboard-tabs-smoke.sh
git diff --check
```

## Results

- Readiness smoke: passed.
- Merlin status smoke: passed.
- First-run smoke: passed.
- Tabs smoke: passed.
- Whitespace check: passed.

## Remaining Work

- Rebuild and reinstall the package before claiming this System tab recovery copy is present in installed runtime at `localhost:8888`.
