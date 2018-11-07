#!/bin/bash

# This postinst script sets the corefile settings

mkdir -p /var/cores
echo "#Kernel corefile pattern" >> /etc/sysctl.conf
echo "kernel.core_pattern = /var/cores/core.%e.%p" >> /etc/sysctl.conf
echo "*   hard   core   unlimited" >> /etc/security/limits.conf
echo "*   soft   core   unlimited" >> /etc/security/limits.conf

