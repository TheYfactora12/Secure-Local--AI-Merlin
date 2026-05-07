# Patent Claim 1 — Hardware-Tier-Aware AI Policy Router
**Wizard AI / Merlin Platform | TheYfactora12 | Priority Date Target: File within 30 days of 2026-05-06**
**Classification: CONFIDENTIAL — Attorney-Client Privileged upon engagement**

---

## Invention Title

**System and Method for Hardware-Tier-Aware Capability Profile Selection and Policy-Enforced AI Task Routing in a Locally-Deployed Artificial Intelligence Operating System**

---

## The One-Sentence Invention

A locally-deployed AI system that automatically detects available hardware resources at installation time, selects a capability profile matched to those resources, and enforces policy-gated routing decisions — including approval gate activation, staff mode assignment, and model alias selection — as a unified pipeline that operates entirely without cloud connectivity.

---

## The Problem Being Solved

Existing AI systems treat hardware as a simple constraint on model size selection. No existing system:
- Detects hardware resources and maps them to a structured capability profile tier
- Enforces policy decisions (approval gates, staff mode, agent activation) based on the detected hardware tier
- Treats hardware tier as a first-class policy variable in AI task routing
- Does this entirely locally, with no cloud dependency

---

## Core Components

**Component 1: Hardware Resource Detector**
At installation and at each system start, measures: available RAM, CPU architecture, storage, GPU/Neural Engine availability.

**Component 2: Tier Classification Engine**

| Tier | RAM Range | Capability Class |
|---|---|---|
| `base` | 8–15 GB | Core models only, no heavy agents |
| `mid` | 16–31 GB | Full model set, search profile available |
| `high` | 32+ GB | Full stack, all profiles, coding agents |

**Component 3: Profile Activation Controller**
Based on detected tier, named capability profiles are activated or suppressed:

| Profile | `base` | `mid` | `high` |
|---|---|---|---|
| `core` | ✅ | ✅ | ✅ |
| `search` | ❌ | ✅ | ✅ |
| `automation` | ❌ | ✅ | ✅ |
| `coding` | ❌ | ❌ | ✅ |
| `security` | ❌ | ✅ | ✅ |

**Component 4: Policy-Enforced Task Router**
Evaluates: task content → staff mode → model alias → hardware tier check → approval gate requirement → produces immutable RouteDecision artifact.

**Component 5: Approval Gate Enforcer**
If RouteDecision specifies `approval_required: true`, execution is suspended until explicit user approval.

**Component 6: Audit Trail Writer**
Every RouteDecision, approval event, and execution outcome written to local append-only audit log.

---

## Stress Test — Prior Art Attacks

| Attack | Verdict |
|---|---|
| "Ollama already selects models based on hardware" | Survives — model selection ≠ policy-enforced routing pipeline |
| "LiteLLM already does model routing" | Survives — static YAML config ≠ hardware-tier policy engine |
| "AnythingLLM does local AI with profiles" | Survives — workspace isolation ≠ hardware-tier capability profiles |
| "This is just an installer script" | Survives — invention is the runtime system, not the installer |
| "AWS/Azure do resource-aware AI deployment" | Survives — cloud server-side ≠ client-side hardware-local pipeline |

**Weakest attack:** Gaming engine LOD systems and mobile adaptive quality have some prior art in hardware → capability mapping. Attorney must distinguish on policy enforcement and approval gate components.

---

## Claim Strength: 7.5/10 — Your Strongest Claim. File First.

---

## USPTO Provisional Filing Steps

1. Go to https://www.uspto.gov/patents/basics/apply/provisional-application
2. Create USPTO account
3. File: "Provisional Application for Patent"
4. Fee: $320 micro-entity
5. Title: Use invention title above verbatim
6. Specification: Attach this document
7. You receive: Application number + "Patent Pending" status (12 months)

---

*Confidential invention disclosure. Attorney-client privileged upon attorney engagement.*
*Prepared: 2026-05-06 | TheYfactora12/home-ai-elite*
