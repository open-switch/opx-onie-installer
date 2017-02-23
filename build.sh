#!/bin/bash -e

BUILD_DIR=$(realpath `dirname -- $0`)
OPX_RUN=$(realpath $BUILD_DIR/../opx-build/scripts/opx_run)

cd $(realpath $BUILD_DIR/..)

$OPX_RUN /bin/bash -c 'cd /mnt/opx-onie-installer && touch opx-rootfs.tar.gz && chmod 666 opx-rootfs.tar.gz && sudo ./build_opx_rootfs.sh'

cd $BUILD_DIR

./build_onie_installer.sh opx-rootfs.tar.gz opx-onie-installer-x86_64_generic.bin

