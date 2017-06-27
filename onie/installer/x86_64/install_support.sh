# Core installer support library

# Exit handler
# This is called when the script terminates
#
# arg1: Exit code
exit_handler()
{
    rc=$1

    # Cleanup any remnants of the script
    rm -rf "$TMP_DIR"

    exit $rc
}
trap exit_handler EXIT

# Load the individual support modules
for support_file in ./lib/*.sh
do
    . $support_file
done

# Main installation function
install_main()
{
    validate_opx_checksum

    load_machine_info
    echo "OPX Installer: machine: $OPX_MACHINE"

    identify_opx_block_dev

    identify_onie_partition_type
    identify_machine_firmware

    # Check for existing OPX installation
    check_opx_presence

    # If we are going to update, don't change the partition layout
    if [ "$OPX_REPARTITION" != 0 ]
    then
        delete_old_nos_partitions

        # Create the OPX boot partition and root volume group
        create_opx_partition $OPX_BOOT_PART_NAME $OPX_BOOT_PART_SIZE
        create_opx_partition $OPX_LVM_PART_NAME
        create_opx_volume_group
    else
        # Extract the partition numbers from the existing layout
        compute_opx_partition_numbers

        # Recreate the volume group
        create_opx_volume_group
    fi

    # Create the OPX logical volumes
    create_opx_volumes

    # Make a filesystem for the Configuration volume
    make_filesystem_volume $OPX_CONFIG_NAME

    # Make a filesystem for the license volume
    make_filesystem_volume $OPX_LICENSE_NAME

    # Make a filesystem for the sysroot volumes
    make_filesystem_volume $OPX_SYSROOT1_NAME
    make_filesystem_volume $OPX_SYSROOT2_NAME

    # Install the rootfs into the sysroots
    install_opx $OPX_SYSROOT1_NAME
    sync_opx $OPX_SYSROOT1_NAME $OPX_SYSROOT2_NAME

    # Make a filesystem for the boot partition
    make_filesystem $OPX_BLK_DEV$OPX_BOOT_PART_NUM $OPX_BOOT_NAME

    # Install GRUB
    install_opx_grub

    # Save installation information
    save_install_info $OPX_BLK_DEV$OPX_BOOT_PART_NUM
}

