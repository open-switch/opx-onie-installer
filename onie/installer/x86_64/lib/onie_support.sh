# ONIE support functions

# Get the block device on which to install the image
# This is the same device where ONIE is installed
#
# Args: none
# Saves the output block device in OPX_BLK_DEV
identify_opx_block_dev()
{
    OPX_BLK_DEV=$(blkid | awk '/ONIE-BOOT/ { print $1 }' |
                    sed -e 's/[0-9]://' | head -n 1)

    # OPX_BLK_DEV should be a block special file
    if [ ! -b "$OPX_BLK_DEV" ]
    then
        abort 1 "Unable to determine the installation location"
    fi
}

# Load the machine specific information
#
# Args: none
load_machine_info()
{
    if [ -n "$OPX_INSTALLER_FORCE_MACHINE" ]
    then
        echo "Forcing machine to $OPX_INSTALLER_FORCE_MACHINE"
        OPX_MACHINE=$OPX_INSTALLER_FORCE_MACHINE
    else
        OPX_MACHINE=$(onie-sysinfo -m)
    fi

    if [ -r "./machine/${OPX_MACHINE}.conf" ]
    then
        . "./machine/${OPX_MACHINE}.conf"
    else
        abort 1 "Unsupported machine: $OPX_MACHINE"
    fi
}

# Identify the ONIE partition type. We only support GPT
identify_onie_partition_type()
{
    ONIE_PARTITION_TYPE=$(onie-sysinfo -t)
    if [ "$ONIE_PARTITION_TYPE" != "gpt" ]
    then
        abort 1 "Unsupported partition type: $ONIE_PARTITION_TYPE"
    fi
}

# Identify the firmware (UEFI/BIOS)
identify_machine_firmware()
{
    # Check for EFI support
    if [ -d /sys/firmware/efi/efivars ]
    then
        OPX_FIRMWARE="uefi"
    else
        OPX_FIRMWARE="bios"
    fi
}
