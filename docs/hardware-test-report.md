# LockedinOS v1 — Hardware Test Report Template

## Test Environment

| Field | Value |
|-------|-------|
| ISO Version | LockedinOS-v1.0.0-amd64.iso |
| ISO SHA256 | `[paste hash]` |
| Test Date | YYYY-MM-DD |
| Tester | [Name] |
| Device | HP [Model Name] |
| CPU | [e.g., Intel Core i5-1235U] |
| RAM | [e.g., 8 GB DDR4] |
| Storage | [e.g., 256 GB NVMe SSD] |
| WiFi | [e.g., Intel AX211] |
| GPU | [e.g., Intel Iris Xe] |
| Boot Method | USB (Rufus / dd) |

## Boot Test

| Test | Result | Notes |
|------|--------|-------|
| UEFI Boot | PASS/FAIL | |
| Legacy BIOS Boot | PASS/FAIL/N/A | |
| GRUB Menu Visible | PASS/FAIL | |
| Live Session Loads | PASS/FAIL | Time to desktop: ___s |
| Display Resolution | PASS/FAIL | Detected: ____x____ |

## Hardware Compatibility

| Component | Result | Notes |
|-----------|--------|-------|
| WiFi | PASS/FAIL | Network: ____ |
| Ethernet | PASS/FAIL/N/A | |
| Bluetooth | PASS/FAIL | |
| Touchpad (basic) | PASS/FAIL | |
| Touchpad (gestures) | PASS/FAIL | |
| Keyboard (standard) | PASS/FAIL | |
| Function keys | PASS/FAIL | Brightness: Y/N, Volume: Y/N |
| Speakers | PASS/FAIL | |
| Microphone | PASS/FAIL | |
| Webcam | PASS/FAIL | |
| USB ports | PASS/FAIL | |
| HDMI/DisplayPort | PASS/FAIL/N/A | |
| SD card reader | PASS/FAIL/N/A | |

## Power Management

| Test | Result | Notes |
|------|--------|-------|
| Battery detected | PASS/FAIL | Level: ___% |
| Battery % in top bar | PASS/FAIL | |
| Suspend (lid close) | PASS/FAIL | |
| Resume (lid open) | PASS/FAIL | |
| Sleep (menu) | PASS/FAIL | |
| Shutdown | PASS/FAIL | |
| Reboot | PASS/FAIL | |

## App Testing on Hardware

| Test | Result | Notes |
|------|--------|-------|
| Tasks app launches | PASS/FAIL | Launch time: ___s |
| Create task | PASS/FAIL | |
| Calendar view | PASS/FAIL | |
| Focus mode on | PASS/FAIL | |
| Focus mode off | PASS/FAIL | |
| Timeshift available | PASS/FAIL | |

## Performance

| Metric | Value |
|--------|-------|
| Boot time (GRUB → desktop) | ___s |
| RAM usage (idle) | ___ MB |
| Tasks app launch time | ___s |
| Battery life estimate | ___ hours |

## Issues Found

| # | Description | Severity | Workaround |
|---|-------------|----------|------------|
| 1 | | Low/Med/High/Crit | |
| 2 | | | |

## Non-Free Driver Notes

```bash
# Run after booting to check needed drivers:
sudo ubuntu-drivers list
# Install if needed:
sudo ubuntu-drivers autoinstall
```

Drivers needed: [list any]

## Overall Verdict

**PASS / FAIL** (with notes)

## Screenshots

[Attach screenshots of desktop, app, focus mode toggle]
