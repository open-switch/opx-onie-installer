#!/bin/sh
##
## Description :- OPX ONIE nos installer.
## Author:- Srideep Devireddy
##


arch=$1
output_file=$2
rootfs=$3

# locate installer directory relative to this script
installer_dir=$(dirname $0)/installer

if  [ ! -d $installer_dir ] || \
    [ ! -r $installer_dir/sharch_body.sh ] ; then
    echo "Error: Invalid installer script directory: $installer_dir"
    exit 1
fi

if  [ ! -d $installer_dir/$arch ] || \
    [ ! -r $installer_dir/$arch/install_support.sh ] ; then
    echo "Error: Invalid arch installer directory: $installer_dir/$arch"
    exit 1
fi

tmp_dir=$(mktemp -d)
trap "rm -rf $tmp_dir" EXIT

# make the data archive
# contents:
#   - kernel and initramfs
#   - install.sh

#echo -n "$arch $installer_dir $output_file "
#echo -n "directory is $tmp_dir"

echo -n "Building self-extracting OPX install image ."
tmp_installdir="$tmp_dir/installer"
echo -n "directory $tmp_installdir"
mkdir -p $tmp_installdir || exit 1

cp $installer_dir/$arch/*.sh $tmp_installdir || exit 1
echo -n "."
cp -r $installer_dir/$arch/lib $tmp_installdir || exit 1
echo -n "."
cp -r $installer_dir/$arch/machine $tmp_installdir || exit 1
echo -n "."
cat $rootfs | sha1sum > $tmp_installdir/image_checksum
echo -n "."

sharch="$tmp_dir/sharch.tar.gz"
tar -C $tmp_dir -czf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    exit 1
}
echo -n "."

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    exit 1
}

echo -n "."
echo -n "copying init script $output_file"

cp -rf $installer_dir/sharch_body.sh $output_file || {

    echo "Error: Problems copying sharch_body.sh"
    exit 1
}

# Replace the variables in the output file
sed -i  -e "s/@@OS_NAME@@/$INSTALLER_OS_NAME/" \
        -e "s/@@OS_VERSION@@/$INSTALLER_OS_VERSION/" \
        -e "s/@@PLATFORM@@/$INSTALLER_PLATFORM/" \
        -e "s/@@ARCHITECTURE@@/$INSTALLER_ARCHITECTURE/" \
        -e "s/@@INTERNAL_BUILD_ID@@/$INSTALLER_INTERNAL_BUILD_ID/" \
        -e "s/@@BUILD_VERSION@@/$INSTALLER_BUILD_VERSION/" \
        -e "s/@@BUILD_DATE@@/$INSTALLER_BUILD_DATE/" \
    $output_file

cat $sharch | base64 >> $output_file
echo >> $output_file
echo '__IMAGE__' >> $output_file
echo -n "."
cat $rootfs >> $output_file
echo -n "."
echo " Done."

echo "Success:  OPX install image is ready in ${output_file}:"
ls -l ${output_file}

exit 0
