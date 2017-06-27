#!/bin/bash
# Build the base rootfs for OpenSwitch

if [ $# -ne 2 ]
then
    echo 'usage: build_opx_rootfs.sh <version> <arch>'
    exit 1
fi

version=$1
arch=$2

tmpdir=$(mktemp -d)

apt-get update
apt-get install -y debootstrap

set -e

debootstrap \
    --arch=$arch \
    --include=sudo \
    jessie \
    $tmpdir

# Add the admin user
chroot $tmpdir adduser --quiet --gecos 'OPX Administrator,,,,' \
    --disabled-password admin
# Set the default password
echo 'admin:admin' | chpasswd -R $tmpdir

# Set the default hostname into /etc/hostname and /etc/hosts
default_hostname=OPX
echo $default_hostname > $tmpdir/etc/hostname
echo -e "127.0.1.1\t$default_hostname" >> $tmpdir/etc/hosts

# Copy the contents of the rootconf folder to the rootfs
rsync -avz --chown root:root rootconf/* $tmpdir

# Update package cache
chroot $tmpdir apt-get update

# Add the admin user to the sudo group
chroot $tmpdir usermod -a -G sudo admin

rm $tmpdir/usr/sbin/policy-rc.d
chroot $tmpdir apt-get update
chroot $tmpdir apt-get clean
rm -rf $tmpdir/tmp/*

# Create the rootfs tarball
tarfile=opx-rootfs_${version}_${arch}.tar.gz
tar czf $tarfile -C $tmpdir .

# Reset the ownership
chown $LOCAL_UID:$LOCAL_GID $tarfile

# Clean up
rm -fr $tmpdir

#  LocalWords:  tmp
