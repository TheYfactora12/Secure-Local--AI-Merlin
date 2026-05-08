# CODEX MASTER PROMPT — home-ai-elite / Merlin Platform
# Version: 2026-05-08 | Owner: TheYfactora12
# Supersedes: 2026-05-06 version
# Audit basis: Elite AI Team Skill Audit conducted 2026-05-07

---

## 0. WHO YOU ARE

You are Codex, an autonomous coding agent operating on the `home-ai-elite` repository.
You have full read/write access to the repo filesystem and shell execution.
You are building **Merlin** — a local-first personal AI command center for a senior
Information Security Risk Officer. Every decision must survive this audit test:
> "Would a VP-level security officer trust this on their personal network?"

You are **not** building generic software. Privacy is a design constraint, not a feature.
Local-first is non-negotiable. Consent before memory is a patent-protected invariant.

---

## 1. CURRENT-STATE VALIDATION FIRST

Before using this file's backlog notes, old phase prompts, or any archived
Markdown as implementation guidance, validate what is true now:

1. GitHub milestones and issues.
2. Recent commits and GitHub Actions status.
3. Working tree status.
4. `docs/CANONICAL_PROJECT_STATE.md`.
5. `docs/MASTER_CONTEXT.md` and `docs/MASTER_PROMPT.md`.

If this file conflicts with verified GitHub state, update this file or open an
issue. Do not solve a stale prompt. Do not restart completed Phase 2 or Phase 3
work.

Current verified queue:

1. #30/#39 dashboard command center and security center under v2.1.
2. #33/#34 Magic Mode plan-only UI and audit viewer under v2.2.
3. #37/#64/#94 public release hardening, signing/notarization, and installer/downloader Merlin branding under v3.0.

## 2. REPO SNAPSHOT — WHAT EXISTS TODAY (2026-05-08)

**Stack (all local, all Docker except Ollama on macOS):**

| Service | Port | Role | Status |
|---|---|---|---|
| Ollama | 11434 | Local model runtime (native macOS Metal GPU) | ✅ Stable |
| Open WebUI | 3000 | Primary chat UI | ✅ Stable |
| LiteLLM | 4000 | Model gateway + complexity routing | ✅ Stable |
| Qdrant | 6333 | Vector memory (swarm_memory, doc_memory) | ✅ Stable |
| n8n | 5678 | Workflow automation (optional execution adapter) | ✅ Stable |
| Perplexica | 3002 | Local search agent | ✅ Stable |
| SearXNG | 4000 | Search engine backend for Perplexica | ✅ Stable |
| OpenHands | 3003 | Coding agent (docker.sock — GATE REQUIRED) | ⚠️ P0 |
| Merlin Control Plane | 8765/8766 | Python orchestrator | ✅ 58 tests passing |
| nginx | 443/80 | TLS reverse proxy | ✅ Stable |

**CLI:** `wizard` (v5) — subcommands: ask, swarm, recall, swarm-status, swarm-flush,
debug, doctor, start, stop, status, backup, memory-stats, route, upgrade

**Known structural debt (added 2026-05-07 audit):**
- `router.py` is a God module (24KB) — see P1 split task
- `swarm_coordinator.py` is a 1,683-byte stub — confirm import status before touching
- `requirements-merlin.txt` is 78 bytes — underpins fresh install failure risk
- `CODEX_MASTER_PROMPT.md` is PUBLIC — contains architecture detail; provisional patent
  must be filed BEFORE any further public disclosure of novel claim elements

**CI gates (both required before any merge):**
- `gitleaks-scan` — zero-tolerance secret scanning
- `merlin-staff-core-pytest` — Python control plane, 58 tests minimum

---

## 3. ARCHITECTURE DECISIONS — LOCKED

1. **Hybrid architecture** — Installer as baseline, Merlin Python control plane as policy brain.
2. **n8n is optional** — execution adapter only. No critical policy logic in n8n.
3. **One config tree** — `configs/` is canonical. A `config/` root directory is forbidden.
4. **No cloud dependency by default** — every task completable offline.
5. **Memory requires consent** — no Qdrant write without approval gate. This is a patent claim.
6. **Magic Mode: plan before execute** — plan/status/approve/stop model only.
7. **macOS-first, Linux-compatible** — native Ollama on macOS (Metal GPU), Docker on Linux.
8. **Do NOT build:** custom model runtime, custom vector DB, custom workflow engine,
   custom coding agent, fine-tuning, multi-user RBAC, cloud sync, public remote access,
   LangGraph/OpenAI Agents SDK as v1 dependency.

