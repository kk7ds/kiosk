#!/bin/sh

SRCISO="$1"
TMP="iso-build"
SRCDIR=$(readlink -f $(dirname $0))
PRESEED="kiosk-preseed.txt"
OUTPUT="kiosk-$(basename $SRCISO)"

if [ ! -f "$SRCISO" ]; then
    echo "Need path to source debian ISO"
    exit 1
fi

if [ -d "$TMP" ]; then
    chmod +w -R "$TMP"
    rm -Rf "$TMP"
fi
mkdir "$TMP"

cp "${SRCDIR}/${PRESEED}" preseed.cfg
xorriso -osirrox on -indev "$SRCISO" -extract / "$TMP"
chmod +w -R "${TMP}/install.amd" "${TMP}/md5sum.txt"
gunzip "${TMP}/install.amd/initrd.gz"
echo preseed.cfg | cpio -H newc -o -A -F "${TMP}/install.amd/initrd"
gzip "${TMP}/install.amd/initrd"
(cd "$TMP"; find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt)

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
   "$TMP"
