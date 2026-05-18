# Merlin Release State Reconciliation

## Bottom line

Merlin AI can currently claim that it is **preparing for controlled local
testing**.

Merlin AI cannot currently claim **public beta**, **public release**,
**enterprise readiness**, or a fully signed-off **Local Trusted Beta** state.

## Documents reviewed

- `README.md`
- `docs/README.md`
- `docs/CANONICAL_PROJECT_STATE.md`
- `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`

## Current allowed claim

The current allowed release/readiness claim is:

**Merlin AI is preparing for controlled local testing.**

This is supported by:

- `README.md`, which says Merlin is not public beta or public release until
  clean install, onboarding, privacy, recovery, and uninstall evidence are
  recorded.
- `docs/CANONICAL_PROJECT_STATE.md`, which explicitly allows only the claim
  “preparing for controlled local testing.”
- `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`, which says Local Trusted
  Beta is not signed off until the manual evidence run is complete.

## Claims not yet allowed

The repo does not currently support claiming:

- public beta
- public release
- compliance-ready
- enterprise-ready
- fully autonomous
- fully cloud-free in every optional configuration
- signed-off Local Trusted Beta

## Evidence gates still open

The following readiness gates remain open based on the Trusted Local Beta
evidence pack:

- full named low/core release-candidate evidence run completed and recorded
- full destructive purge validation completed with explicit approval
- remaining Local Trusted Beta table rows completed
- Public Beta evidence completed after Local Trusted Beta signoff
- Public Release evidence completed after Public Beta signoff

## Conflicting or misleading statements

The main repo-level tension is:

- `README.md` and `docs/CANONICAL_PROJECT_STATE.md` present a conservative
  readiness posture
- `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md` confirms that signoff is
  still incomplete
- `docs/README.md` contains a release status table that can be read as stronger
  than the conservative readiness posture, especially where milestone labels say
  `v1.0 — Stable Installer Release` and several later milestones are complete

That release table may be accurate as milestone history, but without stronger
qualification it can be misread as broader release readiness.

## Recommended doc changes

This reconciliation note does not change any other file.

The next safe review should decide whether to:

1. soften milestone language in `docs/README.md`, or
2. add a clearer qualifier that milestone completion is not the same as current
   public release readiness, or
3. add a direct pointer from `docs/README.md` to the authoritative release
   claim in `docs/CANONICAL_PROJECT_STATE.md` and the evidence pack

## Authoritative source order

For release/readiness wording, use this source order:

1. `docs/CANONICAL_PROJECT_STATE.md`
2. `docs/operations/TRUSTED_LOCAL_BETA_EVIDENCE.md`
3. `README.md`
4. `docs/README.md`

If wording conflicts, the higher item in this list wins.

## Next recommended action

Review this reconciliation note before changing any release/readiness copy in
other Merlin docs.

## Hard limits confirmed

- no code changes
- no install/runtime changes
- no roadmap rewrite
- no production claims
- no secrets or `.env` inspection
- no deploy
- no spend