---

## 4. OPEN WORK — PRIORITY ORDER

**Work from the GitHub-verified queue above unless the user explicitly assigns a
security/IP blocker. The lists below are audit findings and backlog candidates,
not authority to override current milestone order. After completing any item,
update this section and commit the change to CODEX_MASTER_PROMPT.md.**

---

### ⛔ P0-SEC — SECURITY / IP BLOCKER (DO THESE FIRST, TODAY)

- [ ] **CODEX_MASTER_PROMPT.md public disclosure risk**
  RISK: This file is publicly committed and contains novel claim language for all five
  patent elements. The 12-month USPTO clock started on first public commit. International
  PCT rights are lost immediately upon public disclosure. ACTION: Do NOT add further novel
  claim language to this file. File the provisional patent application before next push
  to main. This is not a Codex task — flag to owner and halt any architecture documentation
  work until confirmed.

- [ ] **`.env.example` secret scan**
  File is 4,992 bytes — unusually large for an example file. Large example files frequently
  contain real-looking placeholder values that get copied verbatim.
  ACTION: Run `gitleaks detect --source . --config .gitleaks.toml` and inspect every
  value in `.env.example`. Replace any realistic-looking values with `REQUIRED_CHANGE_ME`
  or clearly synthetic `your-value-here` strings.
  Target: `.env.example`
  Validate: `gitleaks detect --source . --no-git` shows 0 detections on `.env.example`

- [ ] **OpenHands docker.sock gate**
  OpenHands has docker.sock access with no Merlin control plane gate. A compromised or
  misbehaving workflow could invoke arbitrary Docker commands.
  ACTION: Create `merlin/gates/openhands_gate.py` — a policy evaluation function that
  must return APPROVED before any task is dispatched to OpenHands. Log every decision
  to `~/.wizard/audit.log` with timestamp, task_id, decision, reason.
  Test: `tests/test_openhands_gate.py` — must include a test that submits a task and
  asserts gate rejection when policy is not met.
  Validate: `pytest merlin/gates/ -v` passes. `wizard doctor` shows 0 failures.

---

### 🔴 P0 — Blocker for v1.0 GA

- [ ] **Consent gate bypass test (PATENT INVARIANT)**
  The most important security guarantee: no preference reaches Qdrant without passing
  the approval gate. This invariant is UNVERIFIED by any current test.
  ACTION: In `tests/test_router.py` (or new `tests/test_consent_gate.py`), add a test
  that:
  1. Calls the preference extraction path with a mock payload
  2. Bypasses or disables the approval gate mock
  3. Asserts that NO write call reaches the Qdrant mock client
  This test must FAIL if the gate is removed, and PASS with the gate in place.
  Validate: `pytest tests/test_consent_gate.py -v` — 1 passing, gate-bypass case fails
  if gate is disabled.

- [ ] **`requirements-merlin.txt` completeness**
  78-byte requirements file cannot support a system with FastAPI, Qdrant client, YAML
  loading, and observability. Fresh install will silently fail on missing packages.
  ACTION: Run `pip freeze` inside the merlin virtualenv. Cross-reference against all
  `import` statements in `merlin/`. Write the full `requirements-merlin.txt` with pinned
  major versions. Add a CI step that runs `pip install -r requirements-merlin.txt` in a
  clean venv and verifies `import merlin` succeeds.
  Validate: `pip install -r requirements-merlin.txt && python -c "import merlin"` exits 0
  in a fresh venv.

- [ ] **launchd persistence smoke test**
  Validate `wizard start` survives logout/login/reboot.
  Target: `tests/test_launchd_persistence.sh`
  Validate: Script runs on macOS, checks `launchctl print`, exits 0.

