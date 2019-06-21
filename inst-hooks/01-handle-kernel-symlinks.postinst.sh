#!/bin/bash
# Handle the case where we have an older version of the OS10 kernel
# which does not have the standard symlinks

# This runs in the context of an install chroot and works only on
# the current partition being installed to.
# XXX: Link creation can be removed once the kernel package addresses
# it in its own postinst script

# Assumption is that exactly 1 kernel package is installed
KERNEL=$(find /boot -name 'vmlinuz-*' -type f)
INITRD=$(find /boot -name 'initrd.img-*' -type f)

if [[ -n "$KERNEL" && -n "$INITRD" ]]
then
    rm -f /boot/vmlinuz /vmlinuz
    ln "$KERNEL" /boot/vmlinuz
    ln -s "$KERNEL" /vmlinuz
    rm -f /boot/initrd.img /initrd.img
    ln "$INITRD" /boot/initrd.img
    ln -s "$INITRD" /initrd.img

    # This is necessary to ensure that the module.dep is regenerated
    # after installing any new kernel modules
    depmod -a ${KERNEL##*-}
fi

# Create symlinks to OS10 kernel & initrd
if [[ ! -e /vmlinuz ]]
then
    echo "Unable to find kernel, your install may be corrupted!" >&2
    exit 1
fi

if [[ ! -e /initrd.img ]]
then
    echo "Unable to find initrd, your install may be corrupted!" >&2
    exit 1
fi

