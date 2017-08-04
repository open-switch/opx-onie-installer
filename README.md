# OPX Onie Installer

This repository holds the utilities and data files describing how to build an ONIE installation image for OPX.

Images are built using `opx_rel_pkgasm.py` in the [`opx-build`](http://git.openswitch.net/cgit/opx/opx-build/) repository. See the [installation section](https://github.com/open-switch/opx-build#installation) in `opx-build` for more information.

## Directories and files

```
opx-onie-installer/
├── build_opx_rootfs.sh   - create a gzipped tarfile rootfs image
├── inst-hooks/           - hooks for installation process
├── release_bp/           - blueprint directory
│   ├── OPX_dell_base.xml - top-level blueprint for all Dell platforms
│   ├── repo/             - Debian package repository definitions
│   └── vendor/           - vendor-specific blueprint files
└── rootconf/             - extra files to be included in the rootfs
```

