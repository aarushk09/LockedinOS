#!/usr/bin/env bash
# LockedinOS — Automated ISO Build Script (Cubic-based)
# Usage: sudo ./build-iso.sh /path/to/ubuntu.iso [output-dir]
#
# When output-dir is given (e.g. /storage), the final ISO and all build
# intermediates (extract, chroot) are stored there to avoid running out of space.
#
# Example with 50GB /storage disk:
#   sudo ./infra/build-iso.sh /storage/ubuntu.iso /storage
#
set -euo pipefail

# ── Configuration ──
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_ISO="${1:-}"
OUTPUT_DIR="${2:-${REPO_ROOT}/release}"
# Put work dir on same filesystem as output when output-dir is explicit (saves space on repo disk)
if [ -n "${2:-}" ]; then
  WORK_DIR="${OUTPUT_DIR}/.lockedinos-build"
else
  WORK_DIR="${SCRIPT_DIR}/cubic-work"
fi
ISO_NAME="LockedinOS-v1.0.0-amd64"
ISO_LABEL="LockedinOS v1"

if [ -z "$SOURCE_ISO" ]; then
  echo "Usage: sudo $0 /path/to/ubuntu.iso [output-dir]"
  echo ""
  echo "Examples:"
  echo "  sudo $0 /tmp/ubuntu.iso"
  echo "  sudo $0 /storage/ubuntu.iso /storage   # use /storage for ISO + build (needs ~15GB free)"
  echo ""
  echo "Download Ubuntu 24.04 LTS: https://releases.ubuntu.com/24.04/"
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

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

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
  dpkg-dev \
  genisoimage

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

# Find and extract squashfs (Ubuntu 24.04+ may use filesystem.squashfs or main .squashfs in casper/)
SQUASHFS_FILE=""
for candidate in "${EXTRACT_DIR}/casper/filesystem.squashfs" "${EXTRACT_DIR}/live/filesystem.squashfs"; do
  if [ -f "$candidate" ]; then
    SQUASHFS_FILE="$candidate"
    break
  fi
done
if [ -z "$SQUASHFS_FILE" ]; then
  # Fallback: any filesystem.squashfs anywhere
  SQUASHFS_FILE=$(find "$EXTRACT_DIR" -name "filesystem.squashfs" -type f 2>/dev/null | head -1)
