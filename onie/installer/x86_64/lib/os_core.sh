# Core utility functions for the OPX installer

# Validate the image checksum for the root image
#
# args: none
#
# Exits on failure
validate_opx_checksum()
{
    echo -n "Verifying image checksum..."

    # Extract the root image from the installer and validate the checksum
    if ! sed -e '1,/^__IMAGE__$/d' "$INSTALLER" | sha1sum -cs image_checksum
    then
        echo "!!! FAIL !!!"
        exit 1
    fi

    echo "OK"
}

# Install OPX into a logical volume
#
# arg1: Logical volume label on $OPX_VOLUME_GROUP
# Returns: none
install_opx()
{
    opx_dev="/dev/$OPX_VOLUME_GROUP/$1"
    opx_mnt="/mnt/sysroot"

    config_dev="/dev/$OPX_VOLUME_GROUP/$OPX_CONFIG_NAME"
    config_mnt="/mnt/sysroot/config"

    mount_opx_partition "$opx_dev" "$opx_mnt"
    mount_opx_partition "$config_dev" "$config_mnt"

    # Untar contents into partition
    echo "Untaring into $opx_mnt ($opx_dev)"
    sed -e '1,/^__IMAGE__$/d' "$INSTALLER" | tar -xzf - -C "$opx_mnt"

    # Check if we have an executable installer script
    if [ -x "$opx_mnt/root/install_opx.sh" ]
    then
        echo "Installing OPX on primary partition"

        # OPX_MACHINE may have ben overridden here, we want to use the
        # overridden value rather than querying `onie-sysinfo -m`
        chroot "$opx_mnt" /root/install_opx.sh $OPX_MACHINE $OPX_VM_FLAVOR || {
            # install_opx.sh failed
            error "OPX installation failed!!!"
            cat "$opx_mnt/root/install.log"
            exit 1
        }
    else
        echo "No extra installer script for single platform installer"
    fi

    echo "OPX installation on primary partition is complete."

    # Cleanup
    unmount_opx_partition "$config_mnt"
    unmount_opx_partition "$opx_mnt"
}

# Synchronize OPX installation from one partition to the next
#
# arg1: Volume that has OPX already installed
# arg2: Volume to synchronize to
# Returns: none
sync_opx()
{
    opx_src_dev="/dev/$OPX_VOLUME_GROUP/$1"
    opx_dst_dev="/dev/$OPX_VOLUME_GROUP/$2"
    opx_src_mnt="/mnt/sysroot-src"
    opx_dst_mnt="/mnt/sysroot-dst"

    mount_opx_partition "$opx_src_dev" "$opx_src_mnt"
    mount_opx_partition "$opx_dst_dev" "$opx_dst_mnt"

    # Copy contents from source to destination
    echo -n "Synchronizing standby partition..."
    (cd "$opx_src_mnt"; tar cf - .) | (cd "$opx_dst_mnt"; tar xf -) ||
        abort 1 "!!! FAIL !!!"
    echo "OK"

    # Cleanup
    unmount_opx_partition "$opx_src_mnt"
    unmount_opx_partition "$opx_dst_mnt"
}

# Save installation information into the specified partition
#
# arg1: Partition to save information to
# Returns: none
save_install_info()
{
    opx_dev="$1"
    opx_mnt="/mnt/install"
    sys_info="$opx_mnt/platform"

    mount_opx_partition "$opx_dev" "$opx_mnt"

    echo "Saving system information in $sys_info"

    # Save system information
    # Use overridden value of OPX_MACHINE
    cat > "$sys_info" <<EOF
OPX_MACHINE=$OPX_MACHINE
OPX_ARCH=$(onie-sysinfo -c)
OPX_MACHINE_REV=$(onie-sysinfo -r)
OPX_PLATFORM=$(onie-sysinfo -p)
OPX_FIRMWARE=$OPX_FIRMWARE
OPX_MACHINE_ORIG=$(onie-sysinfo -m)
EOF

    # Add VM Information if necessary
    if [ -n "$OPX_VM_FLAVOR" ]
    then
        echo "OPX_VM_FLAVOR=$OPX_VM_FLAVOR" >> "$sys_info"
    fi

    # Protect the file
    chmod 444 "$sys_info"

    echo "Saving ONIE support information in $opx_mnt"
    # Save onie-support information
    onie-support "$opx_mnt"

    # Cleanup
    unmount_opx_partition "$opx_mnt"
}
