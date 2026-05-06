# Home AI Elite Product Plan

Last updated: 2026-05-06

## Product Position

Home AI Elite is a local-first AI command center for hardware the user owns.

Merlin is the product brain. The installer delivers the stack, but Merlin is the user-facing intelligence layer that explains, routes, remembers with approval, and plans supervised work.

## Product Principles

- Local-first by default.
- Consent before persistence.
- Consent before external network.
- Consent before computer action.
- Simple enough for non-technical users.
- Scales by hardware tier: 8GB is the entry point; higher tiers unlock heavier profiles intentionally.
- Wrap mature tools instead of rebuilding them.
- Ship small, tested slices.

## Components

| Component | Purpose | MVP Scope | Future Scope | Risk |
| --- | --- | --- | --- | --- |
| Installer/setup layer | Install and start core stack | Protect existing profile-aware installer | Package signing, upgrades, rollback polish | High |
| Merlin Core | Central policy/routing/persona/status layer | CLI/dashboard task/status loop | Rich orchestration runtime | Medium |
| Model Router | Select local model alias by task/profile | Skeleton route decisions and LiteLLM alias use | Cost/privacy/latency/hardware optimization | Medium |
| Provider Registry | Track local and optional cloud providers | Config skeleton, cloud disabled | Provider health, budgets, fallbacks | High |
| Memory Manager | Approved local memory | Explicit approval, Qdrant writes/deletes | Document memory, audits, retention policies | High |
| Agent Controller | Supervise optional agents | Plan-only assignment | Controlled execution adapters | Critical |
| Policy Engine | Approval gates | Enforce 14 gates | Context-aware policy and session approvals | Critical |
| Audit Logger | Redacted records | Route/policy/memory traces | Searchable audit UI | Medium |
| Magic Mode | Supervised orchestration | Plan-only | Step execution after approvals | Critical |
| Dashboard | Local command center | Read-only status cards | Approvals, memory, model management | Medium |
| Security Center | Secrets/policy visibility | Show gates and local-only mode | Key vault integration, checks | High |
| Hardware Tier Engine | Scale defaults by RAM | 8GB-safe profile warnings | Adaptive service/model planner | Medium |

## MVP User Journeys

1. User installs core.
2. User runs doctor.
3. User opens dashboard and sees local-only status.
4. User asks Merlin a question.
5. Merlin routes locally.
6. Risky route shows required approvals.
7. User asks Merlin to remember a preference.
8. Merlin creates approval request before writing memory.
9. User opens Magic Mode and gets a plan, not execution.

## Product Risks

- Overbuilding autonomous behavior before trust exists.
- Making the dashboard too technical.
- Confusing Open WebUI chat, `wizard ask`, swarm, and Merlin task API.
- Low-memory Macs feeling slow or broken.
- Treating 8GB entry support as permission to run the full stack.
- Cloud provider behavior accidentally becoming default.
- Users misunderstanding "learning" as self-training.

## Product Recommendation

Ship Merlin v1 as:

- Local ask path.
- Read-only dashboard status.
- Explicit memory approval.
- Plan-only Magic Mode.
- Strong approval/security messaging.

Defer autonomous execution until users can understand, approve, stop, and audit every action.
