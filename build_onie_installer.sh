#!/bin/bash
# Usage: ./build_onie_installer.sh <platform> <rootfs> <output>

PLATFORM=$(echo $1 | tr a-z A-Z)
ROOTFS=$2
OUTPUTBIN=$3

if [[ -z "$PLATFORM" || -z "$ROOTFS" || -z "$OUTPUTBIN" ]]
then
    echo "Usage: $0 <platform> <rootfs> <output>"
    exit 1
fi

case "$PLATFORM" in
"S6000")
    GRUB_SERIAL_COMMAND='serial --port=0x3f8 --speed=115200 --word=8 --parity=no --stop=1'
    GRUB_CMDLINE_LINUX='console=ttyS0,115200 intel_idle.max_cstate=0 processor.max_cstate=1'
    INSTALLER_MACHINE='dell_s6000_s1220'
    LINUX_KERNEL_IMAGE='linux-image-3.16.0-4-amd64'
    ;;

"VM-S6000")
    GRUB_SERIAL_COMMAND='serial --port=0x3f8 --speed=115200 --word=8 --parity=no --stop=1'
    GRUB_CMDLINE_LINUX='console=ttyS0,115200'
    INSTALLER_MACHINE='kvm_x86_64'
    LINUX_KERNEL_IMAGE='linux-image-3.16.0-4-amd64'
    ;;

*)
    echo "Unsupported platform $PLATFORM"
    exit 1
esac

ROOTFS_SHA1SUM=$(sha1sum $ROOTFS | awk '{ print $1 }')

sed -e "s/@@GRUB_SERIAL_COMMAND@@/$GRUB_SERIAL_COMMAND/g" \
    -e "s/@@GRUB_CMDLINE_LINUX@@/$GRUB_CMDLINE_LINUX/g" \
    -e "s/@@INSTALLER_MACHINE@@/$INSTALLER_MACHINE/g" \
    -e "s/@@LINUX_KERNEL_IMAGE@@/$LINUX_KERNEL_IMAGE/g" \
    -e "s/@@ROOTFS_SHA1SUM@@/$ROOTFS_SHA1SUM/g" \
    onie/installer_template.sh > $OUTPUTBIN

cat $ROOTFS >> $OUTPUTBIN

chmod +x $OUTPUTBIN
