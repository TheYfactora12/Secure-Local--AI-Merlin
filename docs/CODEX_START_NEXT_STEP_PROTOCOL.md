# Codex Start / Next-Step Protocol — Merlin AI OS

> Use this companion protocol with `docs/CODEX_MASTER_PROMPT.md` whenever the repo owner says `start`, `next step`, `continue`, `what now`, `proceed`, or similar.
>
> Purpose: force Codex to re-align to the repo source of truth before planning or changing code.

---

## Non-Negotiable Rule

Before any new work, Codex must re-read and align to:

1. `docs/CODEX_MASTER_PROMPT.md`
2. `docs/MERLIN_IMPLEMENTATION_ROADMAP.md`
3. `docs/failure-map.md`
4. current open GitHub issues
5. current branch status and recent commits

Do not assume the last chat message is current. The repo may have moved.

---

## Start Command Behavior

When the repo owner says `start`, Codex must:

1. Confirm current branch and working tree status.
2. Identify the current phase from `docs/CODEX_MASTER_PROMPT.md` and roadmap docs.
3. Identify the highest-priority open issue or build slice.
4. Validate that the proposed work preserves the working installer.
5. Validate that the proposed work is safe for M1 8GB Macs.
6. Validate that local-only mode remains default.
7. Validate that no cloud/API behavior is introduced by default.
8. Validate that no autonomous agent behavior is introduced without approval gates.
9. List files it expects to touch and why.
10. Ask for approval before editing if the work touches installer, Docker Compose, `.env.example`, security policy, model routing, memory writes, or agent execution.

Expected output:

```text
Alignment check complete.
Current phase: <phase>
Recommended next slice: <one small slice>
Why this slice: <reason>
Files likely touched: <file list>
Risk level: <low/medium/high/critical>
Installer impact: <none/low/etc.>
M1 8GB impact: <safe/needs guardrails/etc.>
Approval needed before edits: <yes/no>
```

---

## Next Step Behavior

When the repo owner says `next step`, Codex must not jump randomly.

It must choose exactly one next action using this priority order:

1. Fix failing CI or broken installer regression.
2. Fix security issue that could expose secrets, enable unsafe execution, or break local-first guarantees.
3. Complete the current open issue already in progress.
4. Complete the next highest-priority roadmap issue.
5. Improve tests for a recently added feature.
6. Improve dashboard visibility only if backend/status contracts already exist.
7. Improve docs only if implementation is already complete or unclear.

Codex must output exactly one recommended implementation slice, not a broad program.

---

## Review / Align / Update Loop

Every session must follow this loop:

```text
1. Review current repo state.
2. Align with CODEX_MASTER_PROMPT.md.
3. Check roadmap and open issues.
4. Pick one small next slice.
5. Identify touched files.
6. Identify risks and rollback.
7. Implement only that slice after approval.
8. Add or update tests.
9. Run focused validation.
10. Summarize changes, tests, and remaining gaps.
```

If Codex cannot inspect something, it must say so clearly and avoid pretending.

---

## Product North Star Alignment

Codex must keep the product direction aligned to:

- **Home AI Elite**: secure local-first AI command center.
- **Merlin**: orchestration, routing, memory, policy, and trust layer.
- **Magic Mode**: supervised planning and execution, not autonomous takeover.
- **Dashboard**: simple command center for normal users, not a developer-only control panel.
- **Installer**: protected golden path, not the product moat.

Codex must not rebuild mature ecosystems unnecessarily.

Prefer:

- adapters over rewrites
- wrappers over forks
- local-first defaults over cloud defaults
- SQLite/simple storage before heavy infrastructure
- plan-only Magic Mode before execution
- supervised agents before autonomous agents
- small PRs before broad refactors

---

## Mandatory Self-Check Before Code

Before writing code, Codex must answer:

1. Does this preserve the working installer?
2. Does this work on or safely degrade for M1 8GB Macs?
3. Does this keep local-only mode as the default?
4. Does this avoid hidden cloud/API calls?
5. Does this require approval for risky actions?
6. Does this avoid hardcoded secrets and secret logging?
7. Does this avoid unnecessary heavy dependencies?
8. Does this add value to Merlin v1 or the current roadmap phase?
9. Is this small enough for one reviewable PR?
10. Can this be rolled back safely?

If the answer is `no` or `unknown`, Codex must stop and document the concern before editing.

---

## Risk Gate Rules

Codex must require explicit approval before touching or enabling:

- `install.sh`
- `docker-compose.yml`
- `.env.example`
- network/cloud provider routing
- model downloads
- shell execution
- file write execution
- browser automation
- memory writes
- security policy
- dashboard exposure beyond localhost
- anything that may send private data externally

Risk labels:

| Risk | Examples | Default |
|---|---|---|
| Low | docs, tests, read-only status, non-invasive health checks | allowed with summary |
| Medium | config additions, dashboard status cards, non-executing route logic | list files first |
| High | shell execution, file writes, external APIs, memory writes | approval required |
| Critical | deleting files, changing security defaults, exposing secrets, background agents | block unless explicitly approved |

---

## Dashboard Alignment Rules

Dashboard work must make the system more understandable and safer.

Priority dashboard cards:

1. Merlin status
2. Local-only mode
3. Hardware tier
4. Active model/provider
5. Memory status and approval mode
6. Magic Mode status
7. Agent permission status
8. External provider status
9. Recent approvals/actions
10. Service health

Dashboard must never expose secrets.

Dashboard must clearly show:

- `Answered by: local/cloud provider`
- `Memory used: yes/no`
- `External API used: yes/no`
- `Risk level: low/medium/high/critical`

---

## Merlin Learning Alignment

When Codex sees `Merlin learns`, interpret that as controlled, auditable learning:

Allowed in v1:

- user-approved memories
- document retrieval
- preference storage
- feedback logs
- memory delete/export
- route decision metadata

Not allowed in v1:

- autonomous self-training
- self-modifying code
- hidden memory
- unsupervised background learning
- external data sharing by default
- permanent memory without approval

---

## Magic Mode Alignment

Magic Mode must start as plan-first.

Allowed in v1:

- goal intake
- plan generation
- step risk labeling
- approval prompts
- pause/stop controls
- action logging
- summary of proposed or approved changes

Not allowed by default:

- automatic shell commands
- automatic file edits
- automatic package installs
- automatic browser actions
- automatic cloud calls
- automatic memory writes

---

## First PR Preference

When uncertain, prefer the safest useful first PR:

```text
hardware detection + doctor command + safe Merlin config example + tests + docs
```

But if the repo already has that, prefer the next documented issue in the roadmap, usually:

1. memory bridge/session wiring,
2. model router workflow,
3. observability/tracing,
4. dashboard status visibility,
5. release hardening.

Do not duplicate completed work.

---

## Final Response Format After Work

Every Codex session must end with:

```text
Summary:
- What changed
- Why it changed
- Files touched
- Tests run
- Installer impact
- M1 8GB impact
- Security impact
- Rollback notes
- Remaining gaps
- Recommended next step
```

---

## Drift Stop Phrases

If Codex starts drifting, the repo owner can say:

```text
Stop. Re-read CODEX_MASTER_PROMPT.md and CODEX_START_NEXT_STEP_PROTOCOL.md. Align to the current roadmap and pick one small slice only.
```

or:

```text
Protect the installer. Local-first. One PR. No broad refactor.
```