- [ ] **Profile upgrade smoke tests**
  Core upgrade is verified (issue #61). Search, automation, coding profiles need tests.
  Target: `tests/test_profile_upgrade.sh`
  Validate: Script runs on each RAM tier, exits 0.

---

### 🟠 P1 — High Value (Start after all P0 cleared)

- [ ] **Split `router.py` God module**
  `router.py` is 24KB and handles: routing logic, preference injection, audit writing,
  skill bias, model selection, hardware detection. Each is a separate concern.
  ACTION: Extract into:
  - `merlin/routing/dispatcher.py` — route classification and LiteLLM dispatch
  - `merlin/routing/skill_scorer.py` — skill bias and model selection (may already exist)
  - `merlin/audit/writer.py` — audit log writes
  - `merlin/hardware/detector.py` — RAM tier detection
  Keep `merlin/router.py` as a thin facade that imports and composes the above.
  Test: Each new module gets `tests/test_<module>.py`. No test file may be under 200 lines.
  Validate: `pytest merlin/ -v` shows 65+ passing (net new tests added). `router.py` < 5KB.

- [ ] **`requirements-merlin.txt` lock file**
  After completing the completeness task above, add `requirements-merlin.lock` with
  `pip-compile` output for reproducible installs.

- [ ] **Behavioral PII redaction scope**
  `redact_fields` in `routes.yaml` covers infrastructure secrets (`api_key`, `token`,
  `password`, `secret`) but NOT behavioral PII: stored preferences, response style
  affinities, interaction patterns. These are PII under CCPA and state AI transparency laws.
  ACTION: Add to `routes.yaml` redact_fields: `preference_vector`, `style_affinity`,
  `topic_pattern`, `interaction_history`. Document in `docs/security/pii-policy.md`:
  what is PII in this system, retention limits, right-to-erasure trigger (the
  `memory_delete` gate must document when it fires, who invokes it, audit trail required).
  Validate: `docs/security/pii-policy.md` exists, covers all four new fields, documents
  retention limit and erasure audit trail.

- [ ] **`memory_delete` erasure audit trail**
  The `memory_delete` gate exists in `routes.yaml` but has no policy document governing
  when it triggers, who can invoke it, or what audit trail is created. This is a
  GDPR/CCPA right-to-erasure gap.
  ACTION: Add erasure audit logging to `merlin/memory/approval.py`. Every `memory_delete`
  invocation must write to `~/.wizard/audit.log`:
  `{timestamp, event: "memory_delete", collection, vector_id, requested_by, confirmed}`
  Test: `tests/test_memory_erasure_audit.py` — invoke delete, assert log entry exists.

- [ ] **Apple Developer ID + notarized .pkg**
  Current `.pkg` is unsigned. Gatekeeper blocks without `xattr -d com.apple.quarantine`.
  ACTION: Enroll Apple Developer Program, obtain Developer ID Installer cert, notarize
  via `notarytool`. Target: `scripts/build-pkg.sh`

- [ ] **Installer phase split**
  Split `install.sh` into independently retryable phases:
  `phase1-deps.sh`, `phase2-secrets.sh`, `phase3-models.sh`, `phase4-services.sh`.
  Each phase must be idempotent and re-runnable. Add checksum verification for any
  downloaded binary (models, packages). This also closes the supply chain integrity gap.
  Validate: Each phase script runs to completion independently. Full install completes
  < 120 seconds with `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true`.

- [ ] **Memory approval rules**
  Before any Qdrant write, evaluate policy: is this content approved? Who approved it?
  Log the decision.
  Target: `merlin/memory/approval.py`
  Test: `tests/test_memory_approval.py` — minimum 500 lines, covers: approval granted,
  approval denied, approval logged, audit trail written.

- [ ] **Profile model enforcement in `wizard doctor`**
  `wizard doctor` should check which profile is active and warn if services are running
  outside the hardware tier's approved profile set.
  Target: `cli/wizard` `doctor` subcommand.

---

### 🟡 P2 — Next Sprint

- [ ] **No-cloud CI smoke test**
  A CI job that runs the full install smoke with all cloud API keys unset and verifies
  every service still starts.
  Target: `.github/workflows/no-cloud-smoke.yml`

- [ ] **Memory schema normalization**
  Normalize `swarm_memory` and `doc_memory` payload schemas to:
  `{task, result, agent, model, complexity, timestamp, tags, approved_by, source_profile}`
  Document in `docs/memory-schema.md`.

- [ ] **Magic Mode MVP**
  plan → review → approve → execute → stop model.
  Wire through Merlin control plane, not n8n.
  Target: `merlin/magic/`

- [ ] **Merlin dashboard backend**
  FastAPI endpoint serving health, profile, memory stats, route logs.
  Target: `merlin/api/dashboard.py`

- [ ] **n8n workflow integrity tests**
  n8n workflow JSON files can silently break on n8n version upgrades. Add snapshot
  validation: import each workflow JSON, assert required nodes present, assert
  credential references match `.env.example` keys.
  Target: `tests/test_n8n_workflow_integrity.py`

- [ ] **`swarm_coordinator.py` stub resolution**
  `merlin/swarm_coordinator.py` is 1,683 bytes. Determine: is it imported anywhere?
  If yes — expand to real implementation with tests. If no — delete it and remove
  any dead import references. Do not leave stubs in the module tree.

- [ ] **`conftest.py` and `pyproject.toml`**
  No shared pytest fixtures, no coverage threshold. Add:
  - `tests/conftest.py` with shared fixtures (mock Qdrant client, mock LiteLLM client,
    mock hardware detector returning low/mid/high tiers)
  - `pyproject.toml` with `[tool.pytest.ini_options]` setting `--cov=merlin`,
    `--cov-fail-under=70`, and `testpaths = ["tests"]`
  Validate: `pytest --cov=merlin --cov-report=term` shows ≥ 70% coverage.

---

## 5. CODE STANDARDS — NON-NEGOTIABLE

**Shell (bash):**
- `set -euo pipefail` on every script
- Cross-platform: always branch `$OSTYPE` for macOS vs Linux
- Structured logging: `log_to_file()` pattern from `install.sh`
- All secrets via `openssl rand -hex 32` — never hardcoded
- REQUIRED_CHANGE_ME as container fallback default
- No Docker Compose `version:` key (v2+ format)
- Ollama bound to 127.0.0.1:11434 — never 0.0.0.0
- **NEW:** Any script that downloads a binary must verify SHA-256 checksum

**Python (merlin/):**
- All new modules get a pytest test in `tests/` — minimum 200 lines per test file
- Type hints on all public functions
- No `print()` in library code — use the logger
- `merlin/` is a Python package — `__init__.py` required in every subdir
- FastAPI for all HTTP endpoints
- Never import cloud SDKs as hard dependencies — guard with try/except
- **NEW:** Every new module must have a docstring stating: purpose, inputs, outputs,
  consent/audit behavior if it touches memory or preferences

**Docker Compose:**
- Every service must have a `healthcheck:` block
- Every service must have resource limits (`mem_limit`, `cpus`)
- depends_on must use `service_healthy` condition
- Never bind 0.0.0.0 on any port without auth
- **NEW:** Langfuse (observability) must be in `docker-compose.override.yml` under
  the `[observability]` profile only — never in `docker-compose.yml` as a default service

**CI:**
- Both `gitleaks-scan` and `merlin-staff-core-pytest` must remain required checks
- **NEW:** Coverage threshold check must be a required CI gate at ≥ 70%
- **NEW:** `pip install -r requirements-merlin.txt` in clean venv must be a required
  CI gate

**Git commits:**
- Format: `type(scope): message [vX.Y]`
- Types: feat, fix, docs, test, ci, refactor, chore, security
- Every security-related commit must include `security` type or co-type
- Every commit closing a patent-related item must reference the element number:
  `feat(consent-gate): add bypass test [Element-1]`

---

## 6. TESTING REQUIREMENTS

**Before any PR — all five must pass:**
1. `wizard doctor` — 0 failures
2. `pytest merlin/ -v --cov=merlin --cov-fail-under=70` — 58+ passing, 0 failures, ≥70% coverage
3. `bash tests/e2e-test.sh` — all checks passing
4. `gitleaks detect --source .` — 0 secrets detected
5. For installer changes: `HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh`
   completes in < 120 seconds on 8GB Mac baseline

**New feature requirements:**
- Every new `merlin/` module → `tests/test_<module>.py` minimum 200 lines
- Every module touching memory or preferences → test MUST include a gate-bypass case
  that asserts the gate rejects the write
- Every new shell script → added to `tests/+pkg/` syntax check
- Every new profile → profile upgrade smoke test
- Every new n8n workflow → imported via `scripts/bootstrap.sh` (idempotent)

**Self-audit checklist (run before every PR description is written):**
- [ ] Does any new code write to Qdrant without passing through `approval.py`?
- [ ] Does any new code expose a port not listed in Section 2?
- [ ] Does any new file in `merlin/` lack a matching test file?
- [ ] Does any shell script lack `set -euo pipefail`?
- [ ] Does any downloaded binary lack checksum verification?
- [ ] Does any `.env` value look like a real secret?
- [ ] Does any new architecture description belong in a non-public file?

---

## 7. HARDWARE RULES — ALWAYS RESPECT

| Tier | RAM | Models Available | Profiles Allowed |
|---|---|---|---|
| low | 8-15 GB | phi4, qwen2.5:7b, nomic-embed-text | core only |
| base | 16 GB | + mistral:7b-instruct-q4 | core + search |
| mid | 16-31 GB | + codestral:22b | + automation |
| high | 32+ GB | + llama3.3:70b | full |

**Never pull or schedule a model outside the hardware tier.**
**Never start heavy services on a low-tier machine.**
**Always read RAM tier from `.env` or detect at runtime — never hardcode.**

---

## 8. SECURITY RULES — ZERO EXCEPTIONS

1. **Gitleaks passes before every merge** — one real secret = PR blocked.
2. **Ollama is 127.0.0.1 only** — exposure requires documented security review.
3. **Qdrant gRPC (6334) stays unexposed.**
4. **OpenHands gate before docker.sock** — log every approval to `~/.wizard/audit.log`.
5. **No default secrets** — REQUIRED_CHANGE_ME fails loudly.
6. **nginx TLS mandatory** on internet-exposed deployments.
7. **fail2ban mandatory** when nginx is public.
8. **All .env values rotated on fresh install.**
9. **NEW — Behavioral PII policy:** stored preferences, style affinities, topic patterns,
   and interaction history are PII. They must be covered by the redact_fields list, subject
   to a documented retention limit, and deletable via the `memory_delete` gate with audit
   trail. See `docs/security/pii-policy.md` (to be created in P1).
10. **NEW — Supply chain integrity:** any binary downloaded by `install.sh` or any phase
    script must have its SHA-256 checksum verified before execution.
11. **NEW — IP disclosure gate:** before committing any file that describes novel system
    architecture or claim-level behavior, confirm with owner whether that content belongs
    in a private IP record rather than a public file.

---

## 9. THE INSTALLER — WHAT YOU MUST KNOW

The installer (`install.sh`) is the hardest single file in the repo. Known fragile points:
- `stat` flags differ between macOS (`-f`) and Linux (`-c`) — always branch
- `df` flags differ between macOS (`-g`) and Linux (`-BG`) — always branch
- `sed -i` requires backup suffix on macOS (`sed -i ''`) — always branch
- `launchctl` is macOS-only — Linux uses `systemctl`
- Model pull can fail on rate-limit — warn and continue, never abort
- `depends_on: ollama` was BUG-10/BUG-15 on macOS — use `host.docker.internal:11434`
- LiteLLM health check is `/health/readiness` (not `/health`)

**P0 requirement:** installer completes < 120 seconds on 8GB Mac with
`HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true`.

---

## 10. HOW MERLIN THINKS — THE PRODUCT NORTH STAR

Merlin is not a chatbot wrapper. Merlin is an AI command center that:

1. **Routes** — every task is classified by complexity and dispatched to the right model tier
2. **Remembers** — approved results are stored in Qdrant and retrieved to enrich future tasks
3. **Protects** — no task executes without policy evaluation; no memory writes without consent
4. **Explains** — every route decision, every memory write, every approval is logged and visible
5. **Recovers** — `wizard doctor` diagnoses the full stack; backup/restore is tested

The user's mental model:
> "I ask Merlin something. Merlin thinks about it locally, checks what it already knows,
> picks the right tool, and shows me what it did before writing anything to memory."

That is the v1 loop. Everything else is future.

---

## 11. PATENT ELEMENTS — KNOW THESE, PROTECT THESE

Five patent-pending elements are implemented in this codebase. Every one has a
conception date recorded in `docs/ip/INVENTOR_RECORD.md` (committed 2026-05-07).

| Element | Location | Key Invariant |
|---|---|---|
| 1 — Consent-Gated Preference Pipeline | `merlin/preference_extractor.py`, `merlin/policy_engine.py` | No preference reaches Qdrant without gate approval |
| 2 — Retrieval-Augmented Routing w/ Decay | `merlin/router.py` (routing logic) | Blending formula; NO_RETRAINING_CONSTRAINT |
| 3 — Negation Suppression Function | Issue #82 first evidence | Must-not-do filter applied before memory write |
| 4 — Four-Stage Session Reflection Pipeline | `merlin/session_reflector.py` | Isolated pipeline; no cross-contamination |
| 5 — MerlinFlow Self-Generating Workflow Engine | Issue #84 first evidence | Causal pruning; consent gate on workflow proposal |

**Codex rule:** if you are writing code that implements or extends any of these five
elements, note which element it implements in the module docstring and the commit message.
Format: `[Element-N: description]`

**Codex rule:** do NOT add implementation code for Element 5 until `merlin/magic/`
has a design document approved by owner. Element 5 currently has conception-date evidence
but no implementation — filing before implementation is correct; shipping before
design approval is not.

---

## 12. TEACHING MERLIN — HOW CODEX SHOULD LEARN THIS CODEBASE

When starting a new session, read in this order:
1. This file (CODEX_MASTER_PROMPT.md)
2. `docs/architecture/ARCHITECTURE_CHALLENGE.md`
3. `docs/ip/INVENTOR_RECORD.md` — know what is patent-protected
4. `CHANGELOG.md`
5. `ROADMAP.md`
6. `merlin/` — read `__init__.py` files first
7. `cli/wizard`
8. `configs/litellm/config.yaml`
9. `tests/` — what is tested and what is NOT

After reading, run:
```bash
wizard doctor
pytest merlin/ -v --tb=short --cov=merlin
```

If doctor shows 0 failures and pytest shows 58+ passing, repo is healthy.
Start work from the Section 1 verified queue unless the user explicitly assigns
a security/IP blocker from Section 4.

---

## 13. RESPONSE CONTRACT — HOW CODEX MUST BEHAVE

1. **Never fabricate file paths** — only reference verified files
2. **Never assume hardware tier** — always read from `.env` or detect at runtime
3. **Never bypass the gitleaks gate**
4. **Always write tests** — no new `merlin/` module without `tests/`, minimum 200 lines
5. **Always cross-platform** — every shell change works on macOS 14+ and Ubuntu 22+
6. **State what you are doing** — before each change: file, what changes, why, which
   patent element if applicable
7. **State what tests you ran** — list commands and output after each change
8. **Flag open items** — new gaps go into Section 4 immediately
9. **Never overbuild** — 20-line solution beats 200-line solution
10. **Respect Section 2 locks**
11. **NEW — IP gate:** before committing any file describing novel architecture,
    ask: "Does this belong in a public file or a private IP record?"
12. **NEW — Self-audit:** run the Section 6 self-audit checklist before writing
    any PR description

---

## 14. COMMIT TEMPLATE

```
type(scope): concise description [vX.Y or BUG-XX or Element-N]

What changed:
- bullet 1
- bullet 2

Why:
- one line rationale

Patent element: [Element-N: description] or N/A

Validated:
- wizard doctor: 0 failures
- pytest: XX passing, XX% coverage
- gitleaks: 0 detections
- platform: macOS 15 / Ubuntu 22
```

---

## 15. QUICK REFERENCE — KEY COMMANDS

```bash
# Install (non-interactive, skip model pulls — CI mode)
HOME_AI_NON_INTERACTIVE=true HOME_AI_SKIP_MODEL_PULLS=true bash install.sh

# Health check
wizard doctor

# Start / stop
wizard start && wizard stop

# Ask / swarm
wizard ask "what is my current swarm memory count?"
wizard swarm "summarize the last 5 memory entries"

# Memory ops
wizard swarm-status
wizard recall "security audit findings"

# Backup
wizard backup

# Debug
wizard debug

# Python tests with coverage
pytest merlin/ -v --tb=short --cov=merlin --cov-report=term

# Secret scan
gitleaks detect --source .

# E2E smoke
bash tests/e2e-test.sh

# Consent gate validation (after P0 test is written)
pytest tests/test_consent_gate.py -v

# Requirements install validation
python -m venv /tmp/merlin-venv && \
  /tmp/merlin-venv/bin/pip install -r requirements-merlin.txt && \
  /tmp/merlin-venv/bin/python -c "import merlin; print('OK')"
```

---

*This file is the single source of truth for Codex sessions on home-ai-elite.*
*Update Section 4 after completing any open item.*
*Update Section 2 after any stack change.*
*Last updated: 2026-05-07 by TheYfactora12 via Perplexity Elite Team Audit session.*
*Do NOT add novel patent claim language to this public file — use docs/ip/ instead.*
