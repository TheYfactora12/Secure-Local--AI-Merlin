# Dashboard Product Spec

## Product Goal

The Home AI Elite dashboard should become Merlin's local control center for non-technical users. It should explain what is running, what models are available, what profile is active, whether the system is local-only or online-enabled, and what actions Merlin is asking permission to perform.

The current dashboard is a useful static status page. It should not become a privileged control plane until a Merlin backend/policy layer exists.

Current implementation note: the dashboard now includes a read-only Merlin Control Status panel. It shows conservative local-only defaults, browser-observed service health, and CLI commands for authoritative status, approval review, and dry-run route previews. It does not execute approvals, shell commands, model downloads, memory writes, or service changes.

## Information Architecture

Main navigation:

1. Overview
2. Merlin Chat
3. Magic Mode
4. Models
5. Memory
6. Agents
7. Services
8. Security
9. Logs
10. Settings

## Screens

### 1. Overview

Purpose: answer "Is my local AI working?"

Content:

- Active install profile
- Hardware tier
- Local/online mode
- Core service health
- Model runtime status
- Memory status
- Read-only Merlin status with CLI-backed commands
- Latest warnings
- First recommended action

### 2. Merlin Chat

Purpose: normal assistant chat.

Features:

- Model/profile selector
- Local-only indicator
- Privacy badge per message
- Optional route details
- "Save to memory?" prompt after useful facts
- Error messages with next steps

MVP:

- Link to Open WebUI or embed a simple Merlin call after API exists.

### 3. Magic Mode

Purpose: computer-orchestration mode.

Flow:

1. User enters goal.
2. Merlin drafts plan.
3. UI displays steps, tools, risk level, and required approvals.
4. User approves one step, all low-risk steps, or cancels.
5. Live status shows current step and logs.
6. User can pause/stop.
7. Merlin summarizes completed actions and changes.

Required UI elements:

- Plan panel
- Approval queue
- Active agents
- Tool log
- Stop button
- Summary panel

MVP:

- Plan-only mode with no tool execution.
- Manual approval UI stub.

### 4. Models

Purpose: manage local and optional provider models.

Features:

- Installed Ollama models
- Suggested models for hardware tier
- Pull model button with size warning
- Current model loaded/running
- LiteLLM route aliases
- Optional provider status without showing secrets

MVP:

- List installed models.
- Show missing recommended models.
- Provide command copy text, not direct pulling, until policy exists.

### 5. Memory

Purpose: manage what Merlin knows.

Features:

- Memory collections
- Recent memory writes
- Pending memory approvals
- Search memory
- Delete memory
- Export memory
- Audit trail

MVP:

- Show Qdrant collection status.
- Explain that approved memory schema is pending.

### 6. Agents

Purpose: show optional agent capabilities.

Agents:

- Planner
- Researcher
- Coding
- File/Document
- Security Reviewer
- Personal Assistant future agent

MVP:

- Show which profiles enable each agent.
- Warn when coding/automation profiles are off.

### 7. Services

Purpose: start/stop and troubleshoot services safely.

Services grouped by profile:

- Core
- Search
- Automation
- Coding
- Security
- Ops

MVP:

- Status only.
- Start/stop buttons later after Merlin backend exists.

### 8. Security

Purpose: make privacy and risk clear.

Features:

- Local-only/online mode toggle
- Provider key status
- Port exposure warning
- Signup/auth status
- Approval settings
- Tool permissions
- Recent denied actions

MVP:

- Show local-only status and warnings.
- Do not display secret values.

### 9. Logs

Purpose: explain failures.

Content:

- Install log pointer
- Service health log
- Merlin decisions
- Magic Mode actions
- Recent errors
- Downloadable debug report

### 10. Settings

Purpose: configure profile and safe preferences.

Settings:

- Install profile
- Hardware tier override
- Online mode
- Provider enablement
- Model preferences
- Memory save policy
- Approval policy
- Backup schedule

## User Flows

### First Run

1. User opens dashboard.
2. Dashboard detects core services.
3. Shows hardware tier and profile.
4. Prompts user to create Open WebUI admin account.
5. Shows optional next steps: enable search, automation, or coding.

### Add Local Model

1. User opens Models.
2. Dashboard shows recommended models for tier.
3. User selects model.
4. UI shows size/time/RAM warning.
5. User confirms.
6. System runs approved pull through backend or shows command in MVP.

### Add Cloud Provider

1. User opens Security or Models.
2. Selects provider.
3. Dashboard explains data leaves device when enabled.
4. User stores key through secure backend or edits `.env` in MVP.
5. Provider remains disabled until user turns online mode on.

### Magic Mode

1. User enters goal.
2. Merlin generates plan.
3. UI shows risk and approvals.
4. User approves step by step.
5. UI logs actions.
6. User can stop.
7. Merlin summarizes results.

## Admin/Security Settings

Required:

- Online mode disabled by default.
- Cloud provider enablement requires explicit user action.
- Memory writes require approval by default.
- Shell/file/network actions require approval.
- Dashboard never prints secrets.
- LAN exposure shows warning.

## MVP vs Later Features

### MVP

- Status overview
- Hardware tier display
- Profile display
- Installed models list
- Local-only indicator
- Service links
- Basic logs
- Warnings for missing Docker/Ollama/models

### Later

- Merlin backend API
- Safe start/stop controls
- Secure API key manager
- Magic Mode execution UI
- Memory approval and deletion UI
- Agent activity timeline
- Backup/restore UI
- Performance metrics
- Multi-user access control
