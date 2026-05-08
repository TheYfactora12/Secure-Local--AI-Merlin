# Merlin Staff Skill Evaluation

Last updated: 2026-05-08

Issue: #85

## Decision

Do not add a seventh staff mode yet. Keep the six staff modes as the v1/v2
runtime contract and add future skills first as aliases, dashboard workflows, or
review templates that route through the existing staff modes and policy gates.

The first candidate worth implementing later is **Compliance Officer** as a
Security Reviewer workflow, not as a new autonomous staff mode. This matches the
user's security-risk domain, adds immediate value, and does not increase router
ambiguity.

## Current Six-Mode Baseline

| Staff mode | Keep as | Why it remains enough for v1/v2 |
| --- | --- | --- |
| `architect` | Core mode | Covers system design, roadmap tradeoffs, and service boundaries. |
| `ai_engineer` | Core mode | Covers model routing, embeddings, RAG, evals, and memory intelligence. |
| `software_engineer` | Core mode | Covers installer, scripts, tests, CI, and maintainable code. |
| `security_reviewer` | Core mode | Covers secrets, policy gates, threat model, audit, and compliance review. |
| `product_designer` | Core mode | Covers dashboard, onboarding, and non-technical user flows. |
| `operator` | Core mode | Covers install, health checks, upgrades, backups, logs, and profiles. |

Adding more top-level staff modes now would make routing harder and create a
larger prompt surface before the existing modes have enough live outcome data.

## Candidate Evaluation

| Candidate | User value | Recommended shape | Owning mode | Policy gates | 8GB-safe behavior |
| --- | --- | --- | --- | --- | --- |
| Data Analyst | Interpret local CSVs, reports, and tables. | Dashboard workflow, later optional alias. | `ai_engineer` + `software_engineer` | `file_read`, `memory_write` if storing findings, `external_network` only for opt-in data fetch. | Local file summaries only, small samples, no background indexing. |
| Compliance Officer | Map findings to policies, evidence, and risk language. | **First implementation candidate: Security Reviewer workflow/alias.** | `security_reviewer` | `file_read`, `secret_access` if sensitive evidence, `memory_write` for approved findings, `external_network` only for current guidance lookup. | Local docs and user-provided evidence only; no live web unless approved. |
| Support Technician | Guide installer, doctor, remediation, and logs. | Operator workflow/alias. | `operator` | `file_read` for logs, `service_start`/`service_stop` only after approval, `shell_command` for remediation. | Read-only diagnostics first; no automatic fixes. |
| Research Librarian | Organize citations and local-first research notes. | Search workflow/alias. | `ai_engineer` + `operator` | `external_network`, `cloud_model_call` if cloud provider is requested, `memory_write` for approved bibliography memory. | Local notes first; search profile only when user starts it. |
| Finance/Operations Analyst | Budget, planning, and operational reports. | Dashboard workflow, not a staff mode. | `architect` + `operator` | `file_read`, `memory_write`, `external_network` only for explicitly approved account/data access. | Manual/local inputs only; no bank/account/API integrations by default. |

## What Should Not Become A New Mode Yet

- Data Analyst should not be a new mode until document ingestion and local table
  handling are stable.
- Support Technician should stay under Operator because remediation must remain
  tied to installer, doctor, and service gates.
- Research Librarian should stay a workflow because search already has a route
  and high-risk approval gates.
- Finance/Operations Analyst should not ship as a mode until the product has
  explicit account-access policy and redaction rules.

## Recommended First Skill Slice

Implement **Compliance Officer** as a Security Reviewer workflow/alias.

Scope for the later implementation issue:

- Add a prompt/workflow template for compliance review that routes to
  `security_reviewer`.
- Inputs: local policy excerpt, finding text, evidence summary, desired standard
  such as FFIEC, NCUA, NIST, GLBA, SOC 2, or internal policy.
- Outputs: risk statement, evidence gaps, control mapping, remediation plan, and
  approval-gated memory proposal.
- No new staff mode.
- No autonomous execution.
- No cloud/current-guidance lookup unless the user approves `external_network`
  and the search route gates.

Policy gates:

- `file_read` for local evidence or policy documents.
- `secret_access` when evidence may contain credentials or sensitive account
  data.
- `memory_write` before storing findings, mappings, or user preferences.
- `external_network` and `cloud_model_call` only when the user explicitly asks
  for current external guidance or a cloud model.

8GB behavior:

- Use existing low-memory fallback model behavior.
- Limit context to focused excerpts instead of bulk document ingestion.
- Prefer plan/review output over background indexing.
- Do not start search, automation, coding, or observability profiles
  automatically.

Tests for the later implementation issue:

- Routing remains `security_reviewer` for compliance-review inputs.
- Approval gates include `file_read` and `secret_access` when evidence is
  referenced.
- No memory write occurs without approval.
- Low-memory routing uses the configured fallback model.

Rollback:

- Remove the Compliance Officer workflow/template.
- Keep the six staff modes unchanged.
- No data migration required if memory writes remain approval-gated.

## Product Rule

New skills must prove user value as workflows or aliases before becoming staff
modes. A new top-level mode requires evidence from route outcomes, user
feedback, and dashboard usage that the existing six-mode contract cannot
express the work clearly.
