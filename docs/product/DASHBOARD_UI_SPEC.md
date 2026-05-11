# Dashboard UI Spec — Merlin Dashboard

Last updated: 2026-05-10

## Design Standard

Merlin Dashboard should feel like an Apple-quality first-run product surface: quiet,
plain, confident, and one or two clicks from the action the user needs.

Do not turn the dashboard into an engineering cockpit for v1.0. Put technical
detail behind simple labels.

## First Screen

The first screen should answer:

1. Did install work?
2. Is Merlin ready?
3. Is cloud off?
4. What do I do first?
5. How do I fix or uninstall this?

Preferred copy:

> Your private AI is ready.

If degraded:

> Merlin is warming up.
> Local chat is not ready yet. Open Docker Desktop, wait one minute, then run
> `bash scripts/doctor.sh`.

## Visual Direction

- Dark, calm, premium surface.
- Teal/cyan Merlin accent.
- Merlin face/orb centered only where it supports the chat/assistant identity.
- Status states use label + color, never color alone.
- Avoid large technical cards on the main chat surface.
- Side panels may contain service detail, but the center should stay clean.

## v1.0 UI Elements

- Merlin identity.
- Local/private indicator.
- Core readiness state.
- First local question composer or clear link to current local chat.
- Service map in plain English.
- Recovery panel.
- Uninstall/purge guidance.

## Future UI Elements

Rooms, Memory, Brains, Agents, Security, Settings, voice mode, animated orb
reactivity, connector setup, and model library belong to
[`FUTURE_IDEAS.md`](FUTURE_IDEAS.md) unless they directly improve the five v1.0
jobs.

## Hard No

- No fake readiness.
- No cloud opt-in by accident.
- No hidden telemetry.
- No browser execution.
- No overloaded center screen.
- No "gated/route/model" debug copy as primary user text.
