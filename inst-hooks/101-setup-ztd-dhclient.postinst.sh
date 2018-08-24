#!/bin/bash
# Move the ZTD script and corresponding dhclient.conf to appropiate location

mv /etc/dhclient.conf /etc/dhcp/
mv /etc/ztd /etc/dhcp/dhclient-exit-hooks.d/
chmod +x /etc/dhcp/dhclient-exit-hooks.d/ztd
