#!/bin/bash
# Create the marker file to enter ZTD mode after installation

if [[ -n "$ZTD_DISABLE" ]]
then
    exit 0
fi

mkdir -p /etc/opx/ztd
touch /etc/opx/ztd/ztd
