#!/bin/sh

# This repacks a debian iso with:
# 1. Our preseed config file for automated installation
# 2. A payload partition with the ansible playbook ready to go

SRCISO="$1"
TMP="iso-build"
SRCDIR=$(readlink -f $(dirname $0))
PRESEED="kiosk-preseed.txt"
OUTPUT="kiosk-$(basename $SRCISO)"

if [ ! -f "$SRCISO" ]; then
    echo "Need path to source debian ISO"
    exit 1
fi

# TMP is where we will unpack and modify the iso
if [ -d "$TMP" ]; then
    chmod +w -R "$TMP"
    rm -Rf "$TMP"
fi
mkdir "$TMP"

# Copy our preseed into the initrd and repackage it
cp "${SRCDIR}/${PRESEED}" preseed.cfg
xorriso -osirrox on -indev "$SRCISO" -extract / "$TMP"
chmod +w -R "${TMP}/install.amd" "${TMP}/md5sum.txt" "${TMP}/boot/grub"
gunzip "${TMP}/install.amd/initrd.gz"
echo preseed.cfg | cpio -H newc -o -A -F "${TMP}/install.amd/initrd"
gzip "${TMP}/install.amd/initrd"
(cd "$TMP"; find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt)

# Create a FAT image file and copy our playbook into it
dd if=/dev/zero of=payload.vfat bs=1M count=256
mkfs.vfat -n kiosk payload.vfat
mcopy -s -i payload.vfat ${SRCDIR}/../{playbook.yaml,roles,runlocal.sh} ::

# Remove graphical install boot target
sed -ie '/Graphical/,+4d' ${TMP}/boot/grub/grub.cfg

# Repack the ISO to kiosk-$SRCISO
xorriso -as mkisofs \
   -r \
   -o "${OUTPUT}" \
   -J -J -joliet-long -cache-inodes \
   -b isolinux/isolinux.bin \
   -c isolinux/boot.cat \
   -boot-load-size 4 -boot-info-table -no-emul-boot \
   -eltorito-alt-boot \
   -e boot/grub/efi.img \
   -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
   -no-emul-boot -isohybrid-gpt-basdat \
   -append_partition 3 0x0c payload.vfat \
   "$TMP"
