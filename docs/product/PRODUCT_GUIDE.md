# Wizard AI — What It Is, What It Does, What's Coming
**Home AI Elite | `TheYfactora12/home-ai-elite` | v1.0 Pre-Release**
*Built from live repo source — 2026-05-06*

---

## The One-Sentence Version

Wizard AI is a **local-first AI operating system** you install on your own Mac or Linux machine that gives you your own private Perplexity, your own Codex, your own memory — with zero required subscriptions and zero data leaving your hardware unless you explicitly say so.

---

## The Problem It Solves

Every major AI tool — ChatGPT, Perplexity, Copilot, Zapier AI, Pinecone — runs on someone else's servers. Your prompts, your data, your context, your preferences are all sent to a cloud you don't control. You pay a monthly fee to rent intelligence you can never own.

Wizard AI flips that. The AI runs on your hardware, uses your GPU (Apple Silicon supported natively), stores memory in your local database, and routes tasks through a policy engine you can read and audit. You own every bit of it.

---

## What the Product Is Made Of

Wizard AI is not one app. It is a **stack of purpose-built components** orchestrated by a single installer and unified under one AI brain called **Merlin**.

### The Core Stack

| Component | What It Replaces | Port | Notes |
|---|---|---|---|
| **Open WebUI** | ChatGPT | 3000 | Primary chat interface for Merlin |
| **Ollama** | OpenAI API | 11434 | Runs models locally; Apple Metal GPU on macOS |
| **LiteLLM** | OpenAI API layer | 4000 | Routes model aliases to local or optional cloud |
| **Qdrant** | Pinecone | 6333 | Local vector database — memory lives here |
| **n8n** | Zapier | 5678 | Automation workflows; session memory bridge |
| **Perplexica** | Perplexity AI | 3002 | Local AI-powered search |
| **SearXNG** | Google (for AI) | 8080 | Privacy-first metasearch engine |
| **OpenHands** | GitHub Copilot / Codex | 3003 | Autonomous coding agent (high-risk, opt-in profile) |
| **Wizard HQ Dashboard** | Manual status checks | 8888 | Single-pane-of-glass control panel |
| **Merlin Status API** | — | 8765 | Read-only status bridge, localhost only |
| **Merlin Task API** | — | 8766 | FastAPI task routing and status surfaces |

### The Merlin Brain

Merlin is the AI control plane that sits above all these services. It is not a chatbot. It is the decision layer that decides **which model runs, which staff mode activates, whether an action needs approval, and what gets written to memory**.

The commercial direction is to evolve Merlin into a private AI control plane
for owned AI infrastructure: Wizard HQ as the product shell, Brains as model and
provider options, Memory as an approved vault, Agents as supervised workers,
Security as policy/audit visibility, and System as honest local readiness.
Future milestones add AI asset inventory, identity/trust graph, access reviews,
monitoring signals, DLP-style gates, governance evidence, and only later a
Merlin-native workflow runtime. See
`docs/product/MERLIN_CONTROL_PLANE_STRATEGY.md`.

Current release language must stay precise: Merlin is not yet a completed AI
firewall, IDS, IPS, DLP, or enterprise governance suite. Those are future
roadmap outcomes that need their own issues, tests, and evidence.

Merlin is built on six Python modules:

| Module | What It Does |
|---|---|
| `merlin/config_loader.py` | Validates the YAML config set on startup |
| `merlin/policy_engine.py` | Enforces 15 fail-closed approval gates |
| `merlin/router.py` | Routes tasks to the right model, staff mode, and agent target |
| `merlin/memory_manager.py` | Manages Qdrant reads/writes with dimension guards |
| `merlin/persona_injector.py` | Builds system prompts with Merlin's ethos and Pi warmth |
| `merlin/task_endpoint.py` | Exposes FastAPI on port 8766 for task routing |

---

## What Merlin Can Do Right Now

### 1. Route Any Task to the Right AI

Merlin reads your request and decides: Is this a coding task? A memory search? An automation? A security review? A general question? Each type routes to a different **staff mode** with the right model and system prompt.

**The 6 Staff Modes:**

| Mode | What It's For | Default Model |
|---|---|---|
| **Architect** | System design, service boundaries, scalability | `deepseek` |
| **AI Engineer** | Model routing, embeddings, RAG, evals | `qwen-coder` |
| **Software Engineer** | Code, tests, CI, scripts | `qwen-coder` |
| **Security Reviewer** | Secrets, permissions, threat modeling | `deepseek` |
| **Product Designer** | Dashboard, user flows, UX | `qwen7b` |
| **Operator** | Health checks, upgrades, logs, hardware tiers | `mistral` |

### 2. Remember Things You've Approved

Merlin has five canonical memory collections in Qdrant:

| Collection | What It Stores | Dimensions |
|---|---|---|
| `merlin_session` | Working session context (4h TTL) | 768 |
| `merlin_user` | Long-term user preferences (approved) | 768 |
| `merlin_documents` | Ingested local documents | 768 |
| `merlin_tools` | Tool/skill knowledge | 768 |
| `merlin_audit` | Redacted execution audit trail | 768 |

