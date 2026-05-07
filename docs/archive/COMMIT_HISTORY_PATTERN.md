# Commit History Pattern

This note captures the earliest repository history pattern for later roadmap,
release, and provenance documentation.

Command used:

```bash
git log --reverse --format="%ad %H %s" --date=short | head -5
```

Output captured on 2026-05-06:

```text
2026-04-30 8165e89acf3edfaaddb764237141e1922c7c15db Initial commit
2026-04-30 3a86e59e467a8edf131df158069264575d4df6e3 feat: initial home-ai-elite interactive installer scaffold
2026-05-02 17bb8041981c9a71aad35b244722dc2123afd70d feat: v0.2 — full stack build (Perplexica, SearXNG, LiteLLM, OpenHands, unified compose, RAM-aware install)
2026-05-02 5164de9a984b10eca375df354aa51a3b6765680f v0.3 — Qdrant init, n8n workflow auto-import, macOS launchd auto-start
2026-05-02 bbde756c76554851d2e2846ebe1e6a4d29a1d90c v0.4 — GitHub Actions CI + upgrade script with rollback + auto-release
```

Associated pattern:

- `Initial commit` established the repository baseline.
- `feat: initial home-ai-elite interactive installer scaffold` started the protected installer lineage.
- `v0.2` expanded the project into the full local AI stack.
- `v0.3` added memory initialization, n8n import, and macOS launchd persistence.
- `v0.4` introduced CI, upgrade flow, rollback behavior, and release automation.

Use this pattern when documenting how Home AI Elite evolved from installer
scaffold into local AI stack, then into release-managed infrastructure.
