#!/bin/bash

# Set /etc/apt/sources.list

mkdir -p /etc/apt

cat <<EOF >/etc/apt/sources.list
deb http://deb.openswitch.net/jessie unstable main opx opx-non-free
deb http://deb.openswitch.net/contrib stable contrib
deb http://deb.openswitch.net/jessie 2-updates main opx opx-non-free

deb http://httpredir.debian.org/debian/ jessie main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie main contrib non-free

deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie-backports main contrib non-free

deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie-updates main contrib non-free

deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free
EOF

# get deb.openswitch.net gpg key
apt-key adv --fetch-keys http://deb.openswitch.net/opx.asc

apt-get update

