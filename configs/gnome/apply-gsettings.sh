#!/usr/bin/env bash
# Apply LockedinOS GNOME default settings via dconf
# Run this inside the chroot during ISO build or as a user script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DCONF_DIR="/etc/dconf/db/local.d"
DCONF_PROFILE_DIR="/etc/dconf/profile"

echo "==> Applying LockedinOS GNOME defaults"

# Ensure dconf directories exist
mkdir -p "$DCONF_DIR"
mkdir -p "$DCONF_PROFILE_DIR"

# Copy dconf settings
cp "${SCRIPT_DIR}/lockedin-defaults.ini" "${DCONF_DIR}/00-lockedin-defaults"

# Create dconf profile
cat > "${DCONF_PROFILE_DIR}/user" << 'EOF'
user-db:user
system-db:local
EOF

# Update dconf database
dconf update

echo "==> GNOME defaults applied"

# Set favorite apps via gsettings (for current user session)
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  gsettings set org.gnome.shell favorite-apps \
    "['lockedin-tasks.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'lockedin-focus.desktop', 'org.gnome.Settings.desktop']" \
    2>/dev/null || true
  echo "==> Favorites set for current user"
fi
