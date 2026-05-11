#!/usr/bin/env bash
# =============================================================================
# build-pkg.sh — Build the merlin-ai macOS .pkg installer
#
# Produces: merlin-ai-<version>.pkg
# Requires: macOS with Xcode Command Line Tools (pkgbuild + productbuild)
#
# Usage:
#   bash pkg/build-pkg.sh                    # unsigned (for local testing)
#   bash pkg/build-pkg.sh --sign             # signed with Developer ID
#   bash pkg/build-pkg.sh --sign --notarize  # sign + notarize (for distribution)
#
# Reference:
#   https://scriptingosx.com/2025/08/building-simple-component-packages/
#   https://techion.com.au/blog/2025/11/18/wrapping-macos-component-package-into-a-distribution-package
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

# Package identity
PKG_ID="com.merlin.ai"
PKG_VERSION="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.5.0")"
PKG_NAME="merlin-ai-${PKG_VERSION}"
INSTALL_DIR="/usr/local/merlin-ai"

# Signing
SIGN=false
NOTARIZE=false
DEVELOPER_ID_INSTALLER="${DEVELOPER_ID_INSTALLER:-Developer ID Installer: Your Name (TEAMID)}"
PACKAGE_SIGNING_KEYCHAIN="${PACKAGE_SIGNING_KEYCHAIN:-}"
PACKAGE_SIGNING_TIMESTAMP="${PACKAGE_SIGNING_TIMESTAMP:-timestamp}"
APPLE_ID="${APPLE_ID:-your@email.com}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-YOURTEAMID}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-}"

usage() {
  cat <<'USAGE'
Usage: bash pkg/build-pkg.sh [options]

Options:
  --sign       Sign with DEVELOPER_ID_INSTALLER.
  --notarize   Submit signed package to Apple notary service and staple ticket.
  -h, --help   Show this help.

Environment for signed/notarized release:
  DEVELOPER_ID_INSTALLER="Developer ID Installer: Name (TEAMID)"
  PACKAGE_SIGNING_KEYCHAIN="/path/to/signing.keychain"   # optional
  PACKAGE_SIGNING_TIMESTAMP="timestamp|none"             # default: timestamp
  APPLE_ID="apple-id@example.com"
  APPLE_TEAM_ID="TEAMID"
  APPLE_APP_PASSWORD="<app-specific-password>"
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sign)
      SIGN=true
      shift
      ;;
    --notarize)
      NOTARIZE=true
      SIGN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Colors
GREEN="\033[0;32m"; YELLOW="\033[1;33m"; CYAN="\033[0;36m"
BOLD="\033[1m"; RESET="\033[0m"

log()    { echo -e "${GREEN}[pkg-build]${RESET} $*" >&2; }
warn()   { echo -e "${YELLOW}[pkg-build]${RESET} $*" >&2; }
banner() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${RESET}\n" >&2; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
preflight() {
  banner "Preflight Checks"

  if [[ "$(uname)" != "Darwin" ]]; then
    echo "ERROR: .pkg builds require macOS" >&2; exit 1
  fi

  for tool in pkgbuild productbuild; do
    command -v "$tool" >/dev/null 2>&1 \
      || (echo "ERROR: $tool not found. Install Xcode Command Line Tools: xcode-select --install" >&2 && exit 1)
    log "  ✅ $tool found"
  done

  if [[ "$NOTARIZE" == true ]] && [[ -z "$APPLE_APP_PASSWORD" ]]; then
    echo "ERROR: APPLE_APP_PASSWORD must be set for notarization" >&2
    echo "  Get one at: https://appleid.apple.com > App-Specific Passwords" >&2
    exit 1
  fi

  if [[ "$SIGN" == true ]]; then
    if [[ "$DEVELOPER_ID_INSTALLER" == "Developer ID Installer: Your Name (TEAMID)" ]]; then
      echo "ERROR: DEVELOPER_ID_INSTALLER is still the placeholder value" >&2
      exit 1
    fi
    if [[ "$PACKAGE_SIGNING_TIMESTAMP" != "timestamp" && "$PACKAGE_SIGNING_TIMESTAMP" != "none" ]]; then
      echo "ERROR: PACKAGE_SIGNING_TIMESTAMP must be 'timestamp' or 'none'" >&2
      exit 1
    fi

    local identity_check=(security find-identity -v -p basic)
    if [[ -n "$PACKAGE_SIGNING_KEYCHAIN" ]]; then
      [[ -f "$PACKAGE_SIGNING_KEYCHAIN" ]] || {
        echo "ERROR: PACKAGE_SIGNING_KEYCHAIN not found: $PACKAGE_SIGNING_KEYCHAIN" >&2
        exit 1
      }
      identity_check+=("$PACKAGE_SIGNING_KEYCHAIN")
    fi

    if ! "${identity_check[@]}" | grep -Fq "$DEVELOPER_ID_INSTALLER"; then
      echo "ERROR: Developer ID Installer identity not found in keychain: $DEVELOPER_ID_INSTALLER" >&2
      exit 1
    fi
  fi

  rm -rf "$BUILD_DIR"
  mkdir -p "${BUILD_DIR}/payload${INSTALL_DIR}"
  mkdir -p "${BUILD_DIR}/scripts"
  mkdir -p "${BUILD_DIR}/resources"
  log "  Build dir: $BUILD_DIR"
  log "  Version:   $PKG_VERSION"
  log "  Install:   $INSTALL_DIR"
}

