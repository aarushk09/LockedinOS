# LockedinOS v1 — QA Checklist

Use this checklist to validate each LockedinOS build before release.

## VM Testing (VirtualBox / QEMU)

### Boot & Login
- [ ] ISO boots in VirtualBox (UEFI mode)
- [ ] ISO boots in VirtualBox (Legacy BIOS mode)
- [ ] GRUB menu appears with LockedinOS branding
- [ ] Live session reaches GNOME desktop
- [ ] Desktop wallpaper is LockedinOS default
- [ ] Dock shows correct pinned apps (Tasks, Files, Terminal, Text Editor, Focus, Settings)

### Tasks & Calendar App
- [ ] App launches from dock icon
- [ ] App launches from application menu
- [ ] App launches from terminal: `lockedin-tasks`
- [ ] **Create** a new task with title, description, due date, priority, tags
- [ ] Task appears in task list
- [ ] Task with due date appears on calendar view
- [ ] **Edit** an existing task — changes persist
- [ ] **Delete** a task — removed from list and calendar
- [ ] **Complete** a task — checkbox toggles, strikethrough applied
- [ ] **Filter** tasks: All / Active / Completed
- [ ] **Search** tasks by title
- [ ] Calendar month view shows tasks on correct dates
- [ ] Calendar day view shows task details
- [ ] Calendar navigation: previous/next month, "Today" button
- [ ] Keyboard shortcut: Ctrl+N opens new task dialog
- [ ] Keyboard shortcut: Ctrl+S saves current task
- [ ] Data persists after closing and reopening app
- [ ] Data persists after logout/login
- [ ] SQLite DB exists at `~/.local/share/lockedin/tasks.db`

### Focus Mode
- [ ] `lockedin-focus status` shows "INACTIVE"
- [ ] `lockedin-focus on` enables DND + web blocking
- [ ] `lockedin-focus status` shows "ACTIVE"
- [ ] Notification banner: "Focus mode ENABLED"
- [ ] GNOME notifications are suppressed (test with `notify-send "test"`)
- [ ] Blocked websites return connection error in browser
- [ ] `lockedin-focus off` disables DND + web blocking
- [ ] Notification banner: "Focus mode DISABLED"
- [ ] Notifications resume after disabling
- [ ] Blocked websites accessible again
- [ ] `lockedin-focus toggle` switches state
- [ ] Focus Mode desktop entry exists in app menu

### System & Reliability
- [ ] Timeshift is installed (`which timeshift`)
- [ ] Timeshift config exists at `/etc/timeshift/timeshift.json`
- [ ] Flatpak is installed and Flathub remote configured
- [ ] GNOME Tweaks is accessible
- [ ] Dark theme is applied by default
- [ ] Battery percentage shown in top bar
- [ ] Touchpad tap-to-click enabled
- [ ] Window minimize/maximize/close buttons present

### First-Boot Wizard
- [ ] Wizard auto-launches on first login
- [ ] Name field works
- [ ] Email field works (optional)
- [ ] Focus preference selection works
- [ ] Preferences saved to `~/.config/lockedin/preferences.conf`
- [ ] Wizard does not launch on subsequent logins

### Security & Privacy
- [ ] No telemetry enabled by default
- [ ] No non-free drivers included (check `ubuntu-drivers list`)
- [ ] User data not stored in /root or live overlay
- [ ] Default browser (if installed) has no pre-configured accounts

---

## Real Hardware Testing (HP Laptop)

### Boot
- [ ] USB boot via UEFI
- [ ] USB boot via Legacy BIOS (if supported)
- [ ] Reaches GNOME desktop successfully

### Hardware Compatibility
- [ ] WiFi connects to network
- [ ] Ethernet works (if available)
- [ ] Bluetooth detected
- [ ] Touchpad gestures work (scroll, tap-to-click)
- [ ] Keyboard (all keys, function keys, brightness)
- [ ] Display: correct resolution detected
- [ ] Audio output (speakers)
- [ ] Audio input (microphone)
- [ ] Webcam detected
- [ ] Suspend/Resume works (close lid, reopen)
- [ ] Battery level detected and displayed

### Performance
- [ ] Desktop feels responsive (no lag)
- [ ] Tasks app opens within 3 seconds
- [ ] Memory usage < 2 GB at idle
- [ ] No kernel errors in `dmesg | grep -i error`

### Installation (if testing install to disk)
- [ ] Installer launches
- [ ] Disk partitioning works
- [ ] Installation completes successfully
- [ ] System boots from disk after install
- [ ] All features work post-install

---

## Automated Smoke Tests

Run the automated smoke test script:

```bash
sudo bash docs/smoke-test.sh
```

Expected output: all checks PASS.

---

## Test Report Template

```
# LockedinOS v1 Test Report
Date: YYYY-MM-DD
Tester: [Name]
ISO Version: LockedinOS-v1.0.0-amd64.iso
ISO SHA256: [hash]

## VM Testing
- VirtualBox Version: X.X.X
- Boot (UEFI): PASS/FAIL
- Boot (BIOS): PASS/FAIL
- Tasks App: PASS/FAIL
- Calendar: PASS/FAIL
- Focus Mode: PASS/FAIL
- Timeshift: PASS/FAIL
- First-Boot Wizard: PASS/FAIL

## Hardware Testing
- Device: HP [Model]
- Boot: PASS/FAIL
- WiFi: PASS/FAIL
- Touchpad: PASS/FAIL
- Suspend/Resume: PASS/FAIL
- Battery: PASS/FAIL

## Issues Found
1. [Description] — Severity: [Low/Medium/High/Critical]
2. ...

## Overall Verdict: PASS / FAIL
```
