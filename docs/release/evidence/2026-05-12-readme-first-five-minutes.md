# README First 5 Minutes Evidence - 2026-05-12

## Target

- Issue focus: #37 Public release onboarding and packaging hardening
- Supporting focus: #95 Product push audit / release readiness evidence

## Change Summary

- Added a `First 5 Minutes` section to `README.md`.
- Aligned README onboarding with the installed dashboard flow:
  - open Merlin Dashboard,
  - wait for the warming card,
  - click `Start Chatting`,
  - use `See Details` / System if warming persists,
  - run doctor and install-log commands only when needed.
- Added README smoke coverage so this user path remains documented.

## Commands Run

```bash
bash tests/release-readiness-readme-smoke.sh
bash tests/dashboard-readiness-smoke.sh
git diff --check
```

## Results

- README release-readiness smoke: passed.
- Dashboard readiness smoke: passed.
- Whitespace check: passed.

## Remaining Work

- No package retest required for README-only documentation alignment.
