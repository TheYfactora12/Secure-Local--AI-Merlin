# Merlin AI — Scrum & Management Reference

**Last updated:** 2026-05-10
**Scrum cycle:** 2-week sprints, Thursday kick-off
**Current sprint:** v1.0 Focus Reset — five jobs only

> This document governs how the Merlin AI / Merlin project is run. It is
> subordinate only to GitHub issue and milestone state. All planning,
> prioritization, and sequencing decisions trace back to
> `docs/CANONICAL_PROJECT_STATE.md`.

---

## Source of Truth Hierarchy

1. GitHub milestones and open issues (always current)
2. Recent commits and CI status
3. `docs/CANONICAL_PROJECT_STATE.md` (tie-breaker)
4. `docs/MASTER_CONTEXT.md` and `docs/MASTER_PROMPT.md`
5. `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
6. Topic docs under `docs/architecture/`, `docs/security/`, `docs/product/`, `docs/ip/`
7. `docs/archive/` (historical evidence only — do not update)

When a lower source conflicts with a higher source, update the lower source or open a GitHub issue.

---

## Milestone Ladder (Current State)

| Milestone | Status | Sprint Position |
|-----------|--------|-----------------|
| `v1.0 — Stable Installer Release` | ✅ Closed | — |
| `v1.1 — Mobile Access / Remote-Safe Entry` | ✅ Closed | — |
| `v1.2 — Hardware Guide + Doc Ingestion` | ✅ Closed | — |
| `v1.3 — Reliability + Memory + Router` | ✅ Closed | — |
| `v1.5 — Memory Benchmarking` | ✅ Closed | — |
| `v1.6 — Pi Intelligence + Observability` | ✅ Complete | — |
| `v1.7 — Security Hardening` | ✅ Closed | — |
| `v2.0 — Merlin Staff Core` | ✅ Mostly complete | #31, #32 memory follow-ups remain |
| `v2.1 — Dashboard Command Center` | ✅ Closed | — |
| `v2.2 — Magic Mode` | ✅ Closed | — |
| `v3.0 — Local Trusted Beta Hardening` | 🔄 Active | #37, #95 |
| `v3.1 — Wizard HQ Product Shell` | ⚠️ Conditional | Only onboarding/first-action work that supports v1.0 |
| Future product backlog | 🔮 Future | See `docs/product/FUTURE_IDEAS.md` |
| Future engineering/IP backlog | 🔮 Future | See `docs/product/FUTURE_IDEAS.md` |

---

## Active Execution Queue (Priority Order)

> Pull from top. Do not skip ahead.

1. **#37** — onboarding and packaging hardening.
2. **#95** — product audit, release evidence, and installer retest discipline.
3. **#134** — product value checkpoint, now judged by the five v1.0 jobs.
4. **#123/#106** — only where they improve first local question, Wizard HQ
   onboarding, privacy proof, or recovery clarity.
5. **#64 and all other feature issues** — deferred until the five jobs are
   evidenced.

---

## Do-Not-Build-Yet List

These are explicitly deferred. Do not implement until v1.0 proves the five jobs.

- Browser-side shell execution or privileged browser commands
- Automatic cloud routing or cloud-by-default behavior
- Silent model downloads
- Autonomous execution without approval gate
- Heavy default services (OpenHands, large model pre-pulls)
- MerlinFlow/native automation runtime
- Deep Rooms, export/import, voice, Home Assistant, Linux, and provider setup
- Professional/compliance claims before implemented controls are evidenced

---

## Cross-Cutting Guardrails (Always In Force)

These apply to every issue, every PR, every sprint:

| Guardrail | Rule |
|-----------|------|
| **8GB floor** | Every feature must be functional on an 8GB Mac low/core install |
| **Local-first default** | No cloud calls, no external telemetry, no model downloads without explicit user action |
| **Approval gates** | Every write to secrets, memory, workflows, or policy must route through `policy_engine.py` |
| **Secret presence-only** | API keys and tokens are never returned to Wizard HQ after submission |
| **Fail-closed** | Approval gates fail closed — denied by default, not allowed by default |
| **No browser shell** | Dashboard cannot execute shell commands directly — ever |
| **8765 read-only** | Status API port 8765 remains read-only; execution routes through 8766 only |
| **Audit trail** | Every policy gate event writes an audit log without raw prompts or secret content |
| **CI green on main** | No issue is done until CI passes |

---

## Sprint Ceremony Schedule

| Ceremony | Cadence | Owner | Input |
|----------|---------|-------|-------|
| Sprint Planning | Thursday (start of sprint) | Scrum Master | CANONICAL_PROJECT_STATE + open issues |
| Daily Standup | Daily async | All | SPRINT_BOARD.md blocked items |
| Sprint Review | Wednesday (end of sprint) | Product Owner | Acceptance criteria check per issue |
| Sprint Retrospective | Wednesday (end of sprint) | All | What slipped, why, what changes |
| Backlog Grooming | Bi-weekly (mid-sprint Wednesday) | Scrum Master + PM | Unscoped issues, dependency check |
| Patent/IP Review | Monthly or on new issue | Inventor + IP Lead | docs/ip/INVENTOR_RECORD.md + issue state |

---

## Skill Team Roles (from #95)

| Role | Current Sprint Focus |
|------|---------------------|
| Scrum Master / Delivery Lead | Sprint board hygiene, blocked issue resolution |
| Product CEO / Strategy | v3.1 scope lock, do-not-build-yet enforcement |
| Product Manager | Acceptance criteria review per issue |
| UX Director | Wizard HQ shell design, honest readiness states |
| UI Designer | Loading states, Settings tab visual spec |
| Frontend Engineer | Dashboard, Settings flows, Brains tab |
| Backend / Merlin Core | Policy gates, Settings backend, task API |
| Security / Privacy Architect | 8765/8766 boundary, secret presence-only, fail-closed |
| QA Automation | CI static tests, no unsafe POST, no secret render |
| Manual QA / UAT | Clean install, screenshots, Settings manual test |
| Installer / macOS Release | v3.0 packaging, launchd, uninstall/reinstall test |
| Documentation / Governance | CANONICAL_PROJECT_STATE, INVENTOR_RECORD, evidence packs |
| IP / Patent Lead | #83, #82, INVENTOR_RECORD legal name, filing strategy |

---

## Patent / IP Immediate Actions

| Action | Status | Owner | Risk If Skipped |
|--------|--------|-------|-----------------|
| Fill legal name in `docs/ip/INVENTOR_RECORD.md` | ⚠️ OPEN | Inventor | Record unfileable without it |
| Complete #83 (Alice §101 docstrings) | ⚠️ OPEN | Backend / IP | ~40% USPTO rejection rate on software claims |
| Complete #82 (negation suppression function) | ⚠️ OPEN | Backend | Claim 3 cannot be filed without named implementation |
| Decide Provisional B vs CIP for MerlinFlow (#84) | ⚠️ OPEN | Inventor + IP | MerlinFlow conception locked 2026-05-07; clock running |

---

## Escalation Rules

1. **Blocked > 2 days** → Scrum Master opens a comment on the blocking issue with date and impact.
2. **Scope creep detected** → Stop, open a new issue, return to active queue.
3. **Security guardrail at risk** → Immediately escalate to Security/Privacy Architect; do not merge.
4. **Patent-sensitive code change** → Inventor reviews before merge; IP lead notified.
5. **Canonical doc conflicts with GitHub issue** → GitHub issue wins; update the doc.

---

*Governed by: `docs/CANONICAL_PROJECT_STATE.md` · Sprint board: `docs/scrum/SPRINT_BOARD.md`*
