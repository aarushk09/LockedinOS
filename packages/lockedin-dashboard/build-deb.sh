#!/usr/bin/env bash
# Build the lockedin-dashboard .deb package
# Usage: ./build-deb.sh
# Requires: npm, node, dpkg-deb, fakeroot
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="lockedin-dashboard"
VERSION="1.0.0"
ARCH="amd64"
PKG_DIR="${SCRIPT_DIR}/build/${APP_NAME}_${VERSION}_${ARCH}"
INSTALL_DIR="/opt/lockedin-dashboard"

echo "==> Building ${APP_NAME} v${VERSION}"

# Step 1: Install dependencies and build renderer
cd "$SCRIPT_DIR"
echo "==> Installing dependencies..."
npm install --no-fund --no-audit

echo "==> Building renderer (webpack)..."
npm run build:renderer

# Step 2: Package with electron-builder (creates standalone binary with Electron bundled)
echo "==> Packaging with electron-builder..."
npx electron-builder --linux dir --config.directories.output=build/electron-out

ELECTRON_OUT=$(find build/electron-out -maxdepth 1 -type d -name "linux*" | head -1)
if [ -z "$ELECTRON_OUT" ]; then
  echo "ERROR: electron-builder output not found"
  exit 1
fi

# Step 3: Create .deb directory structure
echo "==> Creating .deb structure..."
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR${INSTALL_DIR}"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/pixmaps"
mkdir -p "$PKG_DIR/usr/bin"

# Copy Electron app files (standalone binary + resources)
cp -r "$ELECTRON_OUT"/* "$PKG_DIR${INSTALL_DIR}/"

# Create launcher script
cat > "$PKG_DIR/usr/bin/lockedin-dashboard" << 'LAUNCHER'
#!/bin/sh
exec /opt/lockedin-dashboard/lockedin-dashboard --no-sandbox "$@"
LAUNCHER
chmod 755 "$PKG_DIR/usr/bin/lockedin-dashboard"

# Desktop file
cat > "$PKG_DIR/usr/share/applications/lockedin-dashboard.desktop" << 'DESKTOP'
[Desktop Entry]
Name=LockedIn Dashboard
Comment=LockedinOS unified productivity dashboard
Exec=/usr/bin/lockedin-dashboard %U
Icon=lockedin-dashboard
Terminal=false
Type=Application
Categories=Utility;System;
Keywords=dashboard;tasks;focus;productivity;
StartupWMClass=lockedin-dashboard
DESKTOP

# Copy icon
if [ -f "${SCRIPT_DIR}/assets/icon.png" ]; then
  cp "${SCRIPT_DIR}/assets/icon.png" "$PKG_DIR/usr/share/pixmaps/lockedin-dashboard.png"
fi

# Step 4: Create DEBIAN control file
cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libsecret-1-0
Maintainer: LockedinOS Contributors <lockedinos@protonmail.com>
Description: LockedIn Dashboard
 Unified productivity dashboard for LockedinOS with tasks,
 calendar, notes, focus mode, and study tools.
 Part of the LockedinOS distribution.
Homepage: https://github.com/aarushk09/LockedinOS
EOF

cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/sh
set -e
update-desktop-database /usr/share/applications 2>/dev/null || true
chmod 4755 /opt/lockedin-dashboard/chrome-sandbox 2>/dev/null || true
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

cat > "$PKG_DIR/DEBIAN/postrm" << 'POSTRM'
#!/bin/sh
set -e
update-desktop-database /usr/share/applications 2>/dev/null || true
POSTRM
chmod 755 "$PKG_DIR/DEBIAN/postrm"

# Fix WSL 777 permissions by building in /tmp (native Linux FS)
TMP_BUILD="/tmp/${APP_NAME}_${VERSION}_${ARCH}"
rm -rf "$TMP_BUILD"
cp -r "$PKG_DIR" "$TMP_BUILD"
find "$TMP_BUILD" -type d -exec chmod 755 {} +
find "$TMP_BUILD" -type f -exec chmod 644 {} +
chmod 755 "$TMP_BUILD/DEBIAN/postinst" "$TMP_BUILD/DEBIAN/postrm" "$TMP_BUILD/usr/bin/lockedin-dashboard" 2>/dev/null || true
# Electron executables
chmod 755 "$TMP_BUILD/opt/lockedin-dashboard/lockedin-dashboard" "$TMP_BUILD/opt/lockedin-dashboard/chrome-sandbox" 2>/dev/null || true

# Step 5: Build the .deb
echo "==> Building .deb package in /tmp..."
cd /tmp
fakeroot dpkg-deb --build "${APP_NAME}_${VERSION}_${ARCH}"
cp "/tmp/${APP_NAME}_${VERSION}_${ARCH}.deb" "${SCRIPT_DIR}/build/"
rm -rf "$TMP_BUILD" "/tmp/${APP_NAME}_${VERSION}_${ARCH}.deb"

DEB_PATH="${SCRIPT_DIR}/build/${APP_NAME}_${VERSION}_${ARCH}.deb"
echo "==> Package built: ${DEB_PATH}"
echo "==> SHA256: $(sha256sum "$DEB_PATH" | cut -d' ' -f1)"
echo "==> Size: $(du -h "$DEB_PATH" | cut -f1)"
