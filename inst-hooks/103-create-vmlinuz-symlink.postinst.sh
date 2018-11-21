#!/bin/bash

# This postinst creates the missing vmlinuz and initrd.img symlinks

ln -sf /boot/vmlinuz-4.9.110-opx /vmlinuz
ln -sf /boot/vmlinuz-4.9.110-opx /vmlinuz.old
ln -sf /boot/initrd.img-4.9.110-opx /initrd.img
ln -sf /boot/initrd.img-4.9.110-opx /initrd.img.old

