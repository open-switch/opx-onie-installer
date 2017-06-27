#!/bin/bash
# Setup the upgrade on OPX

OPX_ALT_MOUNT='/alt'
OPX_POST_UPGRADE='/root/postupgrade-hooks'
OPX_INSTALL_HOOKS='/root/hooks'

# Copy any post-upgrade hooks to the correct location on the standby
mkdir -p "${OPX_ALT_MOUNT}${OPX_POST_UPGRADE}"
cp  "${OPX_ALT_MOUNT}${OPX_INSTALL_HOOKS}/*.post-upgrade.*" \
    "${OPX_ALT_MOUNT}${OPX_POST_UPGRADE}" 2>/dev/null || true

# Copy the existing password and shadow files to the standby
for pwd_file in passwd group shadow gshadow
do
    cp -a /etc/$pwd_file ${OPX_ALT_MOUNT}/etc/$pwd_file
done

