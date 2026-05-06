# launchd — macOS Auto-Start Agents

These `.plist` files make your home-ai-elite stack **start automatically on macOS login** — no manual Docker Desktop launch, no terminal commands.

## How launchd Works

- **LaunchAgents** run when YOU log in (user-level, correct for Docker Desktop)
- Files live in `~/Library/LaunchAgents/`
- `launchctl bootstrap` registers them once — they survive reboots forever after
- Reference: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html

## What's Included

| File | What it starts | Delay |
|------|---------------|-------|
| `com.homeai.docker.plist` | Docker Desktop | 5s after login |
| `com.homeai.stack.plist` | Laptop-safe core profile (`wizard start core`) | 30s after login (waits for Docker) |
| `com.homeai.merlin-status-api.plist` | Read-only Merlin status API (`scripts/merlin-status-api.sh run`) | 35s after login |

## Install (run once)

```bash
bash ~/home-ai-elite/launchd/install-launchd.sh
```

This installs only the Docker Desktop opener, the core-profile stack starter,
and the read-only Merlin status API used by the dashboard.
Search, automation, coding, security, and ops profiles still require explicit
manual start commands.

## Uninstall

```bash
bash ~/home-ai-elite/launchd/install-launchd.sh --uninstall
```

## Verify

```bash
# Check agents are loaded
launchctl list | grep homeai

# Check logs
tail -f /tmp/homeai-docker.log
tail -f /tmp/homeai-stack.log
tail -f /tmp/homeai-merlin-status-api.log

# Check the read-only Merlin status API
wizard merlin status-api status
```
