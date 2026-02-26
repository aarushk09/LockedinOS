#!/usr/bin/env bash
# Build lockedin-dashboard .deb package
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NAME="lockedin-dashboard"
VERSION="1.0.0"
BUILD_DIR="${SCRIPT_DIR}/build"
STAGE_DIR="/tmp/${PACKAGE_NAME}-deb-stage"

echo "==> Building ${PACKAGE_NAME} v${VERSION}"

cd "$SCRIPT_DIR"

# Install Node dependencies
if [ ! -d "node_modules" ]; then
  echo "==> Installing npm dependencies..."
  npm install --no-fund --no-audit
fi

# Build renderer bundle
echo "==> Building renderer..."
npx webpack --config webpack.config.js --mode production

# Prepare staging directory
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/opt/${PACKAGE_NAME}"
mkdir -p "$STAGE_DIR/usr/bin"
mkdir -p "$STAGE_DIR/usr/share/applications"
mkdir -p "$STAGE_DIR/DEBIAN"

# Copy application files
cp -r dist "$STAGE_DIR/opt/${PACKAGE_NAME}/"
cp -r src/main "$STAGE_DIR/opt/${PACKAGE_NAME}/"
cp package.json "$STAGE_DIR/opt/${PACKAGE_NAME}/"

# Install production dependencies only in staging
cd "$STAGE_DIR/opt/${PACKAGE_NAME}"
npm install --omit=dev --no-fund --no-audit 2>/dev/null || true
cd "$SCRIPT_DIR"

# Create launcher script
cat > "$STAGE_DIR/usr/bin/${PACKAGE_NAME}" << 'LAUNCHER'
#!/bin/bash
exec electron /opt/lockedin-dashboard/src/main/main.js "$@"
LAUNCHER
chmod 755 "$STAGE_DIR/usr/bin/${PACKAGE_NAME}"

# Create .desktop file
cat > "$STAGE_DIR/usr/share/applications/${PACKAGE_NAME}.desktop" << 'DESKTOP'
[Desktop Entry]
Name=LockedIn Dashboard
Comment=LockedinOS unified productivity dashboard
Exec=/usr/bin/lockedin-dashboard %U
Icon=preferences-desktop
Terminal=false
Type=Application
Categories=Utility;System;
Keywords=dashboard;tasks;focus;productivity;
StartupWMClass=lockedin-dashboard
DESKTOP

# Create DEBIAN control file
cat > "$STAGE_DIR/DEBIAN/control" << CONTROL
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Depends: electron | nodejs
Maintainer: LockedinOS Contributors
Description: LockedinOS Dashboard
 Unified productivity dashboard for LockedinOS with tasks,
 calendar, notes, focus mode, and study tools.
CONTROL

# Build .deb
mkdir -p "$BUILD_DIR"
fakeroot dpkg-deb --build "$STAGE_DIR" "${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb"

# Cleanup
rm -rf "$STAGE_DIR"

echo "==> Built: ${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb"
