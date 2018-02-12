#!/bin/bash

# Set /etc/apt/sources.list

mkdir -p /etc/apt

echo 'deb http://httpredir.debian.org/debian/ jessie main contrib non-free' > /etc/apt/sources.list
echo 'deb-src http://httpredir.debian.org/debian/ jessie main contrib non-free' >> /etc/apt/sources.list

echo 'deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free' >> /etc/apt/sources.list
echo 'deb-src http://httpredir.debian.org/debian/ jessie-backports main contrib non-free' >> /etc/apt/sources.list

echo 'deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free' >> /etc/apt/sources.list
echo 'deb-src http://httpredir.debian.org/debian/ jessie-updates main contrib non-free' >> /etc/apt/sources.list

echo 'deb http://security.debian.org/ jessie/updates main contrib non-free' >> /etc/apt/sources.list
echo 'deb-src http://security.debian.org/ jessie/updates main contrib non-free' >> /etc/apt/sources.list

echo 'deb http://deb.openswitch.net/ unstable main' >> /etc/apt/sources.list
apt-key adv --keyserver pgp.mit.edu --recv AD5073F1

apt-get update
