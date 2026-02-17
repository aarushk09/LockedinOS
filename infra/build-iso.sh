#!/usr/bin/env bash
# LockedinOS — Automated ISO Build Script (Cubic-based)
# Usage: sudo ./build-iso.sh /path/to/ubuntu-24.04.4-desktop-amd64.iso [output-dir]
#
# This script automates the Cubic workflow:
# 1. Extracts the Ubuntu ISO
# 2. Prepares a chroot environment
# 3. Installs LockedinOS customizations
# 4. Repacks into a new ISO
# 5. Generates SHA256 checksum
#
# Requirements: xorriso, squashfs-tools, dpkg-deb, fakeroot (Cubic is optional for GUI use only)
set -euo pipefail

# ── Configuration ──
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_ISO="${1:-}"
OUTPUT_DIR="${2:-${REPO_ROOT}/release}"
WORK_DIR="${SCRIPT_DIR}/cubic-work"
ISO_NAME="LockedinOS-v1.0.0-amd64"
ISO_LABEL="LockedinOS v1"

if [ -z "$SOURCE_ISO" ]; then
  echo "Usage: sudo $0 /path/to/ubuntu-24.04.4-desktop-amd64.iso [output-dir]"
  echo ""
  echo "Download Ubuntu 24.04 LTS Desktop ISO from:"
  echo "  https://releases.ubuntu.com/24.04/"
  exit 1
fi

if [ ! -f "$SOURCE_ISO" ]; then
  echo "ERROR: Source ISO not found: $SOURCE_ISO"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root (sudo)"
  exit 1
fi

echo "============================================"
echo "  LockedinOS v1 — ISO Build"
echo "============================================"
echo "Source ISO: $SOURCE_ISO"
echo "Output dir: $OUTPUT_DIR"
echo "Work dir:   $WORK_DIR"
echo ""

# ── Step 1: Install build dependencies ──
echo "==> [1/8] Installing build dependencies..."
apt-get update
apt-get install -y \
  xorriso \
  squashfs-tools \
  mtools \
  grub-pc-bin \
  grub-efi-amd64-bin \
  isolinux \
  syslinux-utils \
  fakeroot \
  dpkg-dev

# ── Step 2: Build .deb packages ──
echo ""
echo "==> [2/8] Building .deb packages..."
mkdir -p "${WORK_DIR}/packages"

