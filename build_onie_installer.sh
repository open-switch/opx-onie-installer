#!/bin/bash
# Usage: ./build_onie_installer.sh <platform> <rootfs> <output>

ROOTFS=$1
OUTPUTBIN=$2

if [[ -z "$ROOTFS" || -z "$OUTPUTBIN" ]]
then
    echo "Usage: $0 <rootfs> <output>"
    exit 1
fi

ROOTFS_SHA1SUM=$(sha1sum $ROOTFS | awk '{ print $1 }')

sed -e "s/@@ROOTFS_SHA1SUM@@/$ROOTFS_SHA1SUM/g" \
    onie/installer_template.sh > $OUTPUTBIN

cat $ROOTFS >> $OUTPUTBIN

chmod +x $OUTPUTBIN
