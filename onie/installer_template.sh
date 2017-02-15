#!/bin/sh
# OpenSwitch ONIE installer

INSTALLER=$(realpath "$0")

set -e

# Verify the checksum of the rootfs
verify_checksum()
{
    local orig_checksum="@@ROOTFS_SHA1SUM@@"

    echo -n "Verifying image checksum... "
    local computed_csum=$(sed -e '1,/^__OPX_IMAGE__$/d' "$INSTALLER" |
                    sha1sum - | awk '{print $1}')

    if [ "$orig_checksum" != "$computed_csum" ]
    then
        echo "Invalid!"
        echo "    Expected: $orig_checksum"
        echo "    Computed: $computed_csum"
        exit 1
    else
        echo "OK"
    fi
}

# Identify key variables for the installer
identify_onie_variables()
{
    # Find the block device on which to install the image
    ONIE_BLK_DEV=$(blkid | awk '/ONIE-BOOT/ { print $1 }' |
                    sed -e 's/[0-9]://' | head -n 1)
    # ONIE_BLK_DEV should be a block special file
    if [ ! -b "$ONIE_BLK_DEV" ]
    then
        echo "Unable to determine the installation location"
        exit 1
    fi

    ONIE_MACHINE=$(onie-sysinfo -m)

    # Detect the serial port parameters on the current platform
    export GRUB_SERIAL_COMMAND=$(grep '^serial' /mnt/onie-boot/grub/grub.cfg)

    # Find the console parameters for Linux
    export GRUB_CMDLINE_LINUX=$(sed -e 's/^.*console=/console=/' \
                                    -e 's/ .*$//' /proc/cmdline)

    # Ensure that the partition type is GPT. MBR is not supported.
    ONIE_PARTITION_TYPE=$(onie-sysinfo -t)
    if [ "$ONIE_PARTITION_TYPE" != "gpt" ]
    then
        echo "Unsupported partition type: $ONIE_PARTITION_TYPE"
        exit 1
    fi

    # Check for EFI support
    if [ -d /sys/firmware/efi/efivars ]
    then
        ONIE_FIRMWARE=uefi
    else
        ONIE_FIRMWARE=bios
    fi
}

# Check if the partition should be deleted
should_delete_partition()
{
    local part_index="$1"
    local part_info=$(sgdisk -i $part_index $ONIE_BLK_DEV)

    # Make sure the partition exists
    # If it doesn't, we don't need to worry about deleting it
    if echo "$part_info" | grep -q 'does not exist'
    then
        return 1
    fi

    local part_guid=$(echo $part_info | awk '/Partition GUID code/ {print $4}')
    case "$part_guid" in
    'C12A7328-F81F-11D2-BA4B-00A0C93EC93B')
        # This is the EFI System Partition. Save the partition index
        ONIE_UEFI_PART_INDEX=$part_index
        return 1
        ;;

    '21686148-6449-6E6F-744E-656564454649')
        # This is a BIOS Boot partition used on GPT systems
        # with an MBR-style GRUB
        return 1
        ;;

    '7412F7D5-A156-4B13-81DC-867174929325')
        # This is the ONIE boot partition
        return 1
        ;;

    *)
        # Not a special partition
        ;;
    esac

    # Check the partition label for precious names
    local part_name=$(echo $part_info |
                awk -F"'" '/Partition name/ {print $(NF - 1)}')
    case "$part_name" in
    *-DIAG)
        # The diagnostics partition must have a partition label ending
        # in -DIAG and have the system partition flag set in the
        # partition attributes, as per the ONIE specification.
        if sgdisk -A ${part}:show $ONIE_BLK_DEV | grep -q "system partition"
        then
            # Preserve diagnostics image
            return 1
        fi
        ;;

    esac

    return 0
}

# Delete any other NOS on the system, including a previous install of OPX
delete_old_nos()
{
    # Find the last partition
    local last_partition=$(sgdisk -p $ONIE_BLK_DEV | awk 'END {print $1}')

    for part in $(seq 1 $last_partition)
    do
        if should_delete_partition $part
        then
            echo "Deleting old NOS partition $ONIE_BLK_DEV$part ..."
            sgdisk -d $part $ONIE_BLK_DEV &>/dev/null || {
                echo "ERROR: Unable to delete partition $part on $ONIE_BLK_DEV"
                exit 1
            }

            partprobe
        fi
    done
}

# Create a partition for OpenSwitch and format it
create_opx_partition()
{
    # Find next available partition
    local last_part=$(sgdisk -p $ONIE_BLK_DEV | awk 'END { print $1 }')
    OPX_PART_NUM=$(( $last_part + 1 ))
    OPX_PART=$ONIE_BLK_DEV$OPX_PART_NUM
    OPX_PART_LABEL="OPX"

    echo -n "Creating new partition $OPX_PART as $OPX_PART_LABEL..."
    sgdisk --new=${OPX_PART_NUM}:: \
        --change-name=${OPX_PART_NUM}:${OPX_PART_LABEL} $ONIE_BLK_DEV &>/dev/null || {
        echo "FAILED!"
        exit 1
    }
    echo "OK"
    partprobe

    echo "Creating ext4 filesystem on $OPX_PART, volume label $OPX_PART_LABEL"
    mkfs.ext4 -L "$OPX_PART_LABEL" $OPX_PART >/dev/null 2>/dev/null || {
        echo "ERROR: Creating filesystem failed!"
        exit 1
    }
}

