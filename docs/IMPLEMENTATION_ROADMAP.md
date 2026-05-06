# Implementation Roadmap

Last updated: 2026-05-06

## Strategy

Ship Merlin as a useful local-first product before expanding into supervised execution. The installer remains protected. The first implementation slices should be docs/config/health/CLI/dashboard layers, not broad service rewrites.

## GitHub Milestone Ladder

Current GitHub milestone sequence:

| Milestone | Purpose | Current rule |
|---|---|---|
| `v1.0 — Stable Installer Release` | Fresh install, package, backup/restore, upgrade, uninstall | Must finish before new runtime feature work |
| `v1.1 — Mobile Access + Remote-Safe Entry Points` | Optional mobile/local-network entry point design | Opt-in only; no default LAN exposure |
| `v1.2 — Hardware Guide + Document Ingestion Planning` | 8GB-first hardware guide and optional ingestion plan | Docs/planning before heavy dependencies |
| `v1.3 — Reliability + Memory + Router` | Retry logic, memory reliability, router cleanup | Local-first and approval-gated |
| `v1.5 — Memory Benchmarking` | Memory quality evaluation | After memory behavior is stable |
| `v1.6 — Pi Intelligence + Observability` | Warmth/persona and local observability | No heavy default tracing dependency |
| `v1.7 — Security Hardening` | SAST, red team, policy enforcement | Security gates stay fail-closed |
| `v2.0 — Merlin Staff Core` | Python Merlin core and policy surfaces | No cloud default, no autonomous execution |
| `v2.1 — Dashboard Command Center` | Read-only/user-facing control center | No privileged mutation in dashboard v1 |
| `v2.2 — Magic Mode` | Supervised orchestration | Plan-first, approval-gated |
| `v3.0 — Public Product Release` | Public packaging/onboarding polish | Only after stable lower milestones |

Stress-test result: keep this ladder explicit. Do not jump from `v1.0` to `v1.3`; `v1.1` and `v1.2` are now real GitHub milestones.

## Milestone 0: Protect Installer And Document Baseline

Goal: Make the current working baseline explicit.

Fresh Mac installer validation:

- First fresh 8GB Mac core install completed on 2026-05-06 and produced issues #41 through #46.
- Follow-up fixes landed for uninstall sudo behavior, Open WebUI local-first startup, Merlin API startup policy, CLI fallback messaging, and low-tier model recommendations.
- A second full fresh uninstall/install rerun is green after #48.
- Unsigned `.pkg` install validation is green after #49.
- Backup/restore, upgrade, launchd persistence, and signing/notarization readiness remain before marking v1.0 stable installer complete.

Tasks:

- Maintain baseline installer review.
- Maintain do-not-break list.
- Keep `install.sh` and `docker-compose.yml` protected.
- Ensure CI catches config root drift and secret leaks.

Acceptance:

- Baseline docs exist.
- CI remains green.
- No application behavior changed.

## Milestone 1: Health Checks And Hardware Detection

Goal: Make laptop safety obvious.

Tasks:

- Keep `wizard doctor` current.
- Show RAM tier and low-memory warnings.
- Validate required local ports and status endpoints.
- Warn before heavy optional profiles.

Acceptance:

- 8GB machines report low tier.
- Closed optional ports warn, not fail.
- No cloud keys required.

## Milestone 2: Merlin Config Foundation

Goal: Keep config explicit, validated, and local-first.

Tasks:

- Keep `configs/merlin/` as canonical runtime config.
- Use example JSON only as future contract material.
- Validate YAML with existing config loader.
- Keep policy fail-closed.

Acceptance:

- Config validation passes.
- Root legacy config directory is not created.
- Safe defaults documented.

## Milestone 3: Provider Registry Skeleton

Goal: Track local and optional cloud providers without enabling cloud.

Status: implemented as a read-only registry and `/status/providers` endpoint.

Tasks:

- Maintain provider states in `merlin/provider_registry.py`.
- Identify configured local providers from Merlin and LiteLLM config.
- Show external provider disabled/present-key state without values.
- Keep provider status read-only: no provider calls, no cloud enablement, no `.env` value exposure.

Acceptance:

- Local providers visible.
- External providers disabled by default.
- No cloud calls in tests.
- `/status/providers` reports local-first mode and redacts all key values.

## Milestone 4: Model Router Skeleton

Goal: Make route/model choice visible and safe.

Tasks:

- Keep route decisions based on existing `configs/merlin/routes.yaml`.
- Display route ID, model alias, staff mode, and approval gates.
- Avoid heavy model aliases on low-memory tier.

Acceptance:

- All route IDs classify.
- Risky routes block.
- Raw input is hashed only.

## Milestone 5: Dashboard Status Cards

Goal: Make Merlin understandable to non-technical users.

Tasks:

- Add read-only Merlin v1 panel.
- Show local-only mode, hardware tier, service health, approvals, memory health, traces.
- Keep advanced controls hidden.

Acceptance:

- Dashboard loads even when Merlin task API is down.
- No secrets displayed.
- No privileged mutation controls in v1.

## Milestone 6: Memory Approval Layer

Goal: Make learning explicit and reversible.

Tasks:

- Pending approval before write.
- Approved Qdrant write only.
- Delete/revoke support.
- Redacted audit records.

Acceptance:

- Normal chat writes no memory.
- `memory_write` gate enforced.
- Dimension guard remains.

## Milestone 7: Magic Mode Planning

Goal: Plan supervised workflows without executing them.

Tasks:

- Plan steps.
- Show route/staff mode/tool needs.
- Show approvals.
- Save redacted audit log.

Acceptance:

- No shell/file/git/n8n/OpenHands execution.
- Stop/pause semantics documented.
- Plan is understandable.

## Milestone 8: Security Gates And Audit Logging

Goal: Make risky behavior impossible to miss.

Tasks:

- All high-risk actions require gates.
- Audit route, policy, approval, memory, and action events.
- Redact secrets and raw input.

Acceptance:

- Policy tests pass.
- Secret scans pass.
- Dashboard/report output redacted.

## Milestone 9: Supervised Execution

Goal: Introduce narrow approved execution after v1 trust exists.

Tasks:

- Add one adapter at a time.
- Start with read-only or low-risk actions.
- Require explicit approvals and rollback instructions.

Acceptance:

- Execution is scoped.
- User can stop/pause.
- Every action logged.

## Milestone 10: Product Polish And Packaging

Goal: Make Home AI Elite installable, understandable, recoverable.

Tasks:

- Improve README and onboarding.
- Package/release validation.
- Upgrade/rollback documentation.
- Low-memory validation.

Acceptance:

- Clean install, upgrade, backup, restore, uninstall tested.
- User can understand what Merlin does.

## First Implementation Slice

Current next implementation slice:

**Run backup/restore verification against the package-installed stack.**

Reason: the fresh install and unsigned package paths are now green after #48 and #49. v1.0 cannot be treated as stable until restore safety is proven against live Qdrant data and the package-installed runtime.

Previous recommended first PR:

**Add `wizard merlin ask` as a thin local wrapper.**

Status: completed. It does not break the installer, works on 8GB Macs, requires no cloud APIs, introduces no autonomous agents, is testable in one PR, and rolls back cleanly.
