#!/usr/bin/env bash
# LockedinOS — Master Build Script (Run inside WSL Ubuntu)
# Usage: sudo ./build-all.sh
set -euo pipefail

# Clean PATH to prevent Windows PATH pollution in WSL from breaking tools like 'env'
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
RELEASE_DIR="${REPO_ROOT}/release"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root (sudo)"
  exit 1
fi

echo "================================================="
echo "  LockedinOS Build System (WSL)"
echo "================================================="

CLEAN_BUILD=0
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --clean) CLEAN_BUILD=1 ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

if [ "$CLEAN_BUILD" -eq 1 ]; then
  echo "==> CLEAN BUILD REQUESTED: Wiping caches before building..."
fi

# Install master prerequisites for building everything
echo "==> [1/4] Installing system prerequisites..."
apt-get update
# We need node for the electron app, plus live-build for the ISO, plus fakeroot and gnupg
apt-get install -y curl build-essential fakeroot dpkg-dev live-build debootstrap gnupg gnupg1 gnupg2

# Ensure Node.js 18+ is installed (needed for tasks-calendar)
if ! command -v node >/dev/null 2>&1 || ! node -v | grep -q '^v1[89]\|v20\|v22'; then
    echo "==> Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Build tasks-calendar .deb
echo ""
echo "==> [2/5] Building tasks-calendar package..."
if [ -f "${REPO_ROOT}/packages/tasks-calendar/build-deb.sh" ]; then
    if [ "$CLEAN_BUILD" -eq 0 ] && ls "${REPO_ROOT}/packages/tasks-calendar/build/"*.deb 1> /dev/null 2>&1; then
        echo "==> tasks-calendar .deb already exists, skipping."
    else
        echo "==> Building newly..."
        cd "${REPO_ROOT}/packages/tasks-calendar"
        # Ensure dependencies are clean
        rm -rf node_modules build || true
        bash build-deb.sh
    fi
else
    echo "WARNING: packages/tasks-calendar/build-deb.sh not found!"
fi

# Build lockedin-focus .deb
echo ""
echo "==> [3/5] Building lockedin-focus package..."
if [ -f "${REPO_ROOT}/packages/lockedin-focus/build-deb.sh" ]; then
    if [ "$CLEAN_BUILD" -eq 0 ] && ls "${REPO_ROOT}/packages/lockedin-focus/build/"*.deb 1> /dev/null 2>&1; then
        echo "==> lockedin-focus .deb already exists, skipping."
    else
        echo "==> Building newly..."
        cd "${REPO_ROOT}/packages/lockedin-focus"
        rm -rf build || true
        bash build-deb.sh
    fi
else
    echo "WARNING: packages/lockedin-focus/build-deb.sh not found!"
fi

# Build lockedin-dashboard .deb
echo ""
echo "==> [4/5] Building lockedin-dashboard package..."
if [ -f "${REPO_ROOT}/packages/lockedin-dashboard/build-deb.sh" ]; then
    if [ "$CLEAN_BUILD" -eq 0 ] && ls "${REPO_ROOT}/packages/lockedin-dashboard/build/"*.deb 1> /dev/null 2>&1; then
        echo "==> lockedin-dashboard .deb already exists, skipping."
    else
        echo "==> Building newly..."
        cd "${REPO_ROOT}/packages/lockedin-dashboard"
        rm -rf node_modules build || true
        bash build-deb.sh
    fi
else
    echo "WARNING: packages/lockedin-dashboard/build-deb.sh not found!"
fi

# Build ISO
echo ""
echo "==> [5/5] Building LockedinOS ISO using live-build..."
cd "${REPO_ROOT}/infra"
if [ -f "./build-live-build.sh" ]; then
    if [ "$CLEAN_BUILD" -eq 1 ]; then
        bash ./build-live-build.sh "$RELEASE_DIR" "--clean"
    else
        bash ./build-live-build.sh "$RELEASE_DIR"
    fi
else
    echo "ERROR: infra/build-live-build.sh not found!"
    exit 1
fi

echo ""
echo "================================================="
echo "  LockedinOS Build Complete!"
echo "  ISO is located at: $RELEASE_DIR"
echo "================================================="
