# Home AI Elite / Merlin Mythology Brand System

Last updated: 2026-05-10
Status: Product naming and UX architecture

## Purpose

This document defines the Merlin mythology-based product language inside Home AI
Elite. The goal is not to add gimmicky names. The goal is to make a complex
local AI security/control system intuitive, memorable, and aligned to the actual
architecture.

Home AI Elite is the product the user installs. Merlin is the visible assistant
face and internal brain inside it: chat, voice, memory, routing, safety, and
approval-aware action. Merlin protects the user's private AI home, stores
approved context in a user-controlled Vault, governs agents through explicit
approvals, and only allows powerful actions when the user grants scoped
authority.

## Core Brand Thesis

> Home AI Elite is the private AI home. Merlin protects the realm. The Round
> Table governs the Knights. Excalibur represents powerful action. The Vault
> stores what matters. The Chronicle records what happened.

This maps directly to the product architecture:

- local-first brain,
- secure project workspaces,
- user-owned context storage,
- memory review and consent,
- policy-gated actions,
- scoped agents,
- readiness monitoring,
- redacted evidence trails.

## Naming Map

| Myth Name | Product Meaning | Plain-Language Support Text |
| --- | --- | --- |
| Merlin | Visible assistant face and internal AI brain | The assistant you talk to and the intelligence layer that helps reason over your projects. |
| Realm | Protected local AI stack, projects, data, and tools | Your secure AI workspace and environment. |
| Project Realm | A secure project workspace | A project with its own context, memory, files, agents, approvals, and evidence. |
| Round Table | Governance and approvals | Where you approve, deny, revoke, or review agent actions. |
| Knights | Scoped agents | Agents assigned to projects with limited permissions. |
| Excalibur | High-risk execution authority | Powerful actions such as writing files, running commands, using network access, or changing system state. |
| Vault | Memory and context store | Where Merlin stores approved project context and memory. |
| Grimoire | Project knowledge base and rules | The instructions, project notes, and approved working knowledge Merlin uses. |
| Codex | Technical/project documentation and agent operating rules | The structured project record and operating manual. |
| Watchtower | Status, readiness, monitoring, and alerts | Shows what is running, ready, degraded, failed, or blocked. |
| Gatehouse | Policy gates and access control | The approval boundary before risky actions. |
| Chronicle | Redacted activity and evidence logs | The record of what happened without exposing raw secrets or sensitive prompt content. |
| Oath | Agent permission contract | What a Knight is allowed to do, for how long, and inside what boundary. |
| Seal | Approval record | A user decision authorizing or denying a scoped action. |
| Council | Multi-agent review/planning session | Several Knights reviewing or planning together without bypassing permissions. |

## Wizard HQ Information Architecture

Wizard HQ remains the main product surface. The mythology system should be used as an architectural layer, but plain-language labels must remain visible.

Recommended Wizard HQ sections:

1. **Watchtower — Status & Readiness**
   - Overall readiness state.
   - Local/private mode.
   - Active brain/model/provider.
   - Service health.
   - Degraded/failed components.
   - Safe next action.

2. **Project Realms — Secure Projects**
   - Project list.
   - Project storage location.
   - Linked files/folders.
   - Project memory state.
   - Assigned Knights.
   - Recent project activity.

3. **Vault — Memory & Context**
   - Approved memories.
   - Pending memory proposals.
   - Indexed context.
   - Review/delete/export controls.
   - Brain/context storage location.

4. **Round Table — Approvals & Governance**
   - Pending approvals.
   - Approved/denied history.
   - Agent Oaths.
   - Revocation controls.
   - Kill switch.

5. **Knights — Agents & Roles**
   - Agent roster.
   - Mode: Squire, Knight, Champion, Warden, Steward, Scribe, Smith, Scout, Healer, Sentinel.
   - Project assignment.
   - Permission level.
   - Active task.

6. **Gatehouse — Policy & Access**
   - Cloud disabled/enabled status.
   - Network access policy.
   - File write policy.
   - Shell execution policy.
   - API key use policy.
   - Webhook execution policy.

7. **Chronicle — Evidence & Activity**
   - Task history.
   - Model/provider path.
   - Local/cloud indicator.
   - Memory read/write indicator.
   - Approval gates triggered.
   - Redacted trace IDs.

8. **Settings — Configuration**
   - Storage location.
   - Provider connectors.
   - Model library.
   - Startup/API controls.
   - Backup/restore/export.

