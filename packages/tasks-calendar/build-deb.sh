#!/usr/bin/env bash
# Build the lockedin-tasks-calendar .deb package
# Usage: ./build-deb.sh
# Requires: npm, node, dpkg-deb, fakeroot
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="lockedin-tasks-calendar"
VERSION="1.0.0"
ARCH="amd64"
PKG_DIR="${SCRIPT_DIR}/build/${APP_NAME}_${VERSION}_${ARCH}"
INSTALL_DIR="/opt/lockedin-tasks-calendar"

echo "==> Building ${APP_NAME} v${VERSION}"

# Step 1: Install dependencies and build renderer
cd "$SCRIPT_DIR"
echo "==> Installing dependencies..."
npm ci --production=false

echo "==> Building renderer (webpack)..."
npm run build:renderer

# Step 2: Prepare the electron app for packaging
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

# Copy Electron app files
cp -r "$ELECTRON_OUT"/* "$PKG_DIR${INSTALL_DIR}/"

# Create symlink launcher
cat > "$PKG_DIR/usr/bin/lockedin-tasks" << 'LAUNCHER'
#!/bin/sh
exec /opt/lockedin-tasks-calendar/lockedin-tasks-calendar --no-sandbox "$@"
LAUNCHER
chmod 755 "$PKG_DIR/usr/bin/lockedin-tasks"

# Desktop file
cat > "$PKG_DIR/usr/share/applications/lockedin-tasks.desktop" << 'DESKTOP'
[Desktop Entry]
Name=LockedIn Tasks & Calendar
Comment=Student-focused task manager and calendar
Exec=/usr/bin/lockedin-tasks %U
Icon=lockedin-tasks
Terminal=false
Type=Application
Categories=Office;ProjectManagement;Calendar;
Keywords=tasks;calendar;productivity;student;
StartupWMClass=lockedin-tasks-calendar
DESKTOP

# Copy icon
if [ -f "${SCRIPT_DIR}/assets/icon.png" ]; then
  cp "${SCRIPT_DIR}/assets/icon.png" "$PKG_DIR/usr/share/pixmaps/lockedin-tasks.png"
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
Description: LockedIn Tasks & Calendar
 A student-focused productivity app with task management,
 calendar views, priorities, tags, and SQLite-backed persistence.
 Part of the LockedinOS distribution.
Homepage: https://github.com/lockedinos/lockedinos
EOF

cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/sh
set -e
update-desktop-database /usr/share/applications 2>/dev/null || true
chmod 4755 /opt/lockedin-tasks-calendar/chrome-sandbox 2>/dev/null || true
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

cat > "$PKG_DIR/DEBIAN/postrm" << 'POSTRM'
#!/bin/sh
set -e
update-desktop-database /usr/share/applications 2>/dev/null || true
POSTRM
chmod 755 "$PKG_DIR/DEBIAN/postrm"

# Step 5: Build the .deb
echo "==> Building .deb package..."
cd "${SCRIPT_DIR}/build"
fakeroot dpkg-deb --build "${APP_NAME}_${VERSION}_${ARCH}"

DEB_PATH="${SCRIPT_DIR}/build/${APP_NAME}_${VERSION}_${ARCH}.deb"
echo "==> Package built: ${DEB_PATH}"
echo "==> SHA256: $(sha256sum "$DEB_PATH" | cut -d' ' -f1)"
echo "==> Size: $(du -h "$DEB_PATH" | cut -f1)"
