# Installer Notes

These are packaging notes captured while testing from a downloaded
`home-ai-elite-main` archive on macOS.

## Observed Friction

- The downloaded archive is not a Git checkout, so `git status`, branch updates,
  and direct pushes are not available until the folder is connected to a repo.
- Docker Desktop may install through Homebrew only with `--no-binaries` on
  machines where `/usr/local/cli-plugins` requires sudo. In that case the Docker
  CLI still exists at `/Applications/Docker.app/Contents/Resources/bin/docker`.
- The installer cannot assume Docker Desktop is already running. First launch may
  require a GUI approval/setup flow from the user.
- Running the interactive installer from a `.pkg` postinstall script can hang on
  hidden API-key prompts or optional setup prompts.
- The package next-step text had stale service ports.

## Changes Made

- `install.sh` now supports `--non-interactive` and `--skip-model-pulls`.
- `install.sh` and `scripts/bootstrap.sh` now discover Docker's bundled CLI when
  shell symlinks were not created.
- `pkg/scripts/postinstall` now runs `install.sh --non-interactive`, opens Docker
  Desktop, and writes current service URLs to the Desktop next-steps file.
- `pkg/scripts/preinstall` now verifies Docker's bundled CLI inside Docker.app.

## GitHub Shipping Checklist

- Convert the local archive into a real Git checkout or copy these changes into
  the canonical repo.
- Build an unsigned package locally with `bash pkg/build-pkg.sh`.
- Test the `.pkg` on a clean macOS user account with Docker Desktop installed but
  not yet running.
- Decide whether public distribution should require users to install Docker
  Desktop first, or whether the installer should download Docker Desktop during
  setup after explicit consent.
- For broad distribution, sign and notarize with:

```bash
bash pkg/build-pkg.sh --sign --notarize
```
