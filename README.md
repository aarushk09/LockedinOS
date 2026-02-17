# LockedinOS v1

A student-focused Linux distribution built on Ubuntu LTS, designed for distraction-free productivity.

## Features

- **Tasks & Calendar** — Preinstalled Electron app with task management (CRUD, priorities, tags, due dates) and a calendar view. Data persisted locally in SQLite.
- **Focus Mode** — One-click toggle that enables Do Not Disturb and blocks distracting websites via `/etc/hosts`.
- **Timeshift Snapshots** — Automatic system snapshots enabled by default for easy rollback.
- **Flatpak Sandboxing** — Optional apps installed via Flatpak for isolation and security.
- **Minimal & Clean Desktop** — Customized GNOME desktop with reduced distractions, student-friendly defaults, and a lean dock.

## Repository Structure

```
lockedinos/
├── .github/workflows/       # CI/CD (GitHub Actions)
├── docs/                    # Build notes, QA checklist, release notes
├── infra/                   # ISO build scripts, Cubic config
│   ├── cubic-config/
│   ├── build-iso.sh
│   ├── build-live-build.sh
│   └── prepare-chroot.sh
├── packages/
│   ├── tasks-calendar/      # Electron + React app source, .deb packaging
│   └── lockedin-focus/      # Focus-mode daemon/scripts, .deb packaging
├── configs/
│   ├── gnome/               # GNOME/dconf settings
│   └── installer/           # Installer customization
├── iso-seed/                # Files overlaid onto the live filesystem
└── README.md
```

## Quick Start

### Prerequisites

- Ubuntu 22.04+ (or WSL2 with Ubuntu) for building
- Node.js 18+ and npm
- `dpkg-deb`, `cubic`, VirtualBox (for testing)
- Git

### Build the Tasks & Calendar App

```bash
cd packages/tasks-calendar
npm install
npm run build
./build-deb.sh
```

### Build the ISO

```bash
cd infra
sudo ./build-iso.sh /path/to/ubuntu-24.04.4-desktop-amd64.iso
```

See [docs/build-instructions.md](docs/build-instructions.md) for full details.

## System Requirements

| Component | Minimum       | Recommended   |
|-----------|---------------|---------------|
| CPU       | 2-core 64-bit | 4-core 64-bit |
| RAM       | 4 GB          | 8 GB          |
| Storage   | 25 GB         | 50 GB         |
| Boot      | UEFI or BIOS  | UEFI          |

## Default Packages

- GNOME Shell, Control Center, Tweaks
- Timeshift
- Flatpak + GNOME Software Plugin
- SQLite3, Python3, Git, curl, wget
- LockedIn Tasks & Calendar (`.deb`)
- LockedIn Focus Mode (`.deb`)
- Firefox (Flatpak, optional)

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Push and open a Pull Request

See [docs/build-instructions.md](docs/build-instructions.md) for development setup.
