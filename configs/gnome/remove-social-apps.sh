#!/usr/bin/env bash
# Remove default "social" and unnecessary apps from the ISO
# Run inside chroot during ISO build
set -euo pipefail

echo "==> Removing unnecessary default apps..."

PACKAGES_TO_REMOVE=(
  thunderbird
  rhythmbox
  shotwell
  cheese
  gnome-mahjongg
  gnome-mines
  gnome-sudoku
  aisleriot
  gnome-maps
  gnome-weather
  gnome-contacts
  gnome-music
  totem
  simple-scan
  remmina
  transmission-gtk
  libreoffice-impress
)

for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
  if dpkg -l "$pkg" &>/dev/null 2>&1; then
    echo "  Removing: $pkg"
    apt-get remove --purge -y "$pkg" 2>/dev/null || true
  fi
done

apt-get autoremove -y 2>/dev/null || true
apt-get clean

echo "==> Cleanup complete"
