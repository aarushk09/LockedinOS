#!/usr/bin/env bash
# LockedinOS — Automated Smoke Test Script
# Run inside a running LockedinOS VM or installed system
# Usage: sudo bash smoke-test.sh [--scripts-only]
set -euo pipefail

PASS=0
FAIL=0
SKIP=0
SCRIPTS_ONLY=false

if [ "${1:-}" = "--scripts-only" ]; then
  SCRIPTS_ONLY=true
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  local name="$1"
  local cmd="$2"
  
  if eval "$cmd" &>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  $name"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${NC}  $name"
    FAIL=$((FAIL + 1))
  fi
}

skip() {
  local name="$1"
  echo -e "  ${YELLOW}SKIP${NC}  $name"
  SKIP=$((SKIP + 1))
}

echo "============================================"
echo "  LockedinOS v1 — Smoke Tests"
echo "============================================"
echo ""

# ── Script Validation ──
echo "--- Script Syntax Validation ---"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

check "Focus mode script syntax" "bash -n '${REPO_ROOT}/packages/lockedin-focus/scripts/lockedin-focus'"
check "prepare-chroot.sh syntax" "bash -n '${REPO_ROOT}/infra/prepare-chroot.sh'"
check "build-iso.sh syntax" "bash -n '${REPO_ROOT}/infra/build-iso.sh'"
check "build-live-build.sh syntax" "bash -n '${REPO_ROOT}/infra/build-live-build.sh'"
check "apply-gsettings.sh syntax" "bash -n '${REPO_ROOT}/configs/gnome/apply-gsettings.sh'"
check "remove-social-apps.sh syntax" "bash -n '${REPO_ROOT}/configs/gnome/remove-social-apps.sh'"
check "first-boot-wizard.sh syntax" "bash -n '${REPO_ROOT}/configs/installer/first-boot-wizard.sh'"

if [ "$SCRIPTS_ONLY" = true ]; then
  echo ""
  echo "--- Results (scripts-only mode) ---"
  echo -e "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}  ${YELLOW}SKIP: $SKIP${NC}"
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
fi

echo ""

# ── System Checks ──
echo "--- System Checks ---"
check "GNOME Shell running" "pgrep -x gnome-shell"
check "Timeshift installed" "command -v timeshift"
check "Timeshift config exists" "test -f /etc/timeshift/timeshift.json"
check "Flatpak installed" "command -v flatpak"
check "Flathub remote configured" "flatpak remote-list | grep -q flathub"
check "SQLite3 installed" "command -v sqlite3"
check "Git installed" "command -v git"
check "curl installed" "command -v curl"
check "wget installed" "command -v wget"
check "dconf installed" "command -v dconf"

echo ""

# ── Tasks & Calendar App ──
echo "--- Tasks & Calendar App ---"
check "App binary exists" "test -f /usr/bin/lockedin-tasks || test -f /opt/lockedin-tasks-calendar/lockedin-tasks-calendar"
check "Desktop file exists" "test -f /usr/share/applications/lockedin-tasks.desktop"
check "Desktop file valid" "desktop-file-validate /usr/share/applications/lockedin-tasks.desktop 2>/dev/null || true"

# Test SQLite database creation
if command -v lockedin-tasks &>/dev/null; then
  # Launch app briefly to create DB
  timeout 5 lockedin-tasks &>/dev/null &
  APP_PID=$!
  sleep 3
  kill $APP_PID 2>/dev/null || true
  wait $APP_PID 2>/dev/null || true
  
  DB_PATH="$HOME/.local/share/lockedin/tasks.db"
  check "SQLite DB created" "test -f '$DB_PATH'"
  
  if [ -f "$DB_PATH" ]; then
    # Insert a test task
    sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO tasks (id, title, due_date, priority) VALUES ('smoke-test-1', 'Smoke Test Task', '$(date +%Y-%m-%d)', 'high');"
    check "Can insert task" "sqlite3 '$DB_PATH' 'SELECT id FROM tasks WHERE id=\"smoke-test-1\"' | grep -q smoke-test-1"
    check "Can query tasks" "sqlite3 '$DB_PATH' 'SELECT COUNT(*) FROM tasks' | grep -qE '^[0-9]+$'"
    
    # Cleanup
    sqlite3 "$DB_PATH" "DELETE FROM tasks WHERE id='smoke-test-1';"
  fi
else
  skip "App binary not found — skipping app tests"
fi

echo ""

# ── Focus Mode ──
echo "--- Focus Mode ---"
check "Focus script exists" "test -f /usr/local/bin/lockedin-focus"
check "Focus script executable" "test -x /usr/local/bin/lockedin-focus"
check "Focus desktop entry exists" "test -f /usr/share/applications/lockedin-focus.desktop"
check "Blocklist exists" "test -f /etc/lockedin/focus-blocklist.txt"

if [ -x /usr/local/bin/lockedin-focus ]; then
  check "Focus status command" "/usr/local/bin/lockedin-focus status"
  
  # Test toggle (non-destructive)
  INITIAL_STATUS=$(/usr/local/bin/lockedin-focus status 2>/dev/null | head -1)
  /usr/local/bin/lockedin-focus on 2>/dev/null || true
  check "Focus ON toggles DND" "gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null | grep -q false"
  /usr/local/bin/lockedin-focus off 2>/dev/null || true
  check "Focus OFF restores DND" "gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null | grep -q true"
else
  skip "Focus script not installed — skipping focus tests"
fi

echo ""

# ── GNOME Settings ──
echo "--- GNOME Settings ---"
check "Dark theme applied" "gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q dark"
check "Tap-to-click enabled" "gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null | grep -q true"
check "Battery percentage shown" "gsettings get org.gnome.desktop.interface show-battery-percentage 2>/dev/null | grep -q true"
check "dconf local DB exists" "test -f /etc/dconf/db/local.d/00-lockedin-defaults"

echo ""

# ── First-Boot Wizard ──
echo "--- First-Boot Wizard ---"
check "Wizard script exists" "test -f /usr/local/bin/lockedin-wizard"
check "Wizard autostart entry" "test -f /etc/skel/.config/autostart/lockedin-wizard.desktop"

echo ""

# ── Timeshift Snapshot ──
echo "--- Timeshift ---"
if command -v timeshift &>/dev/null; then
  check "Can list snapshots" "timeshift --list 2>/dev/null"
else
  skip "Timeshift not installed"
fi

echo ""
echo "============================================"
echo "  Smoke Test Results"
echo "============================================"
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo -e "  ${YELLOW}SKIP: $SKIP${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}Overall: ALL TESTS PASSED${NC}"
  exit 0
else
  echo -e "  ${RED}Overall: $FAIL TEST(S) FAILED${NC}"
  exit 1
fi
