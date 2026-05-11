# Patent Claim 3 — Air-Gapped AI OS with Profile-Based Capability Isolation
**Merlin AI / Merlin Platform | TheYfactora12 | Priority Date Target: File within 30 days of 2026-05-06**
**Classification: CONFIDENTIAL — Attorney-Client Privileged upon engagement**

---

## Invention Title

**System and Method for Structurally-Enforced Network Egress Prevention with Named Capability Profile Isolation in a Locally-Deployed Artificial Intelligence Operating System**

---

## The One-Sentence Invention

A locally-deployed AI operating system that enforces network egress prevention at the service orchestration layer — not at the firewall or network layer — by activating only named capability profile subsets architecturally incapable of making external network calls, while providing explicit per-profile opt-in mechanisms for controlled, audited external connectivity.

---

## Critical Distinction from Existing Air-Gap Products

Existing air-gap = firewall rules, network segmentation, physical isolation. These are infrastructure-layer solutions outside the software.

This invention = the software itself contains no code paths that attempt external calls in default mode. The air-gap is structural to the application — works even on a machine with full network connectivity at the OS level.

---

## Core Components

**Component 1: Service Profile Manifest**
Declarative manifest defining named profiles with egress classes:
- `egress_class: none` — no external calls permitted (core profile)
- `egress_class: controlled` — explicit opt-in required (search, automation)
- `egress_class: explicit` — per-session approval (cloud-assist)

**Component 2: Profile Activation Controller**
Only profile-included services are started. Non-included services cannot make network calls because they are not running. Structural isolation, not firewall isolation.

**Component 3: Egress Enforcement Monitor**
Intercepts service-layer API calls that would result in external requests. Checks against permitted_endpoints list. Blocks + logs unauthorized attempts.

**Component 4: Controlled Egress Opt-In Flow**
For profiles with external connectivity: presents what services activate, what endpoints they contact, what data categories may transmit. Requires explicit approval before activation.

**Component 5: Egress Audit Trail**
Append-only local log of all external network calls — permitted or blocked:
```
2026-05-06T23:00:00Z | PERMITTED | api.openai.com | cloud-assist | session:abc
2026-05-06T23:01:00Z | BLOCKED   | telemetry.vendor.com | core | service:litellm
```
This log is the compliance artifact for regulators.

---

## Stress Test — Prior Art Attacks

| Attack | Verdict |
|---|---|
| "Firewalls already do egress control" | Survives — network layer vs. application/orchestration layer |
| "Docker network isolation does the same" | **Weakest attack** — attorney must distinguish on consent flow, audit trail, named profile system |
| "Pi-hole does DNS egress control" | Survives — DNS vs. application layer, no profile system |
| "LocalAI/Ollama don't make cloud calls" | Survives — no profile system, no consent flow, no audit trail |

**Recommendation: Do not file this claim alone. File with Claims 1 and 2.**

---

## Claim Strength: 6/10 — File Combined with Claims 1 and 2.

---

## Compliance Sales Value

> "In core profile, no service in the stack has code that makes external network calls. The architecture is the proof. Every external communication attempt — permitted or blocked — is logged in a local audit file you can give to your examiner."

---

*Confidential invention disclosure. Attorney-client privileged upon attorney engagement.*
*Prepared: 2026-05-06 | TheYfactora12/Secure-Local--AI-Merlin*
