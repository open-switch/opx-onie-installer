# OPX ONIE Installer

This repository holds the utilities and data files describing how to build an ONIE installation image for OPX.

Images are built using `opx_rel_pkgasm.py` in the [`opx-build`](https://github.com/open-switch/opx-build) repository (see [installation](https://github.com/open-switch/opx-build#installation)).

## Directories and files

```
opx-onie-installer/
├── inst-hooks/           - hooks for installation process
└── release_bp/           - blueprint directory
    ├── OPX_dell_base.xml - top-level blueprint for all Dell platforms
    ├── repo/             - Debian package repository definitions
    └── vendor/           - vendor-specific blueprint files
```

© 2018 Dell Inc. or its subsidiaries. All Rights Reserved.