**Critical:** Nothing is written to memory without your explicit approval. Every write goes through the `memory_write` approval gate. Merlin never silently learns from your conversations.

### 3. Preview Decisions Before Executing

`wizard merlin dry-run "goal"` shows you exactly what Merlin would do — which route, which staff mode, which model, which approval gates trigger — without executing anything. No side effects. No surprises.

### 4. Enforce a 15-Gate Approval Policy

Before any risky action executes, Merlin's policy engine checks 15 gates. These fail closed — if there's no explicit approval, the action is blocked. The gates cover:

- Shell command execution
- File read/write
- Network calls
- Cloud/API calls
- Memory writes
- Service start/stop
- Model downloads
- OpenHands (autonomous code agent) access
- Secret access
- Webhook-triggered execution
- And more

### 5. Run Automation Workflows

n8n workflows handle repeatable tasks: the session memory bridge (`swarm/session/memory`) bridges Merlin's working memory to n8n-triggered automations. All workflows ship inactive — you activate only what you've validated.

### 6. Search the Web Privately

Perplexica + SearXNG give you AI-powered search with no tracking. Your queries stay on your machine and hit open search engines directly, not a cloud intermediary.

### 7. Write Code Autonomously (Opt-In)

OpenHands, when enabled via the `coding` profile, can read your codebase, write files, and run terminal commands. It uses Docker socket access, which is why it's gated behind explicit profile selection and approval. It's the most powerful — and most dangerous — capability in the stack.

### 8. Show You Everything in a Dashboard

Wizard HQ at `localhost:8888` shows:
- All running services and their status
- Your hardware tier (low/base/mid/high)
- Active staff mode and selected model
- Privacy and cloud state
- Approval queue
- Memory status
- Profile (core/search/automation/coding/full)

---

## What Hardware You Need

Wizard AI is designed to run on **hardware you already own**. The entry point is an 8GB Mac.

| Your RAM | Tier | What You Get |
|---|---|---|
| **8–15 GB** | `low` | Chat (qwen2.5:7b), local memory (nomic-embed-text), all core services |
| **16–23 GB** | `base` | + coder model (qwen2.5-coder:7b) + reasoning model (deepseek-r1:7b) |
| **24–47 GB** | `mid` | + 32B parameter models — significantly better reasoning |
| **48+ GB** | `high` | + 70B models (llama3.3:70b) — near-cloud quality, fully local |

**Apple Silicon note:** On Apple Silicon Macs, your RAM is shared between CPU and GPU (unified memory). Ollama uses Apple Metal for GPU acceleration — this is a first-class feature of the architecture, not an afterthought.

---

## How You Install It

One command:

```bash
bash install.sh
```

The installer:
1. Detects your OS (macOS vs. Linux) and hardware tier
2. Selects the right profile
3. Rotates secrets and writes `.env`
4. Starts Docker services for your profile
5. Bootstraps Qdrant collections
6. Imports n8n workflows (inactive by default)
7. Registers launchd agents (macOS auto-start on login)

**macOS:** Ollama runs natively via Homebrew for Apple Metal acceleration. Docker runs everything else.
**Linux:** Ollama can run in Docker via `--profile docker-ollama`.

After install, validate with:
```bash
bash scripts/doctor.sh
# Expected: 43 passes, ≤2 warnings, 0 failures
```

---

## Install Profiles

You don't have to run everything. Choose what you need:

| Profile | Services | Best For |
|---|---|---|
| `core` | Chat, memory, dashboard | Daily AI use on any hardware |
| `search` | + Perplexica + SearXNG | Private web research |
| `automation` | + n8n | Workflow automation |
| `coding` | + OpenHands | Autonomous coding agent |
| `full` | Everything | Power users with 24GB+ RAM |

```bash
wizard start core        # Laptop-safe default
wizard start search      # Add private search
wizard start automation  # Add n8n automation
wizard start coding      # Add OpenHands (high RAM/risk)
```

---

## The CLI — How You Talk to Merlin

```bash
# Preview any request — zero side effects
wizard merlin dry-run "refactor my config loader"

# Check system state
wizard merlin status

# Manage approvals
wizard merlin approvals list
wizard merlin approvals approve <id>
wizard merlin approvals deny <id>

# Memory — all approval-gated
wizard merlin memory plan --memory-type preference --text "prefers local-first"
wizard merlin memory write --memory-type preference --text "..." --approval-id <id>
wizard merlin memory search --query "local-first preference" --memory-type preference

# Staff mode visibility
wizard mode status

# Health
bash scripts/doctor.sh
wizard doctor
```

---

## What Is Coming Next (Phase 3 Learning)

Phase 3 adds **review-first learning loops**. Merlin starts getting smarter about your preferences — but still never learns without your consent.

