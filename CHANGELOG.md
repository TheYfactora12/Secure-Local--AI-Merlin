# Changelog

All notable changes to Merlin AI are documented here.

## Unreleased

### Changed

- Renamed active product copy to **Merlin AI**.
- Updated the product tagline to **Your private AI. On your Mac. Forever.**
- Rewrote the README for non-technical macOS users.
- Reset the roadmap to the five v1.0 focus areas: install, privacy,
  onboarding, uninstall, and open-source credibility.
- Added `docs/CODEX_MASTER_PROMPT_V3.md` as the current Codex session anchor.
- Added future-scope parking docs for non-v1.0 ideas.
- Updated installer, package welcome/readme, postinstall next steps, dashboard,
  workflow, and smoke-test copy to the Merlin AI naming.
- Added a 2026-05-12 #95 product-push evidence rollup and refreshed the Trusted
  Local Beta evidence pack with current package/onboarding verification status.
- Filled the release evidence table with the current named package/onboarding
  verification run and marked remaining beta-signoff gaps explicitly.
- Added local-image restart validation evidence for the offline-launch row,
  while keeping true network-disconnected launch as a beta-signoff blocker.
- Added Magic Mode and audit validation evidence showing plan-only behavior,
  local redacted audit output, and no model/memory/service/tool/cloud execution.
- Added network-disconnected launch validation evidence showing core services
  restart from local images with Wi-Fi off, plus the remaining no-local-model UX
  gap.

### Notes

- Developer ID signing/notarization remains deferred until the product surface
  and local install evidence are complete.
- Internal `HOME_AI_*` environment variables and `com.homeai.*` launchd labels
  remain compatibility identifiers for now and require a dedicated migration
  issue before renaming.

## 1.0.0 — 2026-05-06

### Added

- Local AI installer with profile-aware startup.
- Native Ollama path for macOS Apple Silicon.
- Core local services: dashboard, Open WebUI, LiteLLM, Qdrant, and Ollama.
- Optional profiles for search, automation, coding, security, and operations.
- Local-first/no-cloud default posture.
- Installer, package, and uninstall smoke tests.

### Known Limits

- Clean install evidence must be refreshed after the Merlin AI naming reset.
- Public beta and public release are not claimed.
