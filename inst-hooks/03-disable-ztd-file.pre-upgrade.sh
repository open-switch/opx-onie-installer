#!/bin/bash
# Ensure that we don't enter ZTD mode after an upgrade

# Deleting the postinst hook ensures that even a failure in a later hook
# would not leave the ZTD file hanging around on the standby filesystem.
# This is will remove the install hook
# when we upgrade the bin in standby partition alone.
rm -f /alt/root/hooks/95-enable-ztd-mode.postinst.sh
