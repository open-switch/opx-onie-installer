# Partition logic for OPX
#
# Following sequence is followed by NOS installer script.
#
# 1. Check the block device on which ONIE is installed.
# 2. Determine the ONIE partition type. It should be 'gpt'.
# 3. Check CF size and adjust OPX sysroot partition sizes.
# 4. Check and delete any existing partitions listed in Table-2 below.
# 5. Check and delete old OPX partition.
# 6. Create partitions listed in Table-2.
# 7. Create filesystem on OPX-SYSROOT1/2 partition with a label.
# 8. Update Grub config for OPX-SYSROOT1/2.
#
#         Table-1 (Created by ONIE/Diag installer)
#---------------------+--------+----------------------------+
#  OPX Partitioning  | Size   | Contents                   |
#---------------------+--------+----------------------------+
# GRUB BOOT           | 2 MB   | GRUB ONIE                  |
#---------------------+--------+----------------------------+
# ONIE-BOOT           | 128 MB | ONIE kernel + initrd Images|
#---------------------+--------+----------------------------+
# PLATFORM-DIAG       | 300 MB | PLATFORM + DIAG specific   |
#---------------------+--------+----------------------------+


#         Table-2 (Created by NOS installer)
#---------------------+--------+----------------------------+
# OPX-BOOT           |   8 MB | GRUB configuration files   |
#---------------------+--------+----------------------------+
# OPX                |   --   | OPX LVM physical volume   |
#---------------------+--------+----------------------------+
# LVM physical volume uses remaining space on flash


#         Table-3 (Logical volumes within OPX LVM)
#---------------------+--------+----------------------------+
# LICENSE             |  32 MB | License files              |
#---------------------+--------+----------------------------+
# CONFIG              | 200 MB | OPX config (specific /etc |
#                     |        |    directories)            |
#---------------------+--------+----------------------------+
# SYSROOT1            |   --   | OPX sysroot 1             |
#---------------------+--------+----------------------------+
# SYSROOT2            |   --   | OPX sysroot 2             |
#---------------------+--------+----------------------------+
# SYSROOT1/2 sizes expand to fill all available space

# GRUB partition cannot reside within LVM, however, GRUB itself
# can load the kernel and initrd from a logical volume
OPX_BOOT_PART_SIZE=+8MB
OPX_BOOT_PART_NAME='OPX-BOOT'
OPX_LVM_PART_NAME='OPX-LVM'

# Sizes for each of the volume groups
OPX_LICENSE_SIZE=32MB
OPX_CONFIG_SIZE=500MB
# Sysroot sizes will be computed based on the number of extents
OPX_SYSROOT1_EXTENTS=50%FREE
OPX_SYSROOT2_EXTENTS=100%FREE

# Volume labels
OPX_VOLUME_GROUP="OPX"
OPX_LICENSE_NAME="LICENSE"
OPX_CONFIG_NAME="CONFIG"
OPX_SYSROOT1_NAME="SYSROOT1"
OPX_SYSROOT2_NAME="SYSROOT2"

# Partition numbers are computed during creation of the individual partitions
OPX_BOOT_PART_NUM=
OPX_LVM_PART_NUM=

# Check if partition is a special partition
#
# arg1: partition GUID code
# Returns: 0 if partition is a special partition
partition_is_special()
{
    part_guid="$1"
    part_index="$2"

    case "$part_guid" in
    'C12A7328-F81F-11D2-BA4B-00A0C93EC93B')
        # This is the EFI System Partition. Save the partition index
        OPX_UEFI_PART_INDEX=$part_index
        return 0
        ;;

    '21686148-6449-6E6F-744E-656564454649')
        # This is a BIOS Boot partition used on GPT systems
        # with an MBR-style GRUB
        return 0
        ;;

    '7412F7D5-A156-4B13-81DC-867174929325')
        # This is the ONIE boot partition
        return 0
        ;;

    *)
        # Not a special partition
        return 1
        ;;
    esac
}

# Delete old NOS partitions
#
# Args: none
# Returns: none
delete_old_nos_partitions()
{
    # Find the last partition
    last_partition=$(sgdisk -p $OPX_BLK_DEV | awk 'END {print $1}')

    for part in $(seq 1 $last_partition)
    do
        part_info=$(sgdisk -i $part $OPX_BLK_DEV)

        # We may have a break in partition numbering.
        # Make sure that the partition exists before testing the label
        if ! echo "$part_info" | grep -q 'does not exist'
        then
            # We have some standard system partitions. These include:
            # - EFI System Partition
            # - BIOS Boot Partition
            # - ONIE Boot Partition
            # Because the partition GUID code is guaranteed to be unique and
            # constant for these partitions, we validate the GUID code rather
            # than the partition name/label, which could vary.

            # Extract the partition GUID from the information output
            part_guid=$(echo $part_info |
                        awk '/Partition GUID code/ {print $4}')

            if partition_is_special "$part_guid" "$part"
            then
                continue
            fi

            # Extract the partition name from the information output
            part_name=$(echo $part_info |
                        awk -F"'" '/Partition name/ {print $(NF - 1)}')

            case "$part_name" in
            *-DIAG)
                # The diagnostics partition must have a partition label ending in
                # -DIAG and have the system partition flag set in the partition
                # attributes, as per the ONIE specification.
                if sgdisk -A ${part}:show $OPX_BLK_DEV | grep -q "system partition"
                then
                    # Preserve diagnostics image
                    continue
                fi
                ;;

            esac

            echo "Deleting old NOS partition $OPX_BLK_DEV$part ($part_name)..."
            sgdisk -d $part $OPX_BLK_DEV ||
                abort 1 "ERROR: Unable to delete partition $part on $OPX_BLK_DEV"

            partprobe
        fi
    done
}