# ---------------------------------------------------------------------------
# Stage payload: copy repo files into build/payload/
# Excludes: .git, backups, build artifacts, secrets
# ---------------------------------------------------------------------------
stage_payload() {
  banner "Staging Payload"

  rsync -a \
    --exclude='.git' \
    --exclude='.env' \
    --exclude='.venv/' \
    --exclude='.venv-test/' \
    --exclude='.pytest_cache/' \
    --exclude='.wizard-bootstrapped' \
    --exclude='.DS_Store' \
    --exclude='certs/' \
    --exclude='logs/' \
    --exclude='backups/' \
    --exclude='docs/release/evidence/assets/' \
    --exclude='pkg/build/' \
    --exclude='*.pkg' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    --exclude='*.log' \
    "${ROOT_DIR}/" \
    "${BUILD_DIR}/payload${INSTALL_DIR}/"

  # Ensure all scripts are executable
  find "${BUILD_DIR}/payload${INSTALL_DIR}" -name '*.sh' -exec chmod +x {} \;

  log "  ✅ Payload staged to build/payload${INSTALL_DIR}"
  log "  Size: $(du -sh "${BUILD_DIR}/payload${INSTALL_DIR}" | cut -f1)"
}

# ---------------------------------------------------------------------------
# Copy installer scripts (preinstall + postinstall)
# These run as root during macOS Installer.app execution
# ---------------------------------------------------------------------------
stage_scripts() {
  banner "Staging Scripts"
  cp "${SCRIPT_DIR}/scripts/preinstall"  "${BUILD_DIR}/scripts/preinstall"
  cp "${SCRIPT_DIR}/scripts/postinstall" "${BUILD_DIR}/scripts/postinstall"
  chmod +x "${BUILD_DIR}/scripts/preinstall"
  chmod +x "${BUILD_DIR}/scripts/postinstall"
  log "  ✅ preinstall + postinstall staged"
}

# ---------------------------------------------------------------------------
# Copy welcome/readme/license resources for the Installer UI
# ---------------------------------------------------------------------------
stage_resources() {
  banner "Staging Resources"
  cp "${SCRIPT_DIR}/resources/welcome.html"  "${BUILD_DIR}/resources/welcome.html"
  cp "${SCRIPT_DIR}/resources/readme.html"   "${BUILD_DIR}/resources/readme.html"
  cp "${ROOT_DIR}/LICENSE"                   "${BUILD_DIR}/resources/license.txt" 2>/dev/null || true
  log "  ✅ Installer resources staged"
}

# ---------------------------------------------------------------------------
# Build component .pkg with pkgbuild
# ---------------------------------------------------------------------------
build_component_pkg() {
  banner "Building Component Package"

  local component_pkg="${BUILD_DIR}/${PKG_NAME}-component.pkg"
  local sign_args=()
  if [[ "$SIGN" == true ]]; then
    sign_args=(--sign "${DEVELOPER_ID_INSTALLER}" "--timestamp=${PACKAGE_SIGNING_TIMESTAMP}")
    if [[ -n "$PACKAGE_SIGNING_KEYCHAIN" ]]; then
      sign_args=(--keychain "${PACKAGE_SIGNING_KEYCHAIN}" "${sign_args[@]}")
    fi
    log "  Signing component with: ${DEVELOPER_ID_INSTALLER}"
  fi

  if [[ "$SIGN" == true ]]; then
    pkgbuild \
      --root     "${BUILD_DIR}/payload" \
      --scripts  "${BUILD_DIR}/scripts" \
      --identifier "${PKG_ID}" \
      --version    "${PKG_VERSION}" \
      --install-location "/" \
      "${sign_args[@]}" \
      "${component_pkg}" >&2
  else
    pkgbuild \
      --root     "${BUILD_DIR}/payload" \
      --scripts  "${BUILD_DIR}/scripts" \
      --identifier "${PKG_ID}" \
      --version    "${PKG_VERSION}" \
      --install-location "/" \
      "${component_pkg}" >&2
  fi

  [[ -f "$component_pkg" ]] || return 1

  log "  ✅ Component pkg: ${component_pkg}"
  echo "$component_pkg"
}

