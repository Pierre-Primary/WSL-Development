#!/usr/bin/env sh
set -ex

cd "$(dirname "$0")"

apk add e2fsprogs e2fsprogs-extra util-linux

TAR_FILE=$(./tar-get-by-docker.sh "3.16")
IMG_FILE="$(dirname "$TAR_FILE")/$(basename "$TAR_FILE" .tar).img"

DU_SIZE=$(du -sb "$TAR_FILE" | awk '{print $1}')
FCST_SIZE=$(tar tvf "$TAR_FILE" | awk '{sum+=$3} END {print sum}')
TARGET_SIZE=$((FCST_SIZE + DU_SIZE))

echo $TARGET_SIZE

dd if=/dev/zero of="$IMG_FILE" bs="${TARGET_SIZE}" count=1

mkfs.ext4 -O ^has_journal "$IMG_FILE"

TEMP_DIR=$(mktemp -d)
mount -t ext4 "$IMG_FILE" "$TEMP_DIR" -o loop

set +e
rm -rf "${TEMP_DIR:?}/*"
tar -xf "$TAR_FILE" -C "$TEMP_DIR"
set -e

umount -lf "$IMG_FILE"
rm -rf "$TEMP_DIR"

e2fsck -p -f "$IMG_FILE"
resize2fs -M "$IMG_FILE"
