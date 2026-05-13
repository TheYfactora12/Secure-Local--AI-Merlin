# Model Readiness UX Polish - 2026-05-12

## Target

- Issue focus: #95 Product push audit / release readiness evidence
- Gap found during: `docs/release/evidence/2026-05-12-network-disconnected-launch-validation.md`

## Problem

Network-disconnected core launch passed, but Merlin could not answer chat
because no generation-capable local model was installed. The observed
user-facing message was technically correct but too terminal-first for a
non-technical beta user:

```text
No chat-capable local model is installed. Install one manually with bash scripts/add-model.sh qwen2.5:7b. Merlin will not download models from the browser.
```

## Change

The chat sidebar Local Brain card now keeps the security boundary but gives a
clearer product path:

- tells the user Merlin needs a local chat model before offline chat can answer,
- sends the user to the Brains tab for reviewed setup,
- states that no browser download will run,
- keeps the manual command in the Brains model library warning/disclosure path.

This preserves the rule that the browser dashboard does not run model downloads
or shell commands.

## Validation

```bash
bash tests/dashboard-model-readiness-smoke.sh
bash tests/dashboard-readiness-smoke.sh
bash tests/dashboard-first-run-smoke.sh
git diff --check
```

Results:

- Dashboard model readiness UX smoke: passed.
- Dashboard readiness smoke: passed.
- Dashboard first-run smoke: passed.
- `git diff --check`: passed.

## Release Impact

- Local Trusted Beta: improves first-run/no-model UX while preserving
  manual-only model installation.
- Public Beta: no claim.
- Public Release: no claim.

## Remaining Boundary

This change does not install a model. A future guided setup path may make model
installation easier, but it must remain policy-gated and outside browser-side
shell execution.