# Mount the OPX partition
mount_opx_partition()
{
    OPX_MOUNT=/mnt/sysroot

    mkdir -p $OPX_MOUNT
    mount -t ext4 $OPX_PART $OPX_MOUNT
}

# Unmount the OPX partition
unmount_opx_partition()
{
    umount $OPX_MOUNT
}

# Install the rootfs contents into the OPX partition
install_opx()
{
    echo -n "Installing OpenSwitch..."
    sed -e '1,/^__OPX_IMAGE__$/d' "$INSTALLER" | tar -zxf - -C $OPX_MOUNT

    # Reconfigure the kernel so that we regenerate the initramfs
    chroot $OPX_MOUNT dpkg-reconfigure linux-image-3.16.0-4-amd64 &>/dev/null

    # Reconfigure OpenSSH to regenerate the host keys
    chroot $OPX_MOUNT dpkg-reconfigure openssh-server &>/dev/null

    echo "OK"
}

# Install the GRUB for BIOS
install_grub_bios()
{
    echo -n "Installing GRUB on $ONIE_BLK_DEV (boot-dir $OPX_GRUB_DIR)..."
    grub-install --boot-directory=$OPX_GRUB_DIR --recheck $ONIE_BLK_DEV || {
        echo "FAILED!"
        exit 1
    }
}

# Install GRUB for EFI
install_grub_uefi()
{
    # Ensure that the EFI System Partition exists
    [ -n "$ONIE_UEFI_PART_INDEX" ] || {
        echo "ERROR: Cannot locate EFI System Partition"
        exit 1
    }

    # Boot label in EFI partition
    OPX_BOOT_LABEL=OpenSwitch

    # Cleanup any old references
    efibootmgr | awk "/$OPX_BOOT_LABEL/ { print \$1 }" | while read boot_id
    do
        # Remove leading 'Boot' and trailing '*'
        boot_id=${boot_id#Boot}
        boot_id=${boot_id%\*}

        efibootmgr -b $boot_id -B
    done


    echo -n "Installing GRUB-UEFI on $ONIE_BLK_DEV ..."
    grub-install \
        --no-nvram \
        --bootloader-id="$OPX_BOOT_LABEL"
        --efi-directory='/boot/efi' \
        --boot-directory="$OPX_GRUB_DIR" \
        --recheck $ONIE_BLK_DEV || {

        echo "FAILED!"
        exit 1
    }
    echo "OK"

    # Configure NVRAM variables
    efibootmgr --quiet --create \
        --label="$OPX_BOOT_LABEL" \
        --disk="$OPX_PART" \
        --part="$ONIE_UEFI_PART_INDEX" \
        --loader="/EFI/$OPX_BOOT_LABEL/grubx64.efi" || {

        echo "EFI boot manager failed to create new boot variable!"
        exit 1
    }
}

# Install GRUB (UEFI/BIOS)
install_grub()
{
    OPX_GRUB_DIR="$OPX_MOUNT/boot"

    install_grub_${ONIE_FIRMWARE}

    # Create the GRUB config file
    local grub_cfg="$OPX_GRUB_DIR/grub/grub.cfg"

    : > $grub_cfg

    cat >> $grub_cfg << EOF
# Serial console configuration
$GRUB_SERIAL_COMMAND
terminal_input serial
terminal_output serial

# Set the timeout
set timeout=5

# Load the environment
if [ -s \$prefix/grubenv ]; then
    load_env
fi

# Load the default entry from the environment
set default="\${saved_entry}"

# Load the one-time boot entry from the environment
if [ "\${next_entry}" ]; then
    set default="\${next_entry}"
    set next_entry=
    save_env next_entry
fi

# Default modules required to boot OPX
insmod ext2
EOF

    # Find the filenames of the kernel and initrd files
    local opx_kernel=$(find $OPX_GRUB_DIR -name '*vmlinu[xz]*' |
                        sed 's#.*\(/boot\)#\1#' | head -n 1)
    local opx_initrd=$(find $OPX_GRUB_DIR -name '*initrd*' |
                        sed 's#.*\(/boot\)#\1#' | head -n 1)

    if [ ! -n "$opx_kernel" -o ! -n "$opx_initrd" ]
    then
        echo "ERROR: Cannot find kernel image or initrd!"
        exit 1
    fi

    cat >> $grub_cfg <<EOF
menuentry 'OpenSwitch' {
    set     root=(hd0,gpt$OPX_PART_NUM)
    echo    "Loading OpenSwitch..."
    linux   $opx_kernel \\
            $GRUB_CMDLINE_LINUX \\
            root=$OPX_PART rw quiet
    initrd  $opx_initrd
}
EOF

    # ONIE menuentry
    /mnt/onie-boot/onie/grub.d/50_onie_grub >> $grub_cfg
}

# Run the installation
verify_checksum
identify_onie_variables
delete_old_nos
create_opx_partition
mount_opx_partition
install_opx
install_grub
unmount_opx_partition

echo "OpenSwitch installation complete"
exit 0

# rootfs marker - DO NOT DELETE
__OPX_IMAGE__
