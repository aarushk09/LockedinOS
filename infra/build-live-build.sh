#!/usr/bin/env bash
# LockedinOS — Alternative ISO Build using Debian live-build
# For Debian-savvy maintainers who prefer live-build over Cubic
# Usage: sudo ./build-live-build.sh [output-dir]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-${REPO_ROOT}/release}"
CLEAN_BUILD="${2:-}"
WORK_DIR="/root/lockedinos-live-build-work"
BUILD_DIR="${WORK_DIR}/lockedinos-live"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root (sudo)"
  exit 1
fi

echo "============================================"
echo "  LockedinOS v1 — live-build ISO"
echo "============================================"

# ── Install live-build and ISO tools ──
echo "==> Installing live-build and ISO tools..."
apt-get update
apt-get install -y live-build debootstrap syslinux-utils xorriso mtools grub-pc-bin grub-efi-amd64-bin

# ── Prepare build directory ──
echo "==> Preparing build directory..."

if [ "$CLEAN_BUILD" = "--clean" ]; then
  echo "==> CLEAN BUILD: Wiping previous live-build workspace..."
  rm -rf "$WORK_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
# Clean broken chroot states but KEEP the apt cache to speed up the build (if not a hard wipe)
lb clean || true

# ── Configure live-build ──
echo "==> Configuring live-build..."
lb config \
  --distribution noble \
  --archive-areas "main restricted universe multiverse" \
  --architectures amd64 \
  --binary-images iso \
  --bootappend-live "boot=casper quiet splash" \
  --bootloader grub2 \
  --linux-flavours generic \
  --mode ubuntu \
  --iso-application "LockedinOS" \
  --iso-volume "LockedinOS v1" \
  --iso-publisher "LockedinOS Contributors" \
  --apt-secure false

# ── Package lists ──
echo "==> Creating package lists..."
mkdir -p config/package-lists
cat > config/package-lists/lockedinos.list.chroot << 'EOF'
gnome-shell
gnome-control-center
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
chromium-browser
syslinux-utils
gdm3
EOF

# ── Include custom .deb packages via hook ──
echo "==> Staging custom .deb packages..."
mkdir -p config/includes.chroot/tmp/lockedin-debs
if [ -d "${REPO_ROOT}/packages/tasks-calendar/build" ]; then
  cp "${REPO_ROOT}/packages/tasks-calendar/build/"*.deb config/includes.chroot/tmp/lockedin-debs/ 2>/dev/null || true
fi
if [ -d "${REPO_ROOT}/packages/lockedin-focus/build" ]; then
  cp "${REPO_ROOT}/packages/lockedin-focus/build/"*.deb config/includes.chroot/tmp/lockedin-debs/ 2>/dev/null || true
fi
if [ -d "${REPO_ROOT}/packages/lockedin-dashboard/build" ]; then
  cp "${REPO_ROOT}/packages/lockedin-dashboard/build/"*.deb config/includes.chroot/tmp/lockedin-debs/ 2>/dev/null || true
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

echo "==> LockedinOS chroot setup starting..."

# ── Apply dconf settings ──
# The overlay has our settings at /etc/dconf/db/local.d/00-lockedin-defaults
# and the profile at /etc/dconf/profile/user. Compile the database.
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF
dconf update 2>/dev/null || true
echo "==> dconf database compiled"

# ── Suppress GNOME initial setup wizard ──
mkdir -p /etc/skel/.config
echo "yes" > /etc/skel/.config/gnome-initial-setup-done

# ── Configure GDM3 for auto-login ──
# Auto-login into the regular GNOME/ubuntu session.
# Our GNOME Shell extension hides the panels, and our dashboard
# autostarts fullscreen on top.
mkdir -p /etc/gdm3
cat > /etc/gdm3/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=ubuntu
WaylandEnable=false

[security]
AllowRoot=false

[greeter]

[chooser]
EOF
echo "==> GDM3 configured for auto-login"

# ── Enable GNOME Shell extension system-wide ──
# Our extension at /usr/share/gnome-shell/extensions/lockedinos-shell@lockedinos.org/
# hides the top panel, dock, and Activities. It's enabled via dconf, but we also
# need to make sure GNOME allows system extensions.
if [ -d /usr/share/gnome-shell/extensions/lockedinos-shell@lockedinos.org ]; then
  echo "==> LockedinOS Shell extension found and will be enabled via dconf"
else
  echo "WARNING: LockedinOS Shell extension not found!"
fi

# ── Add Flathub ──
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# ── Configure Timeshift ──
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

# ── Install custom .deb packages ──
if ls /tmp/lockedin-debs/*.deb 1> /dev/null 2>&1; then
  echo "==> Installing custom .deb packages..."
  dpkg --force-depends -i /tmp/lockedin-debs/*.deb 2>&1 || true
  apt-get install -f -y 2>&1 || true
  rm -rf /tmp/lockedin-debs
  echo "==> Custom packages installed"
else
  echo "WARNING: No custom .deb packages found in /tmp/lockedin-debs/"
fi

# ── Update desktop database ──
update-desktop-database /usr/share/applications 2>/dev/null || true

echo "==> LockedinOS chroot setup complete"
HOOK
chmod 755 config/hooks/live/01-lockedin-setup.hook.chroot

# ── Build ISO ──
echo "==> Building ISO (this will take a while)..."
export DEBOOTSTRAP_OPTIONS="--include=gnupg,gpg"
lb build

# ── Move output ──
echo "==> Converting raw ISO to Bootable Hybrid ISO with grub-mkrescue (this enables Rufus/USB boot)..."
mkdir -p "$OUTPUT_DIR"
# Output directly to Windows target directory to avoid WSL VHDX size limits / tmpfs memory exhaustion
rm -f "${OUTPUT_DIR}/LockedinOS-v1.0.0-amd64.iso" || true
grub-mkrescue -o "${OUTPUT_DIR}/LockedinOS-v1.0.0-amd64.iso" "$BUILD_DIR/binary"

if [ -f "${OUTPUT_DIR}/LockedinOS-v1.0.0-amd64.iso" ]; then
  cd "$OUTPUT_DIR"
  sha256sum "LockedinOS-v1.0.0-amd64.iso" > "LockedinOS-v1.0.0-amd64.iso.sha256"
  echo ""
  echo "============================================"
  echo "  Build Complete!"
  echo "============================================"
  echo "ISO: ${OUTPUT_DIR}/LockedinOS-v1.0.0-amd64.iso"
  echo "SHA256: $(cat LockedinOS-v1.0.0-amd64.iso.sha256)"
else
  echo "ERROR: Failed to generate hybrid ISO with grub-mkrescue"
  exit 1
fi
