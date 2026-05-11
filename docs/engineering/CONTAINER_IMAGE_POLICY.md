# Container Image Policy

Merlin AI is local-first software. Container updates must not silently change
the laptop-safe core in a way that breaks first boot, exposes ports, or starts
heavy services.

## Release Rule

Every container image used by the repo must meet one of these conditions:

1. It is pinned to a specific version tag or digest.
2. It uses a floating tag only because upstream packaging makes pinning
   impractical for now, and the image is listed in the floating-image register
   below with a review policy.

Do not add a new `latest`, `main`, `main-latest`, or moving distro tag without
adding it to this file and explaining the release risk.

## Update Rules

- Core images must be validated by `tests/core-live-smoke.sh` before a stable
  release.
- Optional profile images must be validated by the matching profile smoke test
  before that profile is marked stable.
- Watchtower must remain opt-in/profile-gated and label-scoped. It must not
  become part of the default core profile.
- A tagged GitHub release should use the tested repository revision and attach
  the package artifact produced from that revision.
- If a floating image causes a regression, pin it in the next patch instead of
  working around the failure in installer code.

## Floating-Image Register

| Image | File | Profile / service | Current reason | Required validation before stable |
|---|---|---|---|---|
| `nginx:alpine` | `docker-compose.yml` | dashboard, security proxy | Small static server image; used only for local dashboard/proxy. | Core live smoke for dashboard; security profile smoke before proxy is stable. |
| `crazymax/fail2ban:latest` | `docker-compose.yml` | security | Optional Linux-only service, not macOS core. | Linux security profile smoke before stable server release. |
| `containrrr/watchtower:latest` | `docker-compose.yml` | ops | Optional updater. Keeping moving tag is acceptable only while ops remains opt-in. | Ops profile smoke and rollback test before stable server release. |
| `ollama/ollama:latest` | `docker-compose.yml` | Linux Docker Ollama | macOS uses native Ollama; Docker image is optional Linux path. | Linux core smoke before Linux release. |
| `ghcr.io/berriai/litellm:main-latest` | `docker-compose.yml` | core model gateway | Upstream image is commonly published from main. High-risk core dependency. | Core live smoke plus model gateway completion test before release. Pin when a known-good version tag is available. |
| `ghcr.io/open-webui/open-webui:main` | `docker-compose.yml` | core chat UI | Upstream main image used by prototype. High-risk UI dependency. | Core live smoke before release. Pin after clean package test. |
| `searxng/searxng:latest` | `docker-compose.yml` | search | Optional search profile. | Search profile live smoke before search is marked stable. |
| `itzcrazykns1337/perplexica-backend:main` | `docker-compose.yml` | search | Optional search prototype image. | Search profile live smoke and query quality checks. |
| `itzcrazykns1337/perplexica-frontend:main` | `docker-compose.yml` | search | Optional search prototype image. | Search profile live smoke and browser check. |
| `ghcr.io/all-hands-ai/openhands:main` | `docker-compose.yml` | coding | Optional coding profile with Docker socket access. | Coding profile smoke and security approval gates before stable. |
| `qdrant/qdrant:latest` | `docker-compose.yml` | core vector memory | Prototype uses latest. Core storage dependency, so pinning is preferred before stable v1. | Core live smoke plus Qdrant backup/restore smoke before release. |
| `docker.io/langfuse/langfuse:3` | `docker-compose.observability.yml` | optional observability | Self-hosted Langfuse web UI. Off by default and profile-gated. | `tests/langfuse-observability-profile-smoke.sh`; live profile smoke before marking observability stable. |
| `docker.io/langfuse/langfuse-worker:3` | `docker-compose.observability.yml` | optional observability | Self-hosted Langfuse ingestion worker. Off by default and profile-gated. | `tests/langfuse-observability-profile-smoke.sh`; live profile smoke before marking observability stable. |
| `docker.io/clickhouse/clickhouse-server:latest` | `docker-compose.observability.yml` | optional observability | Langfuse event store. Heavy service, never default on 8GB/core. | Static profile-gating smoke now; pin after successful live observability validation. |
| `cgr.dev/chainguard/minio:latest` | `docker-compose.observability.yml` | optional observability | Local S3-compatible object store for Langfuse. | Static profile-gating smoke now; pin after successful live observability validation. |
| `docker.io/redis:7` | `docker-compose.observability.yml` | optional observability | Langfuse queue/cache dependency. Major tag used to avoid latest. | Static profile-gating smoke now; live profile smoke before stable. |
| `docker.io/postgres:17` | `docker-compose.observability.yml` | optional observability | Langfuse metadata store. Major tag used to avoid latest. | Static profile-gating smoke now; live profile smoke before stable. |
| `ghcr.io/open-webui/open-webui:main` | `docker-compose.base.yml` | legacy sample | Legacy compose sample, not default installer path. | Keep out of release docs or replace with current profile-aware stack. |
| `qdrant/qdrant:latest` | `docker-compose.base.yml` | legacy sample | Legacy compose sample, not default installer path. | Keep out of release docs or replace with current profile-aware stack. |
| `docker.n8n.io/n8nio/n8n:latest` | `docker-compose.base.yml` | legacy sample | Legacy compose sample, not default installer path. Current main stack pins n8n. | Keep out of release docs or replace with current profile-aware stack. |
| `docker.all-hands.dev/all-hands-ai/openhands:latest` | `docker-compose.openhands.yml` | legacy coding sample | Legacy sample; current main stack uses profile-gated OpenHands. | Keep out of release docs or replace with current profile-aware stack. |
| `docker.all-hands.dev/all-hands-ai/runtime:latest` | `docker-compose.openhands.yml` | legacy coding sample | Legacy sample runtime image. Main stack pins runtime to `0.38-nikolaik`. | Keep out of release docs or replace with current profile-aware stack. |

## Pinning Priority

1. `qdrant/qdrant` because it stores local memory.
2. `ghcr.io/berriai/litellm` because it is the model gateway.
3. `ghcr.io/open-webui/open-webui` because it is the default chat UI.
4. Search profile images after search live validation.
5. Coding/security/ops profile images after their approval gates exist.