| Phase | What It Adds |
|---|---|
| **3A — Outcome Observer** | Tracks task success/failure by route (hashed input only, no raw prompts) |
| **3B — Retrieval Routing** | Blends keyword routing with approved outcome history for better route decisions |
| **3C — Preference Extractor** | Surfaces explicit preferences for your review — never writes automatically |
| **3D — Session Reflector** | Short-lived session summaries for continuity (expire by default) |
| **3E — Skill Scores** | Routing confidence improves over time from your approved feedback |

The routing formula for Phase 3B:
```
final_route_score = (0.6 × keyword_score) + (0.4 × retrieval_score)
```

Keyword matching stays dominant (60%) so Merlin's routing is always explainable, never a black box.

---

## The Milestone Roadmap

| Milestone | Status | What It Delivers |
|---|---|---|
| **v1.0 — Stable Installer** | ✅ Complete | Rock-solid install, package, backup, restore, upgrade, uninstall on 8GB Mac |
| **v1.1 — Mobile Access** | ✅ Complete | Optional local-network entry point design (opt-in, no default LAN exposure) |
| **v1.2 — Hardware Guide + Doc Ingestion** | ✅ Complete | 8GB-first hardware guide, free stack map, optional document ingestion planning |
| **v1.3 — Reliability + Memory + Router** | 🔵 Active | Retry logic, memory reliability, router cleanup |
| **v2.0 — Merlin Staff Core** | ✅ Complete | Full Python control plane, 6 staff modes, 15 policy gates, memory manager |
| **v2.1 — Dashboard Command Center** | 📋 Planned | Read-only/user-facing Merlin control center |
| **v2.2 — Magic Mode** | 📋 Planned | Supervised multi-step orchestration — plan-first, approval-gated |
| **v3.0 — Public Release** | 📋 Planned | Public packaging, onboarding polish, signed installer |

---

## What Makes This Different

| Feature | Wizard AI | ChatGPT / Copilot / Perplexity |
|---|---|---|
| Data stays on your machine | ✅ Always | ❌ Sent to cloud |
| Works offline | ✅ Core features | ❌ Requires internet |
| You own the memory | ✅ Qdrant, local | ❌ Cloud provider owns it |
| Monthly subscription | ❌ None required | ✅ Required |
| Apple Silicon GPU acceleration | ✅ Native Metal | ❌ n/a |
| Audit trail of every AI decision | ✅ JSONL, redacted | ❌ Not available |
| Approval gates before risky actions | ✅ 15 fail-closed gates | ❌ None |
| Runs on an 8GB laptop | ✅ Validated | ❌ n/a |
| You can read the policy | ✅ `configs/merlin/policy.yaml` | ❌ Proprietary |

---

## The Merlin Ethos

> *"Merlin is here to help, protect, and improve. Merlin must be truthful, humble, protective, and guided by love, service, and care for humanity. Merlin must not lie, fabricate capability, hide uncertainty, or claim incomplete work is complete."*

This is a literal constraint in `configs/merlin/persona.yaml` that governs every Merlin system prompt. The system implements Pi Emotional Intelligence — it asks follow-up questions, recalls within-session context, and communicates with warmth without pretending to be more capable than it is.

Merlin is a **product assistant, not an authority**. It preserves consent, evidence, safety policy, and user control at every decision point.

---

## Quick Start (30 Seconds)

```bash
# 1. Clone and install (macOS, 8GB+)
git clone https://github.com/TheYfactora12/home-ai-elite
cd home-ai-elite
bash install.sh

# 2. Verify
bash scripts/doctor.sh

# 3. Open the dashboard
open http://localhost:8888

# 4. Start talking to Merlin
open http://localhost:3000

# 5. Preview a task decision
wizard merlin dry-run "help me write a Python script"
```

---

## Related Docs

| If you want to... | Read this |
|---|---|
| Understand the full architecture | [`docs/MASTER_CONTEXT.md`](../MASTER_CONTEXT.md) |
| Start a Codex session | [`docs/engineering/CODEX_MASTER_PROMPT.md`](../engineering/CODEX_MASTER_PROMPT.md) |
| See the active build roadmap | [`docs/MERLIN_IMPLEMENTATION_ROADMAP.md`](../MERLIN_IMPLEMENTATION_ROADMAP.md) |
| Understand the staff mode system | [`docs/architecture/MERLIN_STAFF_CORE.md`](../architecture/MERLIN_STAFF_CORE.md) |
| Review the security model | [`docs/security/SECURITY_MODEL.md`](../security/SECURITY_MODEL.md) |
| Debug a failure | [`docs/operations/FAILURE_MAP.md`](../operations/FAILURE_MAP.md) |
| Understand hardware requirements | [`docs/hardware-guide.md`](../hardware-guide.md) |
| See Phase 3 learning design | [`docs/MERLIN_PHASE3_LEARNING_PLAN.md`](../MERLIN_PHASE3_LEARNING_PLAN.md) |

---

*Source: live repo read — `TheYfactora12/home-ai-elite` — 2026-05-06*
*MASTER_PROMPT.md · MASTER_CONTEXT.md · MERLIN_STAFF_CORE.md · MERLIN_IMPLEMENTATION_ROADMAP.md · MERLIN_PHASE3_LEARNING_PLAN.md*
