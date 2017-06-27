# Library functions to probe for the presence of an existing NOS and to
# delete an existing OPX installation

# Check for the presence of the default OPX partitions
#
# Args: none
# Returns: none
check_opx_presence()
{
    # We require all the OPX partitions to be present to perform an update
    # An update will be performed when the OPX_REPARTITION variable is 0
    # Initialize it to the expected count of OPX partitions, then decrement
    #   for each recognized partition.
    OPX_REPARTITION=2

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
                if ! sgdisk -A ${part}:show $OPX_BLK_DEV | grep -q "system partition"
                then
                    # We have a non-system partition - possibly NOS
                    NOS_PRESENT=1
                fi
                ;;

            "$OPX_BOOT_PART_NAME"|\
            "$OPX_LVM_PART_NAME")
                # Decrement the OPX repartition variable for each recognized
                # OPX partition
                OPX_REPARTITION=$(($OPX_REPARTITION - 1))
                ;;

            *)
                # This is an unrecognized partition, we need to completely
                # repartition the system.
                OPX_REPARTITION=-1
                ;;

            esac

        fi
    done
}

