# Dashboard UI Spec — Merlin Command Center

Last updated: 2026-05-07

## Product Direction

The dashboard should feel like a refined Merlin-native command center, not a
container status page. The v2.1 launch surface is **Wizard HQ**: a premium,
read-only local AI operations dashboard that exposes trust signals before it
adds chat execution. Later releases can bring the ChatGPT-style conversation
surface into the center once `/task` execution and approval UX are fully gated.

The theme should be strong wizard, not novelty wizard. Use a dark, premium interface with restrained arcane details: subtle geometric intelligence, luminous focus states, clear typography, green/yellow/red operational states, and a single Merlin identity system. Avoid cartoon assets, oversized decorative cards, and one-note purple/blue gradients.

Reference the brand direction and generated concept assets in
`docs/product/MERLIN_BRAND_UX_SPEC.md`.

## First-Screen Layout

v2.1 MVP layout:

- Center: Merlin AI core, Brain Status, route registry, and recent traces.
- Left rail: System Doctor, Sovereignty Status, and read-only boundary.
- Right rail: Agent Control, approval gates, Memory Vault, Knowledge Graph placeholder, and safe CLI next steps.
- Top bar: Wizard HQ brand, local-only badge, hardware tier, cloud disabled state, and task API state.

The chat experience should be usable even if optional services are down. If LiteLLM or the task API is unavailable, the UI should show a clear startup/degraded message, not a broken dashboard.

For v2.1 specifically, the static dashboard must not submit chat/tasks. Browser
task execution returns in a later issue after policy-gated approval UX is
designed and tested.

## Core Interaction Model

Merlin Chat:

- The composer is the primary action, with large readable text and an obvious send button.
- Responses show the selected staff mode, route confidence, model alias, and whether memory was used.
- Approval-required responses are shown inline with the blocked gate names and a safe next command.
- Raw prompts, secrets, API keys, and model response text are never written to dashboard logs.

Magic Mode:

- v1 is plan-only.
- The UI shows step list, route per step, approval gates, and risk level.
- No execute button appears until the backend has a tested approval-gated executor.
- Stop/pause controls can exist visually only for plan review until execution exists.

Memory:

- Show memory status, collection health, approved preferences, and delete/review controls.
- Memory writes must remain approval-gated.
- User should be able to see "what Merlin remembers" in plain language.

Models:

- Show local installed models, configured aliases, selected model, and fallback reason.
- Low-memory machines show warnings before heavy model/profile actions.
- Model downloads are never automatic from the dashboard.

Security:

- Show local-only status prominently.
- Show all approval gates and current pending/approved/denied counts.
- API key status is present/missing only. Never show values or partial values.
- External provider controls default off and require explicit user action.

## Visual System

Tone:

- Dark mode first.
- Premium, focused, quiet.
- Wizard identity through names, icons, glow accents, and empty states.
- Operational clarity over decoration.

Do:

- Use compact status chips for `local_only`, `low`, `degraded`, `approval_required`.
- Use familiar icons for send, stop, refresh, memory, model, settings, shield, and logs.
- Use green for healthy/local, yellow for warning/degraded, red for blocked/critical.
- Keep cards to individual panels only; do not nest cards.
- Keep typography tight inside tool panels and larger only for primary chat content.

Avoid:

- Cartoon wizard art.
- Decorative gradient orbs or bokeh backgrounds.
- Marketing hero sections.
- UI text explaining keyboard shortcuts or implementation details.
- Any dashboard action that looks executable before backend policy gates exist.

## Screens

### 1. Merlin Chat

Purpose: Main user experience.

MVP:

- Prompt composer.
- Response stream.
- Route/staff/model metadata.
- Degraded state when task API or LiteLLM is down.
- Approval-required state with gate names.

Later:

- Conversation history.
- Memory citations.
- Voice mode.
- Editable system/persona presets behind advanced controls.

### 2. Magic Mode

Purpose: Supervised plan-first orchestration.

MVP:

- Goal input.
- Plan preview.
- Risk and approval gates per step.
- "No actions executed" guarantee.

Later:

- Approval queue.
- Pause/stop.
- Step execution only after policy engine and audit logger are proven.

### 3. Models

Purpose: Make model state understandable.

MVP:

- Installed local models.
- Configured aliases.
- Active selected/fallback model.
- Hardware tier warning.

Later:

- Explicit model download flow with confirmation.
- Profile-aware recommendations.

### 4. Memory

Purpose: Let the user trust and control learning.

MVP:

- Collection health.
- Approved preference list.
- Search/review/delete controls when backend exists.
- Clear memory-write approval requirement.

Later:

- Session summaries.
- Conflict review.
- Preference approval workflow.

### 5. Security Center

Purpose: Show what Merlin is allowed to do.

MVP:

- 15 approval gates.
- Cloud disabled/enabled state.
- API key presence only.
- Audit log summaries.

Later:

- Policy editor with validation.
- Exportable audit reports.

### 6. System Health

Purpose: Make the stack understandable for non-technical users.

MVP:

- Ollama, LiteLLM, Qdrant, Open WebUI, status API, task API.
- Active profile.
- Hardware tier.
- Disk/RAM warning.

Later:

- Safe service start/stop once policy-gated backend exists.

## MVP Acceptance Criteria

- A non-technical user lands in Merlin Chat, not a services dashboard.
- Local-only/cloud-disabled state is visible without opening settings.
- Low-memory warnings are visible on 8 GB Macs.
- The UI can show a blocked approval gate without implying auto-approval.
- Dashboard never displays secrets, raw audit input, or API key values.
- Dashboard still functions in degraded mode when optional services are down.
