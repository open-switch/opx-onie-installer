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

echo 'deb http://dl.bintray.com/open-switch/opx-apt jessie main' >> /etc/apt/sources.list
echo 'deb http://dell-networking.bintray.com/opx-apt jessie main' >> /etc/apt/sources.list

curl -fsSL https://bintray.com/user/downloadSubjectPublicKey?username=dell-networking | apt-key add -
curl -fsSL https://bintray.com/user/downloadSubjectPublicKey?username=open-switch | apt-key add -
apt-get update
