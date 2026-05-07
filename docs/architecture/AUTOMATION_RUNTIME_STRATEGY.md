# Automation Runtime Strategy

Home AI Elite uses n8n today because it is mature, self-hostable, and useful
immediately. That does not mean n8n is the long-term commercial runtime.

## Current Position

n8n remains an optional automation surface:

- It is useful for webhook workflows, schedules, and integrations.
- It is not the Merlin brain.
- It should not be required for 8GB low-tier installs.
- Imported workflows must stay inactive or explicitly activated.
- Workflow execution remains approval-gated when it can affect files, network,
  secrets, services, memory, or external systems.

This keeps v1.6 pragmatic while avoiding a rebuild before the product proves the
right workflow shape.

## Why We May Need Our Own Runtime

A commercial Home AI Elite product may eventually need a native automation
runtime because:

- n8n is a separate product with its own licensing, UI, concepts, and upgrade
  cadence.
- Non-technical users need simpler plan, approve, run, pause, and rollback
  flows than a generic workflow builder provides.
- Merlin needs first-class policy gates, local-only telemetry, memory approval,
  and audit trails built into every node.
- 8GB Macs need a lighter runtime than a full automation stack plus database.
- Commercial packaging is cleaner when core automation does not depend on a
  third-party workflow product.

## Build Our Own Automation Runtime

The better long-term shape is a small Merlin-native workflow runner, not a full
n8n clone.

MVP capabilities:

- Declarative workflow spec: YAML or JSON.
- Node types: prompt, local HTTP, webhook receive, schedule, transform, approval,
  memory read, memory write, shell-request, file-request.
- Policy gates before every risky node.
- Plan-first execution: dry-run graph, required approvals, estimated services.
- Local JSONL trace sink by default.
- Optional local Langfuse export only when the observability profile is active.
- Pause, resume, cancel, retry, and rollback markers.
- Strict redaction before logs or trace UI export.

Do not build:

- A general-purpose visual workflow IDE in v1.
- A marketplace.
- Cloud trigger hosting.
- Multi-tenant enterprise RBAC.
- Arbitrary plugin execution without policy gates.
- Autonomous browser or shell control.

## Better Than n8n For Merlin

The native runtime should improve on n8n in areas that matter to this product:

| Need | n8n today | Merlin-native target |
| --- | --- | --- |
| User safety | Workflow-specific | Policy gates at runtime core |
| 8GB Macs | Heavy optional stack | Lightweight local runner |
| Approvals | Manual pattern | First-class node type |
| Memory | External workflow logic | Built-in approved memory nodes |
| Observability | Optional profile | JSONL baseline, optional trace UI |
| Product UX | Generic workflow UI | Wizard-themed plan/approve/run UI |
| Commercial packaging | Third-party product | Owned core runtime |

## Migration Path

1. Keep n8n optional and useful.
2. Continue writing static workflow tests so current workflows are safe.
3. Extract repeated workflow concepts into docs and schemas.
4. Build a tiny local runner for one internal workflow.
5. Add dashboard controls for plan, approve, run, and inspect.
6. Keep an n8n adapter for users who already depend on n8n.
7. Promote the native runtime only after it can replace one real workflow with
   less complexity and equal safety.

## Last-mile milestone

Create a final commercial-readiness milestone after the current local-first
runtime is working:

**v3.x — Native Automation Runtime**

Goal: supplement or replace n8n for core Merlin workflows with a lightweight,
policy-gated, local-first workflow runner that ships as part of Home AI Elite.

This milestone should not start until:

- v1.6 observability is stable,
- Magic Mode has plan-first approval flows,
- dashboard approvals are usable by non-technical users,
- n8n workflow usage has shown which patterns are worth owning,
- 8GB low-tier performance has been measured.

Until then, n8n remains a wrapped optional integration, not something to rebuild
inside v1.6.
