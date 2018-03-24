#!/bin/bash

# Set /etc/apt/sources.list

mkdir -p /etc/apt

cat <<EOF >/etc/apt/sources.list
deb http://deb.openswitch.net/ unstable main opx opx-non-free
deb http://deb.openswitch.net/contrib stable contrib
deb http://deb.openswitch.net/ 2-updates main opx opx-non-free

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
apt-key adv --keyserver pgp.mit.edu --recv AD5073F1 || \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys AD5073F1

apt-get update