fi
if [ -z "$SQUASHFS_FILE" ]; then
  # Ubuntu 24.04+ split layout: use largest .squashfs that is not *.live.squashfs (main root)
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] && SQUASHFS_FILE="$f" && break
  done < <(find "$EXTRACT_DIR" -name "*.squashfs" -type f ! -name "*.live.squashfs" -printf '%s %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
fi
if [ -z "$SQUASHFS_FILE" ] || [ ! -f "$SQUASHFS_FILE" ]; then
  # Last resort: any .squashfs (e.g. single file)
  SQUASHFS_FILE=$(find "$EXTRACT_DIR" -name "*.squashfs" -type f 2>/dev/null | head -1)
fi
if [ -z "$SQUASHFS_FILE" ] || [ ! -f "$SQUASHFS_FILE" ]; then
  echo "ERROR: No squashfs found in ISO. Top-level contents:"
  ls -la "$EXTRACT_DIR" 2>/dev/null || true
  echo "All .squashfs files:"
  find "$EXTRACT_DIR" -name "*.squashfs" -type f 2>/dev/null || true
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

# Update size file (casper expects filesystem.size or <name>.size for <name>.squashfs)
SQUASHFS_DIR=$(dirname "$SQUASHFS_FILE")
SQUASHFS_BASE=$(basename "$SQUASHFS_FILE" .squashfs)
SIZE_BYTES=$(du -sx --block-size=1 "$CHROOT_DIR" | cut -f1)
printf "%s" "$SIZE_BYTES" > "${SQUASHFS_DIR}/filesystem.size"
printf "%s" "$SIZE_BYTES" > "${SQUASHFS_DIR}/${SQUASHFS_BASE}.size"

# Update checksums
cd "$EXTRACT_DIR"
find . -type f -print0 | xargs -0 md5sum 2>/dev/null | \
  grep -v isolinux/boot.cat | grep -v md5sum.txt > md5sum.txt || true

# Create ISO (detect boot layout: Ubuntu 24.04+ may not have boot/grub/efi.img or isolinux)
mkdir -p "$OUTPUT_DIR"
ISO_PATH="${OUTPUT_DIR}/${ISO_NAME}.iso"

# ISO9660 volid: no spaces, prefer uppercase (max 32 chars)
VOLID="LOCKEDINOS_V1"

# Detect UEFI boot image (various Ubuntu layouts)
EFI_IMG=""
for p in boot/grub/efi.img boot/efi.img EFI/boot/bootx64.efi; do
  if [ -f "${EXTRACT_DIR}/${p}" ]; then
    EFI_IMG="$p"
    echo "  Using UEFI boot: $p"
    break
  fi
done
if [ -z "$EFI_IMG" ]; then
  # Fallback: first efi.img or bootx64.efi found (relative to EXTRACT_DIR)
  FOUND=$(find "$EXTRACT_DIR" -type f \( -name "efi.img" -o -name "bootx64.efi" \) 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then
    EFI_IMG="${FOUND#${EXTRACT_DIR}/}"
    echo "  Using UEFI boot: $EFI_IMG"
  fi
fi

# Build xorriso args: legacy BIOS (isolinux) if present
XORRISO_EXTRA=()
if [ -f "${EXTRACT_DIR}/isolinux/isolinux.bin" ]; then
  echo "  Using legacy BIOS boot: isolinux"
  XORRISO_EXTRA+=(
    -eltorito-boot isolinux/isolinux.bin
    -no-emul-boot
    -boot-load-size 4
    -boot-info-table
    --eltorito-catalog isolinux/boot.cat
  )
fi

# Add UEFI boot only if we found an EFI image
if [ -n "$EFI_IMG" ]; then
  XORRISO_EXTRA+=(
    -eltorito-alt-boot
    -e "$EFI_IMG"
    -no-emul-boot
    -isohybrid-gpt-basdat
  )
fi

# Create ISO: xorriso has a ~4GB "free space on media" bug; use genisoimage for large ISOs when available.
CREATE_ISO() {
  local ok=0
  rm -f "$ISO_PATH"

  # Prefer genisoimage (no size limit); then xorriso with pre-allocated file
  if command -v genisoimage &>/dev/null; then
    echo "  Creating ISO with genisoimage..."
    local geniso_args=(-o "$ISO_PATH" -iso-level 3 -full-iso9660-filenames -V "$VOLID" -r -J)
    if [ -f "${EXTRACT_DIR}/isolinux/isolinux.bin" ]; then
      geniso_args+=(-b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table)
    fi
    if [ -n "$EFI_IMG" ]; then
      geniso_args+=(-eltorito-alt-boot -e "$EFI_IMG" -no-emul-boot)
    fi
    if genisoimage "${geniso_args[@]}" "$EXTRACT_DIR"; then
      ok=1
      command -v isohybrid &>/dev/null && isohybrid --uefi "$ISO_PATH" 2>/dev/null || true
    fi
  fi

  if [ "$ok" -eq 0 ]; then
    echo "  Creating ISO with xorriso (pre-allocating 10G to avoid size limit)..."
    truncate -s 10G "$ISO_PATH" 2>/dev/null || true
    if xorriso -as mkisofs \
      -iso-level 3 \
      -full-iso9660-filenames \
      -volid "$VOLID" \
      "${XORRISO_EXTRA[@]}" \
      -output "$ISO_PATH" \
      "$EXTRACT_DIR"; then
      ok=1
      # Note: with pre-allocate, the file may be 10GB on disk; the ISO content is smaller
    fi
  fi

  return "$((1 - ok))"
}

if ! CREATE_ISO; then
  echo "ERROR: Failed to create ISO. Install genisoimage: apt-get install genisoimage"
  exit 1
fi

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