# ---------------------------------------------------------------------------
# Synthesize distribution.xml and build final .pkg with productbuild
# Reference: https://techion.com.au/blog/2025/11/18/wrapping-macos-component-package
# ---------------------------------------------------------------------------
build_distribution_pkg() {
  local component_pkg="$1"
  banner "Building Distribution Package"

  local dist_xml="${BUILD_DIR}/distribution.xml"
  local final_pkg="${ROOT_DIR}/${PKG_NAME}.pkg"

  # Synthesize distribution blueprint from component pkg (Apple-recommended method)
  productbuild \
    --synthesize \
    --package "${component_pkg}" \
    "${dist_xml}" >&2

  [[ -s "$dist_xml" ]] || return 1

  # Build final distribution pkg with resources (welcome/readme/license)
  local sign_args=()
  if [[ "$SIGN" == true ]]; then
    sign_args=(--sign "${DEVELOPER_ID_INSTALLER}" "--timestamp=${PACKAGE_SIGNING_TIMESTAMP}")
    if [[ -n "$PACKAGE_SIGNING_KEYCHAIN" ]]; then
      sign_args=(--keychain "${PACKAGE_SIGNING_KEYCHAIN}" "${sign_args[@]}")
    fi
    log "  Signing with: ${DEVELOPER_ID_INSTALLER}"
  fi

  if [[ "$SIGN" == true ]]; then
    productbuild \
      --distribution  "${dist_xml}" \
      --resources     "${BUILD_DIR}/resources" \
      --package-path  "${BUILD_DIR}" \
      "${sign_args[@]}" \
      "${final_pkg}" >&2
  else
    productbuild \
      --distribution  "${dist_xml}" \
      --resources     "${BUILD_DIR}/resources" \
      --package-path  "${BUILD_DIR}" \
      "${final_pkg}" >&2
  fi

  [[ -f "$final_pkg" ]] || return 1

  log "  ✅ Final pkg: ${final_pkg}"
  log "  Size: $(du -sh "${final_pkg}" | cut -f1)"
  echo "$final_pkg"
}

# ---------------------------------------------------------------------------
# Notarize the pkg with Apple notary service
# Requires: Apple Developer account + app-specific password
# ---------------------------------------------------------------------------
notarize_pkg() {
  local pkg_path="$1"
  banner "Notarizing Package"

  log "  Submitting to Apple notary service..."
  log "  (This can take 2-10 minutes)"

  # Store credentials in keychain profile (one-time setup)
  xcrun notarytool store-credentials "merlin-ai-notary" \
    --apple-id     "${APPLE_ID}" \
    --team-id      "${APPLE_TEAM_ID}" \
    --password     "${APPLE_APP_PASSWORD}" 2>/dev/null || true

  # Submit and wait
  xcrun notarytool submit "${pkg_path}" \
    --keychain-profile "merlin-ai-notary" \
    --wait

  # Staple the notarization ticket to the pkg
  xcrun stapler staple "${pkg_path}"

  log "  ✅ Notarized and stapled: ${pkg_path}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo -e "${CYAN}${BOLD}"
  echo "  ┌──────────────────────────────────────┐"
  echo "  │   merlin-ai .pkg builder         │"
  echo "  │   version: ${PKG_VERSION}                       │"
  echo "  └──────────────────────────────────────┘"
  echo -e "${RESET}"

  preflight
  stage_payload
  stage_scripts
  stage_resources

  local component_pkg
  component_pkg=$(build_component_pkg)

  local final_pkg
  final_pkg=$(build_distribution_pkg "$component_pkg")

  if [[ "$NOTARIZE" == true ]]; then
    notarize_pkg "$final_pkg"
  fi

  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║   ✅ PKG built successfully!            ║"
  echo "  ╠══════════════════════════════════════════╣"
  echo "  ║  File: ${PKG_NAME}.pkg"
  echo "  ║  Install: double-click the .pkg file    ║"
  [[ "$SIGN" == true ]] && echo "  ║  ✅ Signed with Developer ID             ║"
  [[ "$NOTARIZE" == true ]] && echo "  ║  ✅ Notarized by Apple                  ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"
}

main "$@"
