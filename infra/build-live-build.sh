#!/usr/bin/env bash
# LockedinOS — Alternative ISO Build using Debian live-build
# For Debian-savvy maintainers who prefer live-build over Cubic
# Usage: sudo ./build-live-build.sh [output-dir]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-${REPO_ROOT}/release}"
WORK_DIR="${SCRIPT_DIR}/live-build-work"
BUILD_DIR="${WORK_DIR}/lockedinos-live"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root (sudo)"
  exit 1
fi

echo "============================================"
echo "  LockedinOS v1 — live-build ISO"
echo "============================================"

# ── Install live-build ──
echo "==> Installing live-build..."
apt-get update
apt-get install -y live-build debootstrap

# ── Prepare build directory ──
echo "==> Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ── Configure live-build ──
echo "==> Configuring live-build..."
lb config \
  --distribution noble \
  --archive-areas "main restricted universe multiverse" \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootappend-live "boot=casper quiet splash" \
  --debian-installer none \
  --linux-flavours generic \
  --mode ubuntu \
  --iso-application "LockedinOS" \
  --iso-volume "LockedinOS v1" \
  --iso-publisher "LockedinOS Contributors"

# ── Package lists ──
echo "==> Creating package lists..."
mkdir -p config/package-lists
cat > config/package-lists/lockedinos.list.chroot << 'EOF'
gnome-shell
gnome-control-center
gnome-tweaks
gnome-terminal
gnome-text-editor
nautilus
timeshift
flatpak
gnome-software-plugin-flatpak
sqlite3
python3-venv
curl
wget
git
zenity
libnotify-bin
dconf-cli
network-manager
network-manager-gnome
pulseaudio
pavucontrol
gparted
vim-tiny
htop
neofetch
unzip
xdg-utils
EOF

# ── Include .deb packages ──
echo "==> Including custom .deb packages..."
mkdir -p config/packages.chroot
if [ -d "${REPO_ROOT}/packages/tasks-calendar/build" ]; then
  cp "${REPO_ROOT}/packages/tasks-calendar/build/"*.deb config/packages.chroot/ 2>/dev/null || true
fi
if [ -d "${REPO_ROOT}/packages/lockedin-focus/build" ]; then
  cp "${REPO_ROOT}/packages/lockedin-focus/build/"*.deb config/packages.chroot/ 2>/dev/null || true
fi

# ── Include overlay files ──
echo "==> Including overlay files..."
mkdir -p config/includes.chroot
if [ -d "${REPO_ROOT}/iso-seed" ]; then
  cp -r "${REPO_ROOT}/iso-seed/"* config/includes.chroot/
fi

# Install wizard script
mkdir -p config/includes.chroot/usr/local/bin
if [ -f "${REPO_ROOT}/configs/installer/first-boot-wizard.sh" ]; then
  install -m 755 "${REPO_ROOT}/configs/installer/first-boot-wizard.sh" \
    config/includes.chroot/usr/local/bin/lockedin-wizard
fi

# ── Chroot hooks ──
echo "==> Creating chroot hooks..."
mkdir -p config/hooks/live
cat > config/hooks/live/01-lockedin-setup.hook.chroot << 'HOOK'
#!/bin/sh
set -e

# Apply dconf settings
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF
dconf update 2>/dev/null || true

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Configure Timeshift
mkdir -p /etc/timeshift
cat > /etc/timeshift/timeshift.json << 'EOF'
{
  "backup_device_uuid": "",
  "do_first_run": true,
  "schedule_weekly": true,
  "schedule_daily": true,
  "count_weekly": 3,
  "count_daily": 5
}
EOF

# Update desktop database
update-desktop-database /usr/share/applications 2>/dev/null || true
HOOK
chmod 755 config/hooks/live/01-lockedin-setup.hook.chroot

# ── Build ISO ──
echo "==> Building ISO (this will take a while)..."
lb build

# ── Move output ──
echo "==> Moving output..."
mkdir -p "$OUTPUT_DIR"
ISO_FILE=$(find . -maxdepth 1 -name "*.iso" -type f | head -1)
if [ -n "$ISO_FILE" ]; then
  mv "$ISO_FILE" "${OUTPUT_DIR}/LockedinOS-v1.0.0-amd64.iso"
  cd "$OUTPUT_DIR"
  sha256sum "LockedinOS-v1.0.0-amd64.iso" > "LockedinOS-v1.0.0-amd64.iso.sha256"
  echo ""
  echo "============================================"
  echo "  Build Complete!"
  echo "============================================"
  echo "ISO: ${OUTPUT_DIR}/LockedinOS-v1.0.0-amd64.iso"
  echo "SHA256: $(cat LockedinOS-v1.0.0-amd64.iso.sha256)"
else
  echo "ERROR: No ISO file produced by live-build"
  exit 1
fi
