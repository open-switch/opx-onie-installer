#!/bin/bash

# This postinst creates the missing vmlinuz and initrd.img symlinks

ln -sf /boot/vmlinuz-4.9.110 /vmlinuz
ln -sf /boot/vmlinuz-4.9.110 /vmlinuz.old
ln -sf /boot/initrd.img-4.9.110 /initrd.img
ln -sf /boot/initrd.img-4.9.110 /initrd.img.old

