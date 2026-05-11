# Merlin AI — Product Guide

**Merlin assistant inside | `TheYfactora12/Secure-Local--AI-Merlin` | v1.0 focus**

## One Sentence

Download one file, run it, and in 30 minutes you have a fully private AI running
on your Mac that you own forever. If you ever want it gone, one click removes
everything.

## What This Product Is

Merlin AI is a local-first Mac product for people who want private AI at
home without becoming local-AI operators.

Merlin is the assistant inside Merlin AI. The user talks to Merlin. Under
the hood, Merlin uses local services such as Ollama, Open WebUI, LiteLLM, and
Qdrant, but v1.0 must not make the user understand those parts before they can
get value.

## What v1.0 Must Do

1. **Install everything in one shot.**
   One command or one installer starts the local AI stack without Docker
   expertise.

2. **Tell the user it worked.**
   Wizard HQ opens to a clear first-run state: "Your private AI is ready," what
   is running, and what to do first.

3. **Keep everything private.**
   No cloud account, no API key, no telemetry, no surprise model download, and
   no data leaving the machine by default.

4. **Recover gracefully.**
   If a service is degraded, the user sees plain English: what broke, why it
   matters, and what to do next.

5. **Uninstall cleanly.**
   One command or one click can remove the product. Full purge removes
   containers, volumes, configs, launch agents, local app files, and downloaded
   pieces when the user asks for that.

## Current Stack

| Component | Purpose | v1.0 User Framing |
| --- | --- | --- |
| Wizard HQ | Local dashboard | "Your private AI is ready / needs attention." |
| Merlin | Assistant and internal brain | The thing the user talks to. |
| Ollama | Local model runtime | Runs the AI model on owned hardware. |
| Open WebUI | Local chat workspace | Current proven chat bridge under Merlin. |
| LiteLLM | Local model route layer | Keeps model routing local-first. |
| Qdrant | Local vector store | Stores approved memory/context locally. |
| n8n | Optional workflows | Future/optional; not required for v1.0 value. |
| Perplexica/SearXNG | Optional private search | Future/optional; not required for v1.0 value. |
| OpenHands | Optional coding agent | Future/optional; high-risk and not v1.0 default. |

## What Is Future

Rooms, export/import brain, voice, Home Assistant, Linux, provider connectors,
professional evidence mode, supervised agents, native automation, and advanced
governance live in [`FUTURE_IDEAS.md`](FUTURE_IDEAS.md). They are good ideas,
but they are not v1.0 promises.

## Release Language

Allowed:

- "Local Trusted Beta hardening."
- "Your private AI."
- "Cloud off by default."
- "Merlin inside Merlin AI."

Not allowed yet:

- Public Beta ready.
- Public Release ready.
- Fully autonomous.
- Compliance-ready.
- Enterprise-ready.

## First User Journey

1. User installs Merlin AI.
2. Wizard HQ opens.
3. User sees "Your private AI is ready" or a plain-English degraded state.
4. User asks Merlin a local question.
5. User sees that cloud is off by default.
6. User can run doctor/recovery guidance if something is degraded.
7. User can uninstall or purge everything if they choose.