# Create a new ext4 filesystem on a partition
#
# arg1: Partition block device
# arg2: Partition label
# Returns: none
make_filesystem()
{
    opx_part_blk="$1"
    opx_part_label="$2"

    echo "Creating ext4 filesystem on $opx_part_blk, volume label $opx_part_label"
    mkfs.ext4 -L "$opx_part_label" "$opx_part_blk" || {
        echo "!!! FAIL !!!"
        exit 1
    }
}

# Create a new ext4 filesystem on a logical volume
#
# arg1: Volume on $OPX_VOLUME_GROUP to make a filesystem
# Returns: none
make_filesystem_volume()
{
    opx_part_blk="/dev/$OPX_VOLUME_GROUP/$1"
    opx_part_label="$OPX_VOLUME_GROUP-$1"

    make_filesystem "$opx_part_blk" "$opx_part_label"
}

# Creates a new partition for the OPX OS.
#
# arg1 -- partition name
# arg2 -- partition size
create_opx_partition()
{
    opx_part_name="$1"
    opx_part_size="$2"

    # Find next available partition
    last_part=$(sgdisk -p $OPX_BLK_DEV | awk 'END { print $1 }')
    opx_part_local=$(( $last_part + 1 ))

    opx_dev=$OPX_BLK_DEV$opx_part_local
    echo "Next available partition is $opx_dev"

    # Create new partition
    echo -n "Creating new partition $opx_dev as $opx_part_name..."
    sgdisk --new=${opx_part_local}::${opx_part_size} \
        --change-name=${opx_part_local}:$opx_part_name $OPX_BLK_DEV || {
        echo "!!! FAIL !!!"
        exit 1
    }
    echo "OK"
    partprobe

    # Store the partition numbers
    case "$opx_part_name" in
    "$OPX_BOOT_PART_NAME")
        OPX_BOOT_PART_NUM=$opx_part_local
        ;;
    "$OPX_LVM_PART_NAME")
        OPX_LVM_PART_NUM=$opx_part_local
        ;;
    *)
        ;;
    esac
}

# Mount partition
# arg $1 -- base block device
# arg $2 -- partition mount point
#
# Return none
mount_opx_partition()
{
    opx_dev="$1"
    opx_mnt_point="$2"

    mkdir -p $opx_mnt_point || {
        abort 1 "Error: Unable to create OPX file system mount point: $opx_mnt_point"
    }

    mount -t ext4 -o defaults,rw $opx_dev $opx_mnt_point || {
        abort 1 "Error: Unable to mount $opx_dev on $opx_mnt_point"
    }
}

# Unmount partition
# arg $1 -- partition mount point
unmount_opx_partition()
{
    opx_mnt_point="$1"

    umount $opx_mnt_point || {
        echo "Error: Problems unmounting $opx_mnt_point"
    }
}

# Extract partition number from the partition table
# arg $1 -- partition label
extract_part_num()
{
    sgdisk -p $OPX_BLK_DEV | awk "/$1/ { print \$1 }"
}

# Compute partition numbers
# Updates partition number environment variables from the partition table
compute_opx_partition_numbers()
{
    # Save the partition table
    part_table=$(sgdisk -p $OPX_BLK_DEV)

    OPX_BOOT_PART_NUM=$(extract_part_num "$OPX_BOOT_PART_NAME")
    OPX_LVM_PART_NUM=$(extract_part_num "$OPX_LVM_PART_NAME")
}

# Create OPX Volume Group
create_opx_volume_group()
{
    # Set the partition type to Linux LVM
    sgdisk --typecode ${OPX_LVM_PART_NUM}:8e00 ${OPX_BLK_DEV}
    partprobe

    echo "Creating physical volume on ${OPX_BLK_DEV}${OPX_LVM_PART_NUM} ..."
    # pvcreate balks if you try to create a physical volume over an existing
    # volume group. However, we really want to erase any volume groups that
    # exist, and therefore we deliberately force the creation of the physical
    # volume. However, we don't care about the error message that it inevitably
    # spits out, complaining that it's erasing the volume group, therefore,
    # we redirect stderr to /dev/null.
    pvcreate -ff -y ${OPX_BLK_DEV}${OPX_LVM_PART_NUM} 2>/dev/null

    echo "Creating volume group ${OPX_VOLUME_GROUP} ..."
    vgcreate ${OPX_VOLUME_GROUP} ${OPX_BLK_DEV}${OPX_LVM_PART_NUM}
}

# Create a single logical volume
#
# arg1: Logical volume name
# arg2: Size switch (--size/--extents)
# arg3: Size value
# Returns: none
_create_opx_logical_volume()
{
    opx_lv_name=$1
    opx_lv_switch=$2
    opx_lv_size_val=$3

    echo "Creating logical volume $opx_lv_name on $OPX_VOLUME_GROUP ..."
    lvcreate --name $opx_lv_name $opx_lv_switch $opx_lv_size_val $OPX_VOLUME_GROUP
}

# Create OPX Volumes
create_opx_volumes()
{
    # Create the OPX logical volumes
    _create_opx_logical_volume $OPX_LICENSE_NAME --size $OPX_LICENSE_SIZE
    _create_opx_logical_volume $OPX_CONFIG_NAME --size $OPX_CONFIG_SIZE
    _create_opx_logical_volume $OPX_SYSROOT1_NAME --extents $OPX_SYSROOT1_EXTENTS
    _create_opx_logical_volume $OPX_SYSROOT2_NAME --extents $OPX_SYSROOT2_EXTENTS
}
