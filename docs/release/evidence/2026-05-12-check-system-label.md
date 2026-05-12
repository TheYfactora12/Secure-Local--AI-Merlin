# Check System Label Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Change Summary

- Renamed first-run user-facing `Dashboard` action to `Check System`.
- Kept the action behavior unchanged: it opens the System tab.
- Updated README first-run wording to match the dashboard label.
- Left internal health labels as `Dashboard` where they refer to the local dashboard service.

## Commands Run

```bash
bash tests/dashboard-first-run-smoke.sh
bash tests/release-readiness-readme-smoke.sh
bash tests/dashboard-readiness-smoke.sh
git diff --check
```

## Results

- Dashboard first-run smoke: passed.
- README release-readiness smoke: passed.
- Dashboard readiness smoke: passed.
- Whitespace check: passed.

## Remaining Work

- Batch package retest with the latest dashboard copy slices before claiming this label is present in installed runtime at `localhost:8888`.
