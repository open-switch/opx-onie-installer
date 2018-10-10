#!/bin/bash

# Set /etc/apt/sources.list

mkdir -p /etc/apt

cat <<EOF >/etc/apt/sources.list
deb http://deb.openswitch.net/stretch unstable main opx opx-non-free
deb http://deb.openswitch.net/stretch 3-updates main opx opx-non-free

deb http://deb.debian.org/debian/ stretch main contrib non-free
deb-src http://deb.debian.org/debian/ stretch main contrib non-free

deb http://deb.debian.org/debian/ stretch-backports main contrib non-free
deb-src http://deb.debian.org/debian/ stretch-backports main contrib non-free

deb http://deb.debian.org/debian/ stretch-updates main contrib non-free
deb-src http://deb.debian.org/debian/ stretch-updates main contrib non-free

deb http://security.debian.org/ stretch/updates main contrib non-free
deb-src http://security.debian.org/ stretch/updates main contrib non-free
EOF

# get deb.openswitch.net gpg key
apt-key adv --fetch-keys http://deb.openswitch.net/opx.asc

apt-get update

