> Moved from `docs/MERLIN_V1_MVP.md` on 2026-05-06.

# Merlin V1 MVP

Last updated: 2026-05-08

## Current MVP Boundary

Merlin v1 is local-first, policy-gated, and visibility-first.

Included:

- protected installer and uninstall/upgrade paths
- Wizard HQ read-only dashboard
- Merlin status API on port 8765 and task/status API on port 8766
- route/status/approval/memory visibility
- plan-only Magic Mode
- redacted local audit viewer
- approved memory write/search boundaries
- 8GB low/core path

Not included:

- autonomous computer control
- browser-driven approval/deny controls
- automatic cloud routing
- automatic model downloads
- background agents
- Magic Mode execution
- native workflow runtime replacement for n8n

## Magic Mode MVP

Magic Mode v1 is useful when it can show a safe plan and tell the truth about
what would require approval. It is not useful if it pretends to execute.

MVP success means:

- `wizard merlin magic plan "goal"` clearly says `plan_only`
- risky steps show approval gates and required tools
- plan records are local JSONL and redacted
- `wizard merlin audit list` shows route, approval, memory, outcome, and Magic
  summaries without raw prompts or sensitive values
