# LockedinOS v1 — Build Instructions

Complete guide to building LockedinOS from source.

## Prerequisites

### Host System

- **OS**: Ubuntu 22.04+ (native or WSL2) or any Debian-based Linux
- **RAM**: 8 GB minimum (16 GB recommended for ISO build)
- **Disk**: 50 GB free space
- **Internet**: Required for package downloads

### Required Tools

```bash
# System packages
sudo apt-get update
sudo apt-get install -y \
  git curl wget \
  build-essential \
  fakeroot dpkg-dev \
  squashfs-tools xorriso mtools \
  grub-pc-bin grub-efi-amd64-bin \
  isolinux syslinux-utils \
  qemu-system-x86 qemu-utils \
  virtualbox

# Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Cubic (optional, for GUI-based ISO customization)
sudo apt-add-repository ppa:cubic-wizard/release
sudo apt-get update
sudo apt-get install -y cubic

# Verify
node --version   # v18.x+
npm --version    # 9.x+
git --version
```

### VS Code + Remote WSL (Windows users)

1. Install [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) with Ubuntu
2. Install [VS Code](https://code.visualstudio.com/) + Remote WSL extension
3. Open the repo in WSL: `code .` from the WSL terminal

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/lockedinos/lockedinos.git
cd lockedinos
```

## Step 2: Build the Tasks & Calendar App

```bash
cd packages/tasks-calendar
npm install
npm run build:renderer

# Test locally (requires display or Xvfb)
npm start

# Build .deb package
chmod +x build-deb.sh
./build-deb.sh
# Output: build/lockedin-tasks-calendar_1.0.0_amd64.deb
```

## Step 3: Build the Focus Mode Package

```bash
cd packages/lockedin-focus
chmod +x build-deb.sh
./build-deb.sh
# Output: build/lockedin-focus_1.0.0_all.deb
```

## Step 4: Build the ISO

### Option A: Automated Script (Recommended)

```bash
# Download Ubuntu 24.04 LTS Desktop ISO
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso \
  -O /tmp/ubuntu-24.04-desktop-amd64.iso

# Build LockedinOS ISO
cd infra
sudo ./build-iso.sh /tmp/ubuntu-24.04-desktop-amd64.iso
# Output: release/LockedinOS-v1.0.0-amd64.iso
```

### Option B: Cubic (GUI)

1. Launch Cubic: `sudo cubic`
2. Create a new project directory
3. Select the Ubuntu 24.04 ISO as the source
4. In the chroot terminal, run:
   ```bash
   # Copy packages and scripts into the chroot first
   apt-get update
   bash /path/to/prepare-chroot.sh /path/to/deb-packages
   ```
5. Click Next → select xz compression → Generate

### Option C: live-build (Debian-style)

```bash
cd infra
sudo ./build-live-build.sh
# Output: release/LockedinOS-v1.0.0-amd64.iso
```

## Step 5: Test in a VM

### VirtualBox

1. Create a new VM: Type=Linux, Version=Ubuntu (64-bit)
2. RAM: 4096 MB, Disk: 25 GB (dynamically allocated)
3. Settings → Storage → Add optical drive → Select the ISO
4. Settings → System → Enable EFI (optional)
5. Start the VM

### QEMU (headless)

```bash
# UEFI boot
qemu-system-x86_64 \
  -m 4096 \
  -enable-kvm \
  -bios /usr/share/ovmf/OVMF.fd \
  -cdrom release/LockedinOS-v1.0.0-amd64.iso \
  -boot d \
  -vga virtio

# Legacy BIOS boot
qemu-system-x86_64 \
  -m 4096 \
  -enable-kvm \
  -cdrom release/LockedinOS-v1.0.0-amd64.iso \
  -boot d
```

## Step 6: Flash to USB (Real Hardware)

### Linux

```bash
sudo dd if=release/LockedinOS-v1.0.0-amd64.iso of=/dev/sdX bs=4M status=progress
sync
```

### Windows

Use [Rufus](https://rufus.ie/) or [Balena Etcher](https://www.balena.io/etcher/):
1. Select the ISO file
2. Select target USB drive (8 GB+)
3. Flash

### macOS

```bash
sudo dd if=LockedinOS-v1.0.0-amd64.iso of=/dev/rdiskN bs=4m
```

---

## Troubleshooting

### Build fails: "filesystem.squashfs not found"
The source ISO structure may differ. Check the ISO contents:
```bash
mount -o loop ubuntu.iso /mnt
find /mnt -name "*.squashfs"
```

### Electron app won't build: native module errors
Rebuild native modules for the correct Electron version:
```bash
cd packages/tasks-calendar
npx electron-rebuild
```

### WSL2: GUI apps don't display
Install WSLg support (Windows 11) or use Xvfb:
```bash
sudo apt-get install -y xvfb
xvfb-run npm start
```

---

## Directory Reference

| Path | Purpose |
|------|---------|
| `packages/tasks-calendar/` | Electron app source + .deb build |
| `packages/lockedin-focus/` | Focus mode script + .deb build |
| `configs/gnome/` | GNOME/dconf default settings |
| `configs/installer/` | First-boot wizard script |
| `iso-seed/` | Files overlaid onto the live filesystem |
| `infra/` | ISO build scripts |
| `docs/` | Documentation and QA checklists |
