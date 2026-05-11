# Dashboard Product Spec — Merlin Dashboard

Last updated: 2026-05-10

## Product Goal

Merlin Dashboard is the first screen after install. It exists to prove the five v1.0
jobs, not to expose every future capability.

The user should understand in under 30 seconds:

- Merlin AI installed.
- Merlin is the assistant.
- Local AI is ready, warming, degraded, or failed.
- Cloud is off by default.
- The first safe action is to ask Merlin a local question.
- Recovery and uninstall paths are visible.

## v1.0 Dashboard Scope

- First-run state: "Your private AI is ready" or a plain degraded state.
- Plain-English service map for Ollama, Open WebUI, LiteLLM, Qdrant, and Wizard
  HQ.
- Local/private proof: cloud off, telemetry off, no API key required.
- Honest readiness states from localhost checks.
- Recovery guidance when a core service is down.
- Link/command for doctor and status checks.
- Uninstall/purge guidance.
- Optional Merlin Chat only if it does not hide readiness or create fake
  capability.

## Parked Dashboard Scope

The following remain future unless they directly improve install, onboarding,
privacy, recovery, or uninstall:

- Deep Rooms management.
- Memory review/delete UI.
- Provider/API key setup.
- Model library and downloads.
- Voice mode.
- Animated orb polish.
- Agent panels.
- Magic Mode execution.
- Professional/security reporting.
- Multi-user/admin settings.

## Hard Guardrails

- No browser-side shell execution.
- No service start/stop controls in the browser unless a policy-gated backend
  issue owns them and tests exist.
- No API key values displayed.
- No cloud/API calls by default.
- No automatic model downloads.
- No "Ready" unless checks pass.
- No public beta or public release claims.

## Success Criteria

- A nontechnical user knows what happened after install.
- A degraded service tells the user what to do next.
- The privacy posture is visible without opening settings.
- The first action is obvious.
- The user can find uninstall guidance.
