# pkg — macOS .pkg Installer

Builds a double-click `.pkg` installer for merlin-ai using Apple's native `pkgbuild` + `productbuild` toolchain.

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
# Preflight local release prerequisites
bash pkg/release-preflight.sh

# Unsigned (local testing)
bash pkg/build-pkg.sh

# Install locally from Terminal with a clear macOS password prompt
bash scripts/install-pkg-local.sh

# Local self-signed package (trusted/private testing)
bash scripts/sign-pkg.sh --version <version>

# Signed with Developer ID (no Gatekeeper warning; future public distribution)
bash pkg/build-pkg.sh --sign

# Signed + notarized (ready for public distribution)
bash pkg/build-pkg.sh --sign --notarize
```

Output: `merlin-ai-<version>.pkg` in the repo root.

## Install Flow (what happens when user double-clicks)

1. macOS Installer.app shows Welcome + Readme screens
2. `preinstall` runs: checks macOS ≥13, RAM ≥8GB, disk ≥20GB, Docker Desktop installed, git installed
3. If all checks pass: files copied to `/usr/local/merlin-ai`
4. `postinstall` runs:
   - Copies stack to `~/merlin-ai`
   - Creates `.env` from `.env.example`
   - Opens Docker Desktop so the user can finish first-run setup
   - Launches `install.sh --profile core --skip-model-pulls --non-interactive` in background
   - Installs launchd auto-start agents
   - Drops a **Next Steps** file on the Desktop
5. Done — services start automatically after Docker Desktop is running, user opens `http://localhost:3000`

## Docker Desktop Caveat

The package does not bundle Docker Desktop. Users should install and open Docker
Desktop before running Merlin AI. If Docker Desktop is installed without
shell symlinks, the installer uses Docker's bundled CLI at:

```bash
/Applications/Docker.app/Contents/Resources/bin/docker
```

## Local Self-Signed Package

The v1.0 path supports local/self-signed packages for trusted private testing.
This avoids requiring a paid Apple Developer Program account before the product
is ready for broad public distribution.

The local identity must be usable by `productsign` as an installer-signing
identity. A normal application Code Signing certificate is not enough for flat
`.pkg` products.

One working command-line path is:

```bash
mkdir -p /private/tmp/merlin-ai-installer-signing

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.key \
  -out /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.crt \
  -subj "/CN=Merlin AI Local Signing/O=Merlin AI/C=US" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=1.2.840.113635.100.6.1.14"

openssl pkcs12 -legacy -export \
  -inkey /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.key \
  -in /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.crt \
  -out /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.p12 \
  -passout pass:homeai-local-import

security create-keychain -p homeai-build \
  /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.keychain
security unlock-keychain -p homeai-build \
  /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.keychain
security import /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.p12 \
  -k /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.keychain \
  -P homeai-local-import \
  -T /usr/bin/productsign
security add-trusted-cert -r trustRoot \
  -k /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.keychain \
  /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.crt

# Trust it for current-user package verification on this Mac.
security add-trusted-cert -r trustRoot \
  -k "$HOME/Library/Keychains/login.keychain-db" \
  /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.crt
```

Then build and sign:

```bash
bash pkg/build-pkg.sh
security unlock-keychain -p homeai-build \
  /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.keychain
bash scripts/sign-pkg.sh --version <version> \
  --keychain /private/tmp/merlin-ai-installer-signing/home-ai-installer-signing.keychain
pkgutil --check-signature merlin-ai-v<version>.pkg
```

macOS may still show an unidentified-developer warning for self-signed
packages. For trusted local testing, right-click the `.pkg`, choose Open, and
confirm the prompt. This is expected for the self-signed path.

## Developer ID Signing & Notarization

Requires an Apple Developer account ($99/year).

```bash
export DEVELOPER_ID_INSTALLER="Developer ID Installer: Your Name (TEAMID)"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOURTEAMID"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password

bash pkg/release-preflight.sh --require-signing
bash pkg/build-pkg.sh --sign --notarize
```

The preflight does not print secret values. It checks local package tools,
Developer ID Installer identity availability, and required notarization
environment variables.

## Uninstall

```bash
bash ~/merlin-ai/pkg/scripts/uninstall.sh
```

Default removes: containers, launchd agents, install directory, pkgutil receipt.
Default keeps: Docker Desktop, Homebrew, Ollama models, Docker volumes, and a timestamped `.env` backup.

Clean-reset uninstall:

```bash
bash ~/merlin-ai/pkg/scripts/uninstall.sh --remove-data
```

Full Merlin purge for a clean reinstall test:

```bash
bash ~/merlin-ai/pkg/scripts/uninstall.sh --purge-all
```

This removes Merlin app files, Docker containers, Docker volumes, Docker images
used by the stack, and known Merlin-recommended Ollama models. It still keeps
system dependencies: Docker Desktop, Homebrew, and the Ollama app/binary.

Dependency-aware removal:

```bash
bash ~/merlin-ai/pkg/scripts/uninstall.sh --dry-run --purge-dependencies
bash ~/merlin-ai/pkg/scripts/uninstall.sh --purge-dependencies --i-understand-shared-tools
```

Merlin writes `~/.merlin/install-manifest.json` during install. Dependency
purge uses that manifest and only removes shared tools marked as installed by
Merlin. Docker Desktop, Ollama, and Homebrew may be used by other apps, so this
path is intentionally explicit and should be previewed first.

Preview first:

```bash
bash ~/merlin-ai/pkg/scripts/uninstall.sh --dry-run
```
