#!/bin/bash
# Build the base rootfs for OpenSwitch

tmpdir=$(mktemp -d)

apt-get update
apt-get install -y debootstrap

set -e

debootstrap \
    --arch=amd64 \
    --include=linux-image-3.16.0-4-amd64,sudo \
    jessie \
    $tmpdir

# Add the admin user
chroot $tmpdir adduser --quiet --gecos 'OPX Administrator,,,,' \
    --disabled-password admin
# Set the default password
echo 'admin:admin' | chpasswd -R $tmpdir

# Add the admin user to the sudo group
chroot $tmpdir usermod -a -G sudo admin

# Set the default hostname into /etc/hostname and /etc/hosts
default_hostname=OPX
echo $default_hostname > $tmpdir/etc/hostname
echo -e "127.0.1.1\t$default_hostname" >> $tmpdir/etc/hosts

# Create the rootfs tarball
tar czf opx-rootfs.tar.gz -C $tmpdir .

