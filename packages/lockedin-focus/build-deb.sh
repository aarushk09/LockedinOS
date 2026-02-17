#!/usr/bin/env bash
# Build lockedin-focus .deb package
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_NAME="lockedin-focus"
VERSION="1.0.0"
ARCH="all"
PKG_DIR="${SCRIPT_DIR}/build/${PKG_NAME}_${VERSION}_${ARCH}"

echo "==> Building ${PKG_NAME} v${VERSION}"

rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/local/bin"
mkdir -p "$PKG_DIR/etc/lockedin"
mkdir -p "$PKG_DIR/etc/systemd/system"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/pixmaps"

# Install the focus script
install -m 755 "${SCRIPT_DIR}/scripts/lockedin-focus" "$PKG_DIR/usr/local/bin/lockedin-focus"

# Install default blocklist
install -m 644 "${SCRIPT_DIR}/scripts/focus-blocklist.txt" "$PKG_DIR/etc/lockedin/focus-blocklist.txt"

# Systemd service
cat > "$PKG_DIR/etc/systemd/system/lockedin-focus.service" << 'SERVICE'
[Unit]
Description=LockedIn Focus Mode helper daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/lockedin-focus daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# Desktop entry for toggling focus mode
cat > "$PKG_DIR/usr/share/applications/lockedin-focus.desktop" << 'DESKTOP'
[Desktop Entry]
Name=LockedIn Focus Mode
Comment=Toggle distraction-free focus mode
Exec=/usr/local/bin/lockedin-focus toggle
Icon=preferences-system-notifications
Terminal=false
Type=Application
Categories=Utility;
Keywords=focus;dnd;block;productivity;
DESKTOP

# DEBIAN control
cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: bash, libnotify-bin
Recommends: gnome-shell
Maintainer: LockedinOS Contributors <lockedinos@protonmail.com>
Description: LockedIn Focus Mode
 A simple focus mode toggle for students. Enables Do Not Disturb
 and blocks distracting websites via /etc/hosts.
 Part of the LockedinOS distribution.
Homepage: https://github.com/lockedinos/lockedinos
EOF

cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/sh
set -e
systemctl daemon-reload 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

cat > "$PKG_DIR/DEBIAN/postrm" << 'POSTRM'
#!/bin/sh
set -e
systemctl daemon-reload 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
POSTRM
chmod 755 "$PKG_DIR/DEBIAN/postrm"

cat > "$PKG_DIR/DEBIAN/conffiles" << 'CONFFILES'
/etc/lockedin/focus-blocklist.txt
CONFFILES

# Build
echo "==> Building .deb..."
cd "${SCRIPT_DIR}/build"
fakeroot dpkg-deb --build "${PKG_NAME}_${VERSION}_${ARCH}"

DEB_PATH="${SCRIPT_DIR}/build/${PKG_NAME}_${VERSION}_${ARCH}.deb"
echo "==> Package built: ${DEB_PATH}"
echo "==> SHA256: $(sha256sum "$DEB_PATH" | cut -d' ' -f1)"
