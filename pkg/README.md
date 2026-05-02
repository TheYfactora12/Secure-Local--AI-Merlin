# pkg — macOS .pkg Installer

Builds a double-click `.pkg` installer for home-ai-elite using Apple's native `pkgbuild` + `productbuild` toolchain.

## Structure

```
pkg/
├── build-pkg.sh           # Main build script
├── scripts/
│   ├── preinstall          # Runs before files are copied (preflight checks)
│   ├── postinstall         # Runs after files are copied (launches install.sh)
│   └── uninstall.sh        # Full uninstaller (bundled inside the pkg)
├── resources/
│   ├── welcome.html        # Welcome screen shown in macOS Installer.app
│   └── readme.html         # Post-install next steps shown in Installer.app
└── build/                  # Generated during build (gitignored)
```

## Build

```bash
# Unsigned (local testing)
bash pkg/build-pkg.sh

# Signed with Developer ID (no Gatekeeper warning)
bash pkg/build-pkg.sh --sign

# Signed + notarized (ready for public distribution)
bash pkg/build-pkg.sh --sign --notarize
```

Output: `home-ai-elite-<version>.pkg` in the repo root.

## Install Flow (what happens when user double-clicks)

1. macOS Installer.app shows Welcome + Readme screens
2. `preinstall` runs: checks macOS ≥13, RAM ≥8GB, disk ≥20GB, Docker installed, git installed
3. If all checks pass: files copied to `/usr/local/home-ai-elite`
4. `postinstall` runs:
   - Copies stack to `~/home-ai-elite`
   - Creates `.env` from `.env.example`
   - Launches `install.sh` in background (pulls Docker images, starts services)
   - Installs launchd auto-start agents
   - Drops a **Next Steps** file on the Desktop
5. Done — services start automatically, user opens `http://localhost:3001`

## Signing & Notarization

Requires an Apple Developer account ($99/year).

```bash
export DEVELOPER_ID_INSTALLER="Developer ID Installer: Your Name (TEAMID)"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOURTEAMID"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password

bash pkg/build-pkg.sh --sign --notarize
```

## Uninstall

```bash
bash ~/home-ai-elite/pkg/scripts/uninstall.sh
```

Removes: containers, volumes, launchd agents, install directory, pkgutil receipt.
Keeps: Docker Desktop, Homebrew, Ollama models.
