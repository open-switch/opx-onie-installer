#!/bin/sh

#######################################################################
# Dell OPX Installer
#######################################################################

#######################################################################
# OPX Data
export OS_NAME=@@OS_NAME@@
export OS_VERSION=@@OS_VERSION@@
export PLATFORM=@@PLATFORM@@
export ARCHITECTURE=@@ARCHITECTURE@@
export INTERNAL_BUILD_ID=@@INTERNAL_BUILD_ID@@
export BUILD_VERSION=@@BUILD_VERSION@@
export BUILD_DATE=@@BUILD_DATE@@
#######################################################################

# Enable error handling
set -e

INSTALLER=$(realpath "$0")
TMP_DIR=$(mktemp -d)

cd $TMP_DIR

# Extract installer scripts
echo -n "Initializing installer..."
sed -e '1,/^__INSTALLER__$/d;/^__IMAGE__$/,$d' "$INSTALLER" |
    base64 -d | tar xzf -
echo "OK"

# Load the installer library files
cd installer
. install_support.sh

install_main
rc="$?"

exit $rc
__INSTALLER__