## Agent / Knight Model

Agents are framed as Knights, but every Knight must map to a real permission model.

| Agent Type | Product Role | Default Permission |
| --- | --- | --- |
| Squire | Suggests or prepares work | No execution. |
| Knight | Performs step-approved actions | One approved action at a time. |
| Champion | Scoped autopilot | Narrow, time-bound, revocable project boundary only. |
| Warden | Monitors health/security | Read-only unless explicitly approved. |
| Steward | Organizes project materials | Project-scoped, file actions approval-gated. |
| Scribe | Writes docs, summaries, records, and memory proposals | No durable memory write without approval. |
| Smith | Build/code/test agent | Project-scoped, shell/file actions approval-gated. |
| Scout | Research/discovery agent | Network-gated. No external access by default. |
| Healer | Repair/diagnostic agent | Suggest/prepare by default; fixes require approval. |
| Sentinel | Guardrail/policy reviewer | Read-only review by default. |

## Excalibur Execution Language

Excalibur represents powerful execution authority. It must never mean unrestricted access.

Use Excalibur only for actions that can materially change state or expose data:

- writing files,
- deleting files,
- running shell commands,
- installing software,
- pushing to GitHub,
- sending messages/emails,
- using credentials or API keys,
- accessing external network,
- controlling apps or browser sessions,
- changing system settings.

Recommended UI language:

> Excalibur is sheathed.
>
> This Knight is requesting permission to unsheathe Excalibur for one scoped action.

Approval language must include:

- action requested,
- project boundary,
- file/folder/tool scope,
- network/cloud use,
- duration,
- rollback or undo note where possible,
- evidence that will be written,
- revoke/kill switch reminder.

## Project Realm Model

A Project Realm is a secure workspace with its own context and controls.

Each Project Realm should include:

- name,
- description,
- storage location,
- linked files/folders,
- Vault/memory status,
- Grimoire/project instructions,
- assigned Knights,
- Oaths/permission contracts,
- Round Table approvals,
- Chronicle evidence,
- backup/export settings,
- risk level.

Use **Project** for plain-language clarity and **Realm** as the branded metaphor.

Example:

```text
Project Realm: Home AI Elite Build
Brain Location: /Users/Kevin/HomeAIElite/Rooms/Home-AI-Elite-Build
Vault: Active
Knights: Scribe, Smith, Sentinel
Round Table: 2 approvals pending
Excalibur: Sheathed
Chronicle: 14 recent events
```

## UX Rules

1. Mythology must clarify, not obscure.
2. Every myth label must have plain-language support text.
3. Excalibur must be reserved for high-risk execution authority.
4. Knights must never imply broad autonomous power by default.
5. Round Table must always imply user governance and revocation.
6. Vault must always imply reviewable, deletable, exportable memory/context.
7. Chronicle must remain redacted and safe by default.
8. Watchtower must never fake readiness.
9. Gatehouse must fail closed.

## Product Pitch Integration

Primary product sentence:

> Home AI Elite gives you a private AI home. Merlin is the assistant face and
> brain that protects it.

Expanded sentence:

> Merlin stores project context in your Vault, governs agents through the Round
> Table, and only unsheathes Excalibur when you approve powerful actions.

Plain-language alternative:

> Home AI Elite is private AI on hardware you own. Merlin remembers approved
> context where you choose, shows what agents can do, and blocks powerful
> actions until you approve them.

## Implementation Guidance

Do not rename core services blindly. Product-facing labels can adopt the mythology system first while internal service names remain stable for compatibility.

Priority order:

1. Product docs and README language.
2. Wizard HQ copy and navigation labels.
3. Project/Realm model design.
4. Vault memory/context UI.
5. Round Table approval UX.
6. Knights agent roster and Oath model.
7. Excalibur high-risk execution language.
8. Chronicle evidence presentation.

## Related Issues

- #37 — Public release onboarding and packaging hardening
- #95 — Product push audit and release readiness
- #106 — Wizard HQ Product Shell
- #114 — Policy-gated Wizard HQ Settings backend
- #122 — Product Focus Cut
- #123 — Offline Local Brain + User-Owned Context Store
- #130 — Brain/context storage location
- #131 — Brand direction: Home AI Elite product, Merlin assistant face and brain
- #132 — Mythology brand architecture
