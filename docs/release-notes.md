# LockedinOS v1.0.0 — Release Notes

**Release Date**: 2026-02-17  
**Base**: Ubuntu 24.04 LTS (Noble Numbat)  
**Architecture**: amd64 (64-bit)  
**ISO Size**: ~4 GB (estimated)

---

## What's New

LockedinOS v1.0.0 is the first release of a student-focused Linux distribution built on Ubuntu LTS. It provides a distraction-free desktop experience with integrated productivity tools.

### Core Features

#### Tasks & Calendar App
- Full CRUD task management (create, read, update, delete)
- Task properties: title, description, due date, priority (low/medium/high/urgent), tags
- Task filtering: All / Active / Completed
- Task search by title
- Calendar with month and day views
- Tasks with due dates appear on the calendar
- Keyboard shortcuts: Ctrl+N (new task), Ctrl+S (save)
- Local SQLite database persistence (`~/.local/share/lockedin/tasks.db`)
- Dark-themed, modern UI

#### Focus Mode
- One-click toggle to enable/disable focus mode
- Do Not Disturb: suppresses GNOME notification banners
- Website blocking: blocks distracting sites (social media, streaming) via `/etc/hosts`
- Customizable blocklist at `/etc/lockedin/focus-blocklist.txt`
- CLI tool: `lockedin-focus {on|off|toggle|status}`
- Desktop shortcut in app menu
- Optional systemd daemon

#### Desktop Customization
- Dark Adwaita theme by default
- Customized dock with productivity-focused apps
- Touchpad tap-to-click enabled
- Battery percentage in top bar
- Window minimize/maximize/close buttons
- Reduced notification clutter
- Removed unnecessary default apps (games, social apps)

#### System Reliability
- Timeshift snapshots enabled by default (daily + weekly)
- Flatpak + Flathub configured for sandboxed app installation
- First-boot setup wizard for personalization

### Included Packages
- GNOME Shell desktop environment
- LockedIn Tasks & Calendar (Electron app)
- LockedIn Focus Mode (bash CLI tool)
- Timeshift (system snapshots)
- Flatpak + GNOME Software Plugin
- SQLite3, Python3, Git, curl, wget
- GNOME Tweaks, GParted, htop, neofetch

---

## Known Issues

1. **Focus Mode web blocking requires root** — The `/etc/hosts` modification uses `pkexec` which prompts for a password. Future versions may use a systemd service to handle this transparently.

2. **Cubic scripting limitations** — Cubic is primarily a GUI tool. The `build-iso.sh` script replicates Cubic's workflow programmatically but may need adjustments for different Ubuntu ISO structures.

3. **No cloud sync** — Tasks & Calendar data is local-only in v1. Cloud sync is planned for v2.

4. **No non-free drivers** — WiFi and GPU drivers may need manual installation on some hardware. Run `sudo ubuntu-drivers autoinstall` after booting.

5. **First-boot wizard requires zenity** — If zenity is not available, the wizard silently skips.

---

## Upgrade Path

LockedinOS v1 is based on Ubuntu 24.04 LTS and receives standard Ubuntu security updates via `apt`. The LockedinOS-specific packages (tasks-calendar, focus-mode) will be updated via the project's GitHub releases.

---

## System Requirements

| Component | Minimum       | Recommended   |
|-----------|---------------|---------------|
| CPU       | 2-core 64-bit | 4-core 64-bit |
| RAM       | 4 GB          | 8 GB          |
| Storage   | 25 GB         | 50 GB         |
| Boot      | UEFI or BIOS  | UEFI          |

---

## Build Information

- Build system: `infra/build-iso.sh` (xorriso + chroot) or Cubic GUI
- Alternative: `infra/build-live-build.sh` (Debian live-build)
- CI: GitHub Actions (lint, test, .deb builds)
- Full build instructions: [docs/build-instructions.md](build-instructions.md)

---

## Credits

LockedinOS is built by students, for students. Contributions welcome at [GitHub](https://github.com/lockedinos/lockedinos).
