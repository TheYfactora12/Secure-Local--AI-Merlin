# Phase 3 Stress Test — Learning Loop

Date: 2026-05-06

Scope:

- Phase 3A outcome observer
- Phase 3B retrieval-augmented routing
- Phase 3C preference extractor
- Phase 3D session reflector
- Phase 3E skill scores and router skill bias

## Result

Phase 3 is structurally sound after one safety fix.

The learning loop remains local-first, review-first, and approval-gated:

- Raw user input is stored as hashes in outcome records.
- Preference extraction is review-only.
- Session reflection is review-only unless preview logging is explicitly called.
- Skill score writes require an approval id.
- Skill reports are recomputed read-only from local Qdrant.
- Skill bias is advisory and non-blocking.
- Qdrant/scorer failures degrade without breaking routing.

## Critical Finding Fixed

Stress testing found that skill bias could change a safe route's `agent_target`
to a higher-risk target such as `openhands` or `n8n` without adding that target's
approval gates or required profile.

Fix:

- Skill bias now applies only to safe internal targets: `litellm` and
  `merlin-core`.
- `openhands` and `n8n` remain available through normal route classification and
  approval-gated routes, not statistical skill bias.
- Tests now prove safe general routes cannot be biased into `openhands` or `n8n`.

Tracking issue: #71

## Validation

Commands run:

```bash
.venv-test/bin/python -m pytest tests/test_router.py tests/test_router_skill_bias.py -v --tb=short
.venv-test/bin/python -m pytest tests/ --ignore=tests/test_memory_manager_integration.py -v --tb=short --no-header -q
MERLIN_PYTHON=.venv-test/bin/python bash cli/wizard skills
MERLIN_PYTHON=.venv-test/bin/python bash scripts/doctor.sh
```

Results:

- Router + skill-bias tests: 40 passed.
- Full offline Python suite: 152 passed.
- `wizard skills`: printed a score table and degraded to zero outcomes cleanly.
- `wizard doctor`: 38 passed, 13 warnings, 0 failures.

Doctor warnings were expected in this shell:

- Docker unavailable.
- Ports 8765 and 8766 closed.
- Optional search, automation, and coding profiles disabled.

## Architecture Stress Notes

Validated:

- Retrieval score only uses approved outcome history.
- Preference extractor does not write memory.
- Session reflector does not write memory unless explicit preview logging is
  called.
- Skill scoring does not create persistent score files.
- Skill bias does not authorize execution, cloud calls, shell commands, file
  writes, memory writes, or model downloads.

Rejected for now:

- Session abandonment scoring. The current code does not produce abandonment
  signals.
- Preference-agent affinity. The current preference extractor does not expose
  preferred agents per domain.
- Delegation correction. The current swarm coordinator is a pure adapter and
  does not record handoffs.
- Model-aware skill scores. Outcome records do not yet reliably include the
  selected model alias.

Those ideas are documented as future signal-audit candidates in
`docs/MERLIN_PHASE3_LEARNING_PLAN.md`.

## Remaining Risks

- `skill_outcomes` is created dynamically and is not yet part of the canonical
  memory manifest. This is acceptable for Phase 3E but should be revisited
  before a packaged release.
- Skill bias currently changes only `agent_target`, not `selected_agent` or
  `required_profile`. Because risky targets are blocked from bias, this is
  acceptable now. If future bias is allowed to affect higher-risk execution
  targets, it must recompute approval gates and profile requirements.
- Live Qdrant behavior still needs an integration pass with real approved
  outcome writes.

## Recommendation

Do not add more learning behavior until Phase 3 is tested end-to-end with the
local stack running.

Recommended next validation:

1. Start core stack.
2. Run `wizard skills`.
3. Execute a local `/task` success path.
4. Record an approved outcome.
5. Confirm `skill_outcomes` point creation.
6. Confirm `wizard skills` reads a non-zero outcome count.
7. Confirm safe routes cannot be skill-biased into `openhands` or `n8n`.
