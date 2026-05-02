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
| `com.homeai.stack.plist` | All AI services (docker compose up) | 30s after login (waits for Docker) |

## Install (run once)

```bash
bash ~/home-ai-elite/launchd/install-launchd.sh
```

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
```
