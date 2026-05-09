# Merlin AI — Active Sprint Board

**Sprint:** v3.1 Product Shell & Policy-Gated Settings  
**Sprint Start:** 2026-05-08  
**Sprint Goal:** Make Wizard HQ the Merlin-native product shell with policy-gated, safe Settings flows before any deeper governance features are built.

> Source of truth: GitHub issues + `docs/CANONICAL_PROJECT_STATE.md`. This file is regenerated each sprint. Do not edit manually — open a GitHub issue to change scope.

---

## 🔴 IN PROGRESS — Actively Being Built

| # | Issue | Owner | Priority | Blocked By |
|---|-------|-------|----------|------------|
| [#106](https://github.com/TheYfactora12/home-ai-elite/issues/106) | v3.1: Wizard HQ Product Shell parent | Engineering | `priority: high` | #102 (status API persistence) |
| [#114](https://github.com/TheYfactora12/home-ai-elite/issues/114) | v3.1: Policy-gated Wizard HQ Settings backend | Engineering | `priority: high` | #31, #32 (memory gates) |
| [#117](https://github.com/TheYfactora12/home-ai-elite/issues/117) | v3.1 settings: provider connector + secret presence-only | Engineering | `priority: medium` | #114 |
| [#95](https://github.com/TheYfactora12/home-ai-elite/issues/95) | Product Push audit — skill-team, installer retest, UX | All roles | `priority: high` | #106 findings |

---

## 🟡 READY — Scoped, Unblocked, Next Up

| # | Issue | Priority | Depends On |
|---|-------|----------|------------|
| [#119](https://github.com/TheYfactora12/home-ai-elite/issues/119) | v3.1 settings: startup and API service controls | `priority: medium` | #114, #116, #37 |
| [#120](https://github.com/TheYfactora12/home-ai-elite/issues/120) | v3.1 settings: memory review and delete controls | `priority: medium` | #31, #32 |
| [#83](https://github.com/TheYfactora12/home-ai-elite/issues/83) | PATENT: Alice §101 hardening — all anchor docstrings | `priority: critical` | None |
| [#82](https://github.com/TheYfactora12/home-ai-elite/issues/82) | PATENT: Negation suppression function — named + tested | `priority: critical` | None |

---

## 🔵 BACKLOG — Sequenced, Not Yet Sprint

| # | Issue | Milestone | Gate Condition |
|---|-------|-----------|----------------|
| [#84](https://github.com/TheYfactora12/home-ai-elite/issues/84) | PATENT: MerlinFlow self-generating workflow engine | `v4.x` | After #83 + #82 complete; inventor legal name in INVENTOR_RECORD |
| [#105](https://github.com/TheYfactora12/home-ai-elite/issues/105) | v3.2: AI Asset Inventory + Identity Graph | `v3.2` | After #106 shell complete |
| [#103](https://github.com/TheYfactora12/home-ai-elite/issues/103) | v3.3: Access Control + Reviews | `v3.3` | After #105 |
| [#104](https://github.com/TheYfactora12/home-ai-elite/issues/104) | v3.4: Monitoring IDS Signals + Drift | `v3.4` | After #103 |
| [#107](https://github.com/TheYfactora12/home-ai-elite/issues/107) | v3.5: DLP + Prevention Gates | `v3.5` | After #104 |
| [#112](https://github.com/TheYfactora12/home-ai-elite/issues/112) | v3.6: Governance Reporting + Evidence | `v3.6` | After #107 |
| [#108](https://github.com/TheYfactora12/home-ai-elite/issues/108) | v3.7: Local Fallback + DR | `v3.7` | After #112 |
| [#92](https://github.com/TheYfactora12/home-ai-elite/issues/92) | v3.x: Native Automation Runtime (n8n supplement) | `v3.x` | After v3.1 control-plane evidence |
| [#111](https://github.com/TheYfactora12/home-ai-elite/issues/111) | v4.x: MerlinFlow Native Runtime | `v4.x` | After v3.x runtime patterns proven |
| [#64](https://github.com/TheYfactora12/home-ai-elite/issues/64) | Developer ID signing / notarization | `v3.0` | After installer + Wizard HQ product-complete |

---

## ✅ DONE THIS SPRINT — Definition of Done Met

| # | Issue | Closed | Evidence |
|---|-------|--------|----------|
| `v1.0–v2.2` | All prior milestones | Closed | See CANONICAL_PROJECT_STATE milestone table |
| `INVENTOR_RECORD.md` | Patent conception date record | 2026-05-07 | `docs/ip/INVENTOR_RECORD.md` committed to main |

---

## Definition of Done (applies to every issue)

1. Acceptance criteria in the issue are all checked.
2. Static tests pass — no unsafe browser execution, no secret values rendered, no direct unsafe POST.
3. Manual test documented (screenshots or notes saved to release evidence path).
4. Rollback path documented in the issue.
5. No behavior changes outside the issue's stated scope.
6. CI green on `main`.
7. `docs/CANONICAL_PROJECT_STATE.md` updated if milestone state changes.

---

## Blocked Issues Log

| Issue | Blocker | Owner | ETA |
|-------|---------|-------|-----|
| #120 (memory delete controls) | Blocked by #31 and #32 | Backend / Memory | After #31+#32 |
| #36 (observability design) | #8 must be scoped to optional-only profile | Scrum | Next grooming |
| #84 (MerlinFlow patent) | Inventor legal name missing in INVENTOR_RECORD.md | Inventor | Immediate |

---

*Last regenerated: 2026-05-08 by Scrum Master (AI). Verify against GitHub issue state before acting.*