# Build tasks-calendar .deb
if [ -f "${REPO_ROOT}/packages/tasks-calendar/build-deb.sh" ]; then
  echo "  Building lockedin-tasks-calendar..."
  cd "${REPO_ROOT}/packages/tasks-calendar"
  
  # Ensure Node.js is available
  if ! command -v node &>/dev/null; then
    echo "  Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
  fi
  
  bash build-deb.sh
  cp build/*.deb "${WORK_DIR}/packages/" 2>/dev/null || true
fi

# Build lockedin-focus .deb
if [ -f "${REPO_ROOT}/packages/lockedin-focus/build-deb.sh" ]; then
  echo "  Building lockedin-focus..."
  cd "${REPO_ROOT}/packages/lockedin-focus"
  bash build-deb.sh
  cp build/*.deb "${WORK_DIR}/packages/" 2>/dev/null || true
fi

# ── Step 3: Extract source ISO ──
echo ""
echo "==> [3/8] Extracting source ISO..."
EXTRACT_DIR="${WORK_DIR}/extract"
SQUASHFS_DIR="${WORK_DIR}/squashfs"
CHROOT_DIR="${WORK_DIR}/chroot"

rm -rf "$EXTRACT_DIR" "$SQUASHFS_DIR" "$CHROOT_DIR"
mkdir -p "$EXTRACT_DIR" "$SQUASHFS_DIR" "$CHROOT_DIR"

# Mount and copy ISO contents
MOUNT_DIR=$(mktemp -d)
mount -o loop "$SOURCE_ISO" "$MOUNT_DIR"
cp -a "$MOUNT_DIR"/* "$EXTRACT_DIR/" || true
cp -a "$MOUNT_DIR"/.* "$EXTRACT_DIR/" 2>/dev/null || true
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

# Find and extract squashfs
SQUASHFS_FILE=$(find "$EXTRACT_DIR" -name "filesystem.squashfs" -type f | head -1)
if [ -z "$SQUASHFS_FILE" ]; then
  echo "ERROR: filesystem.squashfs not found in ISO"
  exit 1
fi

echo "  Found squashfs: $SQUASHFS_FILE"
unsquashfs -d "$CHROOT_DIR" "$SQUASHFS_FILE"

# ── Step 4: Prepare chroot ──
echo ""
echo "==> [4/8] Setting up chroot environment..."

# Mount necessary filesystems
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount -t proc proc "$CHROOT_DIR/proc"
mount -t sysfs sysfs "$CHROOT_DIR/sys"
mount -t tmpfs tmpfs "$CHROOT_DIR/tmp"

# Copy resolv.conf for network access
cp /etc/resolv.conf "$CHROOT_DIR/etc/resolv.conf"

# Copy packages into chroot
mkdir -p "$CHROOT_DIR/tmp/lockedin-packages"
cp "${WORK_DIR}/packages/"*.deb "$CHROOT_DIR/tmp/lockedin-packages/" 2>/dev/null || true

# Copy repo into chroot
mkdir -p "$CHROOT_DIR/tmp/lockedinos-repo"
cp -r "${REPO_ROOT}/configs" "$CHROOT_DIR/tmp/lockedinos-repo/"
cp -r "${REPO_ROOT}/iso-seed" "$CHROOT_DIR/tmp/lockedinos-repo/"
cp "${REPO_ROOT}/infra/prepare-chroot.sh" "$CHROOT_DIR/tmp/lockedinos-repo/"

# ── Step 5: Run customization inside chroot ──
echo ""
echo "==> [5/8] Running chroot customization..."
chroot "$CHROOT_DIR" /bin/bash -c "
  cd /tmp/lockedinos-repo
  export DEBIAN_FRONTEND=noninteractive
  bash prepare-chroot.sh /tmp/lockedin-packages
"

# ── Step 6: Cleanup chroot ──
echo ""
echo "==> [6/8] Cleaning up chroot..."

# Cleanup temporary files
rm -rf "$CHROOT_DIR/tmp/lockedin-packages"
rm -rf "$CHROOT_DIR/tmp/lockedinos-repo"

# Unmount chroot filesystems
umount "$CHROOT_DIR/tmp" 2>/dev/null || true
umount "$CHROOT_DIR/sys" 2>/dev/null || true
umount "$CHROOT_DIR/proc" 2>/dev/null || true
umount "$CHROOT_DIR/dev/pts" 2>/dev/null || true
umount "$CHROOT_DIR/dev" 2>/dev/null || true

# ── Step 7: Repack squashfs and ISO ──
echo ""
echo "==> [7/8] Repacking filesystem and ISO..."

# Remove old squashfs
rm -f "$SQUASHFS_FILE"

# Create new squashfs
mksquashfs "$CHROOT_DIR" "$SQUASHFS_FILE" \
  -comp xz -b 1M -Xdict-size 100% \
  -noappend

# Update filesystem.size
printf "%s" "$(du -sx --block-size=1 "$CHROOT_DIR" | cut -f1)" > \
  "$(dirname "$SQUASHFS_FILE")/filesystem.size"

# Update checksums
cd "$EXTRACT_DIR"
find . -type f -print0 | xargs -0 md5sum 2>/dev/null | \
  grep -v isolinux/boot.cat | grep -v md5sum.txt > md5sum.txt || true

# Create ISO
mkdir -p "$OUTPUT_DIR"
ISO_PATH="${OUTPUT_DIR}/${ISO_NAME}.iso"

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "$ISO_LABEL" \
  -eltorito-boot isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog isolinux/boot.cat \
  -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
  -output "$ISO_PATH" \
  "$EXTRACT_DIR" 2>/dev/null || {
    # Fallback for Ubuntu ISOs without isolinux (newer UEFI-only ISOs)
    xorriso -as mkisofs \
      -iso-level 3 \
      -full-iso9660-filenames \
      -volid "$ISO_LABEL" \
      -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
      -output "$ISO_PATH" \
      "$EXTRACT_DIR"
  }

# ── Step 8: Generate checksum and manifest ──
echo ""
echo "==> [8/8] Generating checksum and manifest..."

cd "$OUTPUT_DIR"
sha256sum "${ISO_NAME}.iso" > "${ISO_NAME}.iso.sha256"

cat > "${ISO_NAME}-manifest.txt" << EOF
LockedinOS v1.0.0 Release Manifest
====================================
Build Date: $(date -Iseconds)
Base ISO: $(basename "$SOURCE_ISO")
Source SHA256: $(sha256sum "$SOURCE_ISO" | cut -d' ' -f1)

Output ISO: ${ISO_NAME}.iso
ISO SHA256: $(cat "${ISO_NAME}.iso.sha256" | cut -d' ' -f1)
ISO Size: $(du -h "${ISO_NAME}.iso" | cut -f1)

Included Packages:
$(ls "${WORK_DIR}/packages/"*.deb 2>/dev/null | while read f; do echo "  - $(basename "$f")"; done)

Build Host: $(uname -a)
EOF

# Cleanup work directory
echo ""
echo "==> Cleaning up work directory..."
rm -rf "$CHROOT_DIR"

echo ""
echo "============================================"
echo "  LockedinOS ISO Build Complete!"
echo "============================================"
echo "ISO:      ${ISO_PATH}"
echo "SHA256:   $(cat "${OUTPUT_DIR}/${ISO_NAME}.iso.sha256")"
echo "Manifest: ${OUTPUT_DIR}/${ISO_NAME}-manifest.txt"
echo ""
echo "Flash to USB: sudo dd if=${ISO_PATH} of=/dev/sdX bs=4M status=progress"
echo "Or use Rufus (Windows) / Balena Etcher (cross-platform)"
