# docs/ — Home AI Elite Documentation

> **Product team navigation index.** Read this first. Every file in this folder has a purpose — find it here.
> Last updated: 2026-05-06

---

## What To Read First

| If you are... | Start here |
|---|---|
| New contributor or onboarding | [`ARCHITECTURE.md`](./ARCHITECTURE.md) → [`MASTER_CONTEXT.md`](./MASTER_CONTEXT.md) |
| Starting a Codex session | [`MASTER_CONTEXT.md`](./MASTER_CONTEXT.md) → [`CODEX_MASTER_PROMPT.md`](./engineering/CODEX_MASTER_PROMPT.md) |
| Working on the current sprint | [`MERLIN_IMPLEMENTATION_ROADMAP.md`](./MERLIN_IMPLEMENTATION_ROADMAP.md) → [`MERLIN_STAFF_CORE.md`](./architecture/MERLIN_STAFF_CORE.md) |
| Making a product decision | [`product/HOME_AI_ELITE_PRODUCT_PLAN.md`](./product/HOME_AI_ELITE_PRODUCT_PLAN.md) → [`product/MERLIN_V1_MVP.md`](./product/MERLIN_V1_MVP.md) |
| Reviewing security posture | [`security/SECURITY_MODEL.md`](./security/SECURITY_MODEL.md) → [`security/SECURITY_REVIEW.md`](./security/SECURITY_REVIEW.md) |
| Debugging a failure | [`operations/FAILURE_MAP.md`](./operations/FAILURE_MAP.md) → [`operations/DO_NOT_BREAK.md`](./operations/DO_NOT_BREAK.md) |

---

## Folder Structure

### 📄 Root — Always-Open Docs (read frequently)
| File | Purpose |
|---|---|
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Canonical system architecture — single source of truth |
| [`MASTER_CONTEXT.md`](./MASTER_CONTEXT.md) | Full project context for Codex and team orientation |
| [`MASTER_PROMPT.md`](./MASTER_PROMPT.md) | Active Codex agent config and rules |
| [`MERLIN_IMPLEMENTATION_ROADMAP.md`](./MERLIN_IMPLEMENTATION_ROADMAP.md) | Active v1→v2 build roadmap — updated each sprint |
| [`MERLIN_PHASE3_LEARNING_PLAN.md`](./MERLIN_PHASE3_LEARNING_PLAN.md) | Phase 3 review-first learning contracts and build order |

### 📁 product/ — What we are building and why
| File | Purpose |
|---|---|
| [`HOME_AI_ELITE_PRODUCT_PLAN.md`](./product/HOME_AI_ELITE_PRODUCT_PLAN.md) | Top-level product plan and vision |
| [`MERLIN_V1_MVP.md`](./product/MERLIN_V1_MVP.md) | v1 MVP scope, constraints, and acceptance criteria |
| [`DASHBOARD_PRODUCT_SPEC.md`](./product/DASHBOARD_PRODUCT_SPEC.md) | Dashboard product requirements |
| [`DASHBOARD_UI_SPEC.md`](./product/DASHBOARD_UI_SPEC.md) | Dashboard UI and interaction spec |

### 📁 architecture/ — How Merlin is designed
| File | Purpose |
|---|---|
| [`ARCHITECTURE_CHALLENGE.md`](./architecture/ARCHITECTURE_CHALLENGE.md) | Architecture decisions, gap analysis, v2/v3 direction (canonical merge) |
| [`MERLIN_BRAIN_SPEC.md`](./architecture/MERLIN_BRAIN_SPEC.md) | Merlin brain — memory, routing, policy, and cognition spec |
| [`MERLIN_CONFIG_SPEC.md`](./architecture/MERLIN_CONFIG_SPEC.md) | Config file schema and canonical config tree |
| [`MERLIN_STAFF_CORE.md`](./architecture/MERLIN_STAFF_CORE.md) | Staff mode system — 6 roles, routing profiles, swarm integration |
| [`MERLIN_ARCHITECTURE_SPEC.md`](./architecture/MERLIN_ARCHITECTURE_SPEC.md) | Merlin architecture component spec |
| [`SWARM.md`](./architecture/SWARM.md) | Swarm coordinator design and agent coordination |
| [`MAC_HARDWARE_TIERS.md`](./architecture/MAC_HARDWARE_TIERS.md) | Hardware tier definitions and model limits per RAM tier |

