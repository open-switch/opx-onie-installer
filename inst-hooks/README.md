OPX Installation hooks
=======================

This folder contains a number of hook scripts that are included by the
blueprints into the installer image. These scripts are run with root privileges
and can do anything necessary within the chroot jail to configure OPX.

Hook scripts must be Bourne-shell compatible shell scripts, be marked as
executable, and the filename must end with `.preinst.sh` or `.postinst.sh`.
extension. Any scripts residing in /root/hooks will be run, so to enforce an
order to this, it is recommended to prefix each script with a number (eg.
`10_opx_base.postinst.sh`)

The preinst hook scripts are run before any packages are installed and before
the rootfs packages are reconfigured. The postinst hook scripts are run after
the OPX packages are installed for the given platform and flavor, but before
the packages are cleaned up. If a hook script exits with an error, the overall
installation fails since the calling script is run with `set -e`.

Each hook script must be explicitly specified in the blueprint using the tag
`inst_hook` in order to be copied. You only need to specify the basename of
the script, not the full path. opx_rel_pkgasm.py will assume it resides in the
folder `opx-onie-installer/inst-hooks`.

# Upgrade Scripts

Upgrade scripts are similar to the install hook scripts and specified in the
same manner in the blueprint. The only difference is that they must have the
suffix `.pre-upgrade.<ext>` or `.post-upgrade.<ext>`, where `<ext>` is any
extension. These are executed by the opx-image script when upgrading the
standby partition, and run in the OPX context. They have full access to the
system, including the complete set of mountpoints.
