# GRUB utility functions for OPX

# Generate a grub configuration file
#
# Arg1: Path to the config file
# Returns: Writes the config to the above file
generate_opx_grub_config()
{
    grub_cfg_file=$1

    # Create or truncate the grub config file
    : > $grub_cfg_file

    # Create a minimal grub.cfg that supports:
    #   - serial console
    #   - USB console
    #   - grub-reboot
    #   - menu entries for OPX
    #   - menu entry for ONIE

    cat >> $grub_cfg_file <<EOF
if [ -s \$prefix/grubenv ]; then
    load_env
fi
EOF

    # Set the default input/output for the GRUB terminal
    if [ ! -n "$GRUB_TERMINAL_IO" ]
    then
        GRUB_TERMINAL_IO=serial
    fi

    # Add common configuration, like the timeout and serial console.
    # If OPX_SERIAL_COMMAND is set, use that in preference to GRUB_SERIAL_COMMAND
    # For units with USB serial interfaces, terminal IO to 'console' uses the
    # RJ45 serial interface, so we need to explicitly configure 'serial' to
    # use the USB serial interface.
    if [ -n "$OPX_SERIAL_COMMAND" ]
    then
        cat >> $grub_cfg_file << EOF
$OPX_SERIAL_COMMAND
terminal_input $GRUB_TERMINAL_IO
terminal_output $GRUB_TERMINAL_IO
EOF
    elif [ -n "$GRUB_SERIAL_COMMAND" ]
    then
        cat >> $grub_cfg_file <<EOF
$GRUB_SERIAL_COMMAND
terminal_input $GRUB_TERMINAL_IO
terminal_output $GRUB_TERMINAL_IO

EOF
    fi

    cat >> $grub_cfg_file <<EOF
set timeout=5

EOF

    # Add the logic to support grub-reboot and grub-set-default
    cat >> $grub_cfg_file <<EOF
# Load the default entry from the environment
set default="\${saved_entry}"

# Load the one-time boot entry from the environment
if [ "\${next_entry}" ] ; then
    set default="\${next_entry}"
    set next_entry=
    save_env next_entry
fi

EOF

    # Add modules used to load LVM
    cat >> $grub_cfg_file <<EOF
# Default modules required for booting OPX
insmod lvm
insmod ext2

EOF
    # Add menu entries for OPX
    cat >> $grub_cfg_file <<EOF
menuentry 'OPX-A' --class gnu-linux --class gnu --class os {
    set     root=(lvm/$OPX_VOLUME_GROUP-$OPX_SYSROOT1_NAME)
    echo    'Loading OPX ...'
    linux   /vmlinuz \\
            $GRUB_CMDLINE_LINUX \\
            root=/dev/mapper/$OPX_VOLUME_GROUP-$OPX_SYSROOT1_NAME rw \\
            quiet
    initrd  /initrd.img
}

menuentry 'OPX-B' --class gnu-linux --class gnu --class os {
    set     root=(lvm/$OPX_VOLUME_GROUP-$OPX_SYSROOT2_NAME)
    echo    'Loading OPX ...'
    linux   /vmlinuz \\
            $GRUB_CMDLINE_LINUX \\
            root=/dev/mapper/$OPX_VOLUME_GROUP-$OPX_SYSROOT2_NAME rw \\
            quiet
    initrd  /initrd.img
}

EOF

    # Add menu entries for ONIE -- use the grub fragment provided by the
    # ONIE distribution.
    /mnt/onie-boot/onie/grub.d/50_onie_grub >> $grub_cfg_file
}

# Install GRUB in MBR
install_grub_bios()
{
    # Install GRUB into the MBR of $OPX_BLK_DEV
    echo -n "Installing GRUB on $OPX_BLK_DEV (boot-dir $opx_grub_mnt)..."
    grub-install --boot-directory="$opx_grub_mnt" --recheck "$OPX_BLK_DEV" || {
        echo "!!! FAIL !!!"
        exit 1
    }
    echo "OK"
}

# Install GRUB-UEFI
install_grub_uefi()
{
    # Install GRUB into the EFI system partition
    [ -n "$OPX_UEFI_PART_INDEX" ] || {
        abort 1 "Cannot locate EFI system partition"
    }

    # Boot label in EFI partition
    OPX_BOOT_LABEL='OPX'

    # Cleanup any old references in EFI boot variables to OPX
    for boot_id in $(efibootmgr | awk "/$OPX_BOOT_LABEL/ { print \$1 }")
    do
        # Remove leading 'Boot' and trailing '*'
        boot_id=${boot_id#Boot}
        boot_id=${boot_id%\*}

        efibootmgr -b $boot_id -B
    done

    echo -n "Installing GRUB-UEFI on $OPX_BLK_DEV"
    grub-install \
        --no-nvram \
        --bootloader-id="$OPX_BOOT_LABEL" \
        --efi-directory='/boot/efi' \
        --boot-directory="$opx_grub_mnt" \
        --recheck "$OPX_BLK_DEV" || {

        echo "!!! FAIL !!!"
        exit 1
    }
    echo "OK"

    # Configure NVRAM variables
    efibootmgr --quiet --create \
        --label="$OPX_BOOT_LABEL" \
        --disk="$OPX_BLK_DEV" \
        --part="$OPX_UEFI_PART_INDEX" \
        --loader="/EFI/$OPX_BOOT_LABEL/grubx64.efi" || {

        echo "EFI boot manager failed to create new boot variable on $OPX_BLK_DEV"
        exit 1
    }
}

# Install GRUB for OPX
#
# Args: none
# Returns: none
install_opx_grub()
{
    # Partition to install GRUB to
    opx_grub_dev=${OPX_BLK_DEV}${OPX_BOOT_PART_NUM}

    # Mount point for above partition
    opx_grub_mnt="/mnt/boot"

    # Mount the boot partition
    mount_opx_partition "$opx_grub_dev" "$opx_grub_mnt"

    # Call the appropriate routine depending on firmware type
    install_grub_${OPX_FIRMWARE}

    # Create the GRUB config file
    grub_cfg="$opx_grub_mnt/grub/grub.cfg"
    generate_opx_grub_config "$grub_cfg"

    unmount_opx_partition "$opx_grub_mnt"
}
