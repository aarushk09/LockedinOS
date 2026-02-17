#!/usr/bin/env bash
# LockedinOS — Prepare chroot environment for ISO customization
# This script is run INSIDE the chroot (either via Cubic or live-build)
# Usage: ./prepare-chroot.sh [--deb-dir /path/to/debs]
set -euo pipefail

DEB_DIR="${1:-/tmp/lockedin-packages}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "============================================"
echo "  LockedinOS v1 — Chroot Preparation"
echo "============================================"

# ── Step 1: Update base system ──
echo ""
echo "==> [1/9] Updating base system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# ── Step 2: Install required packages ──
echo ""
echo "==> [2/9] Installing required packages..."
apt-get install -y --no-install-recommends \
  gnome-shell \
  gnome-control-center \
  gnome-tweaks \
  gnome-shell-extension-prefs \
  gnome-terminal \
  gnome-text-editor \
  nautilus \
  timeshift \
  flatpak \
  gnome-software-plugin-flatpak \
  sqlite3 \
  python3-venv \
  python3-pip \
  curl \
  wget \
  git \
  zenity \
  libnotify-bin \
  dconf-cli \
  dconf-editor \
  gnome-shell-extension-appindicator \
  network-manager \
  network-manager-gnome \
  pulseaudio \
  pavucontrol \
  gparted \
  vim-tiny \
  htop \
  neofetch \
  unzip \
  xdg-utils

# ── Step 3: Add Flathub remote ──
echo ""
echo "==> [3/9] Configuring Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# ── Step 4: Install LockedIn .deb packages ──
echo ""
echo "==> [4/9] Installing LockedIn packages..."
if [ -d "$DEB_DIR" ]; then
  for deb in "$DEB_DIR"/*.deb; do
    if [ -f "$deb" ]; then
      echo "  Installing: $(basename "$deb")"
      dpkg -i "$deb" || true
    fi
  done
  apt-get install -f -y
else
  echo "  WARNING: No .deb directory found at $DEB_DIR"
  echo "  Build packages first: cd packages/tasks-calendar && ./build-deb.sh"
fi

# ── Step 5: Copy ISO seed files ──
echo ""
echo "==> [5/9] Copying ISO seed files..."
if [ -d "${REPO_ROOT}/iso-seed" ]; then
  cp -rv "${REPO_ROOT}/iso-seed/"* / 2>/dev/null || true
  echo "  ISO seed files copied"
else
  echo "  WARNING: iso-seed directory not found"
fi

# ── Step 6: Install first-boot wizard ──
echo ""
echo "==> [6/9] Installing first-boot wizard..."
if [ -f "${REPO_ROOT}/configs/installer/first-boot-wizard.sh" ]; then
  install -m 755 "${REPO_ROOT}/configs/installer/first-boot-wizard.sh" /usr/local/bin/lockedin-wizard
  echo "  Wizard installed at /usr/local/bin/lockedin-wizard"
fi

# ── Step 7: Apply GNOME settings ──
echo ""
echo "==> [7/9] Applying GNOME settings..."
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

mkdir -p /etc/dconf/db/local.d
if [ -f "${REPO_ROOT}/configs/gnome/lockedin-defaults.ini" ]; then
  cp "${REPO_ROOT}/configs/gnome/lockedin-defaults.ini" /etc/dconf/db/local.d/00-lockedin-defaults
fi
dconf update 2>/dev/null || true
echo "  dconf database updated"

# ── Step 8: Remove unnecessary apps ──
echo ""
echo "==> [8/9] Removing unnecessary default apps..."
if [ -f "${REPO_ROOT}/configs/gnome/remove-social-apps.sh" ]; then
  bash "${REPO_ROOT}/configs/gnome/remove-social-apps.sh"
fi

# ── Step 9: Configure Timeshift ──
echo ""
echo "==> [9/9] Configuring Timeshift..."
mkdir -p /etc/timeshift
cat > /etc/timeshift/timeshift.json << 'TIMESHIFT'
{
  "backup_device_uuid": "",
  "parent_device_uuid": "",
  "do_first_run": true,
  "btrfs_mode": false,
  "include_btrfs_home_for_backup": false,
  "include_btrfs_home_for_restore": false,
  "stop_cron_emails": true,
  "schedule_monthly": false,
  "schedule_weekly": true,
  "schedule_daily": true,
  "schedule_hourly": false,
  "schedule_boot": false,
  "count_monthly": 2,
  "count_weekly": 3,
  "count_daily": 5,
  "count_hourly": 6,
  "count_boot": 5,
  "snapshot_size": 0,
  "snapshot_count": 0,
  "date_format": "%Y-%m-%d %H:%M:%S",
  "exclude": [
    "/home/**/.cache/**",
    "/home/**/.thumbnails/**",
    "/home/**/.local/share/Trash/**",
    "/home/**/node_modules/**"
  ],
  "exclude-apps": []
}
TIMESHIFT

# ── Cleanup ──
echo ""
echo "==> Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/cache/apt/archives/*
rm -rf /tmp/*

echo ""
echo "============================================"
echo "  LockedinOS chroot preparation complete!"
echo "============================================"
