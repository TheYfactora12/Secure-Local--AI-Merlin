# Roadmap Stress Test — 2026-05-06

## Verdict

The plan is directionally sound, but the project must resist two kinds of drift:

1. Overbuilding Merlin before the installer is release-stable.
2. Older documentation describing cloud fallback, 16GB minimum RAM, or stale service ports as if they are current policy.

The current sequence should be:

1. Finish `v1.0 — Stable Installer Release`.
2. Add safe optional access/docs in `v1.1`.
3. Clean up hardware/document-ingestion guidance in `v1.2`.
4. Continue reliability/router/memory work in `v1.3`.
5. Defer advanced memory benchmarks, observability, Magic Mode, and public release polish until the lower milestones are green.

## What Stays

- Keep `install.sh` as the protected install path.
- Keep Open WebUI as the primary chat UI.
- Keep Ollama, LiteLLM, Qdrant, n8n, SearXNG, Perplexica, and OpenHands as wrapped services, not rebuilt internals.
- Keep `configs/merlin/` as the canonical Merlin config root.
- Keep Magic Mode plan-first and approval-gated.
- Keep cloud/API behavior off by default.
- Keep 8GB Mac support scoped to low/core mode. 8GB is the entry point, not the full-stack target.

## What Changes

- `v1.1` and `v1.2` milestones now exist in GitHub; the roadmap no longer jumps from `v1.0` to `v1.3`.
- Issue #5 moved to `v1.2` because it is hardware/docs/document-ingestion planning, not router reliability.
- Issue #47 created for `v1.1` mobile/remote-safe entry point planning.
- Missing version labels were added for `v1.1`, `v2.1`, `v2.2`, and `v3.0`.
- Older failure-map docs were marked as legacy where they conflict with current 8GB-first/local-first policy.

## Redundancy Found

There are two failure-map documents:

- `docs/FAILURE_MAP.md`
- `docs/failure-map.md`

They overlap but are not identical. The lowercase file contains useful older research and version targets, but it had stale implementation claims. It should be treated as a legacy research note. The canonical active planning sources are:

- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FRESH_INSTALL_MAC_TEST_2026-05-06.md`
- `docs/CODEX_START_NEXT_STEP_PROTOCOL.md`
- GitHub milestones/issues

## Drift Removed

- The plan no longer implies 16GB is the minimum supported RAM. Current policy is 8GB as the entry point in low/core mode, with conservative services and model recommendations.
- The plan no longer treats automatic cloud fallback as acceptable default behavior.
- The plan no longer treats mobile/LAN access as a default install behavior; it is `v1.1` opt-in planning only.
- The plan no longer treats document ingestion as a `v1.3` router/reliability task; it is now `v1.2`.

## Current Execution Queue

1. Rerun full fresh uninstall/install from current `main`.
2. Close or update `v1.0` release issue #1 only after fresh install, package, upgrade, backup, restore, and uninstall checks are green.
3. Start #47 only after `v1.0` is release-stable, unless it is docs-only and does not touch installer defaults.
4. Rewrite #5 against current 8GB-first hardware tiers.
5. Then return to `v1.3` reliability/router/memory issues.

## Do Not Do Yet

- Do not make mobile/LAN access default.
- Do not add autonomous Magic Mode execution.
- Do not add cloud routing as fallback behavior.
- Do not add heavy document-ingestion containers to the core profile.
- Do not replace Open WebUI with a custom chat UI.
- Do not close `v1.0` until a second fresh install validates the fixes from #41 through #46 together.