### 📁 engineering/ — How we build and operate Codex
| File | Purpose |
|---|---|
| [`CODEX_MASTER_PROMPT.md`](./engineering/CODEX_MASTER_PROMPT.md) | Master Codex prompt — rules, constraints, session behavior |
| [`CODEX_START_NEXT_STEP_PROTOCOL.md`](./engineering/CODEX_START_NEXT_STEP_PROTOCOL.md) | Protocol for starting Codex sessions and handoffs |
| [`TEST_STRATEGY.md`](./engineering/TEST_STRATEGY.md) | Test coverage strategy, CI gates, and test types |
| [`CONTAINER_IMAGE_POLICY.md`](./engineering/CONTAINER_IMAGE_POLICY.md) | Container image selection and update policy |
| [`MODEL_OPERATIONS.md`](./engineering/MODEL_OPERATIONS.md) | Model pull, lifecycle, and operations runbook |

### 📁 security/ — Security and privacy posture
| File | Purpose |
|---|---|
| [`SECURITY_MODEL.md`](./security/SECURITY_MODEL.md) | Security model — threat surface, controls, and local-first principles |
| [`SECURITY_REVIEW.md`](./security/SECURITY_REVIEW.md) | Structured security review findings and recommendations |
| [`AGENT_PERMISSION_MODEL.md`](./security/AGENT_PERMISSION_MODEL.md) | Agent permission gates and approval model |
| [`PRIVACY_AND_MEMORY_MODEL.md`](./security/PRIVACY_AND_MEMORY_MODEL.md) | Privacy policy, memory consent, and data handling |

### 📁 operations/ — Running and recovering the system
| File | Purpose |
|---|---|
| [`FAILURE_MAP.md`](./operations/FAILURE_MAP.md) | Known failure modes, root causes, and recovery steps |
| [`DO_NOT_BREAK.md`](./operations/DO_NOT_BREAK.md) | Invariants — things that must never be changed without review |
| [`FIRMWARE_FIXES.md`](./operations/FIRMWARE_FIXES.md) | Firmware and OS-level fixes and known issues |
| [`INSTALLER_NOTES.md`](./operations/INSTALLER_NOTES.md) | Installer behavior notes and edge cases |

### 📁 archive/ — Historical / point-in-time snapshots
| File | Status |
|---|---|
| [`ARCHITECTURE_CURRENT.md`](./archive/ARCHITECTURE_CURRENT.md) | Archived 2026-05-06 — superseded by `ARCHITECTURE.md` |
| [`FRESH_INSTALL_MAC_TEST_2026-05-06.md`](./archive/FRESH_INSTALL_MAC_TEST_2026-05-06.md) | v1.0 fresh install test log |
| [`ROADMAP_STRESS_TEST_2026-05-06.md`](./archive/ROADMAP_STRESS_TEST_2026-05-06.md) | v1.0 roadmap stress test session output |
| [`CODEX_BASELINE_REVIEW.md`](./archive/CODEX_BASELINE_REVIEW.md) | Pre-v1.0 Codex baseline review snapshot |
| [`BASELINE_INSTALLER_REVIEW.md`](./archive/BASELINE_INSTALLER_REVIEW.md) | Pre-v1.0 installer review snapshot |

---

## Release Status

| Milestone | Status |
|---|---|
| **v1.0 — Stable Installer Release** | 🔵 In Progress — fresh install, unsigned package, backup/restore, core upgrade, launchd, clean reinstall, and package builder fixes verified; self-signed `.pkg` install still needs System trust or Developer ID |
| **v2.0 — Merlin Staff Core** | 🔵 In Progress — Phase 2 core implemented; #53 and #60 remain open |

See [GitHub Milestones](https://github.com/TheYfactora12/home-ai-elite/milestones) and [CHANGELOG.md](../CHANGELOG.md) for full release history.
