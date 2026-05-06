# Dashboard UI Spec

Last updated: 2026-05-06

## Design Direction

The dashboard should feel like a clean local AI command center for normal users. It should be dark-mode first, status-driven, and calm. Advanced controls should live behind an Advanced or Developer section.

## Global Requirements

- Show Merlin status.
- Show local-only mode.
- Show hardware tier.
- Show active model.
- Show memory status.
- Show Magic Mode status.
- Show agent permissions.
- Show external provider status.
- Show whether cloud/API calls are enabled.
- Show logs and approvals.
- Allow memory review/delete only after approval model exists.
- Allow API key management without exposing values.
- Show RAM warnings before model/profile changes.
- Keep service start/stop safe, explicit, and non-default.

## Screens

### 1. Home

- Purpose: One glance system summary.
- Actions: Open Merlin chat, run doctor command, view alerts.
- Data: 8765 status, 8766 status panels, hardware tier, profile, service health.
- Indicators: green/yellow/red health, local-only badge, degraded mode.
- Warnings: public bind, missing secrets, low RAM, stopped model gateway.
- Empty: "Merlin core not started."
- Error: "Status API unavailable."
- MVP: Read-only cards.
- Future: Guided repair actions.

### 2. Merlin Chat

- Purpose: Product-visible Merlin interaction.
- Actions: Ask local question, view route and approval gates.
- Data: Task endpoint response, route metadata.
- Indicators: model alias, route ID, approval state.
- Warnings: approval required, local model unavailable.
- Empty: First prompt suggestions.
- Error: LiteLLM unavailable degraded message.
- MVP: Can show CLI-equivalent ask flow.
- Future: Thread history and memory opt-in.

### 3. Magic Mode

- Purpose: Supervised planning.
- Actions: Enter goal, generate plan, pause/stop planning.
- Data: route rules, policy gates, approval requirements.
- Indicators: plan-only badge, blocked steps.
- Warnings: no execution in v1.
- Empty: "Describe a goal to plan."
- Error: route/policy unavailable.
- MVP: Plan-only.
- Future: Step-by-step approved execution.

### 4. Models

- Purpose: Explain local model state.
- Actions: View installed/loaded models, copy pull command.
- Data: Ollama tags/ps, LiteLLM models, hardware tier.
- Indicators: active model, RAM warning, disk warning.
- Warnings: large model on 8GB, cloud provider disabled.
- Empty: no models installed.
- Error: Ollama unavailable.
- MVP: Read-only plus safe copy commands.
- Future: guarded model pulls.

### 5. Memory

- Purpose: Let user trust and manage memory.
- Actions: Review, approve, deny, delete memory.
- Data: memory status, collections, approvals, audit IDs.
- Indicators: Qdrant health, collection dimensions, write approval state.
- Warnings: memory writes require approval.
- Empty: no approved memories.
- Error: Qdrant degraded.
- MVP: Status and approval records.
- Future: document memory and retention controls.

### 6. Agents

- Purpose: Show agent capabilities and permission state.
- Actions: View disabled/enabled supervised agents.
- Data: policy gates, profiles, agent config.
- Indicators: supervised-only, disabled, approval required.
- Warnings: OpenHands/Docker socket risk.
- Empty: no agents enabled.
- Error: agent config unavailable.
- MVP: Read-only permissions matrix.
- Future: supervised adapter enablement.

### 7. Security

- Purpose: Trust center.
- Actions: View gates, local-only mode, secret scan state.
- Data: policy.yaml, gitleaks status, env key presence.
- Indicators: cloud disabled, telemetry disabled, secrets redacted.
- Warnings: missing gitleaks hook, public bind.
- Empty: no warnings.
- Error: policy config invalid.
- MVP: Read-only gate list.
- Future: security setting editor with approvals.

### 8. System Health

- Purpose: Operational status.
- Actions: Copy repair commands, run doctor externally.
- Data: service health, ports, disk, RAM, logs counts.
- Indicators: pass/warn/fail.
- Warnings: low disk, closed required port, Docker stopped.
- Empty: no services running.
- Error: status API down.
- MVP: Read-only.
- Future: safe start/stop with confirmations.

### 9. Logs

- Purpose: Audit and troubleshooting.
- Actions: View redacted event summaries, create bug report.
- Data: redacted route traces, policy logs, log error counts.
- Indicators: errors, warnings, recent approvals.
- Warnings: never show raw secrets.
- Empty: no logs.
- Error: logs unavailable.
- MVP: counts and redacted summaries.
- Future: searchable audit UI.

### 10. Settings

- Purpose: User preferences and advanced config visibility.
- Actions: Toggle local-only display preference, manage provider setup flow.
- Data: config, provider registry, dashboard settings.
- Indicators: cloud disabled/enabled, API key present without value.
- Warnings: enabling cloud sends data outside machine.
- Empty: safe defaults active.
- Error: config invalid.
- MVP: Read-only plus links/copy commands.
- Future: guarded config editor.
