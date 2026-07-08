# owrt-build-release

Private build script under GPLv3-or-later

To be released publicly under GPLv3-or-later

## ⚠️ LICENSE WARNING: GPLv3 INCOMPATIBILITY

This build script is licensed under GPLv3.  It is NOT compatible with GPLv2-only projects (such as the Linux Kernel or OpenWrt).

DO NOT use this script to build binaries for distribution if the underlying source code is licensed GPLv2-only.  Doing so creates a license conflict that makes the resulting binary undistributable and constitutes a copyright violation.

This script is intended for:

- Private use only (no distribution of binaries).
- Projects that are fully GPLv3 or GPLv2-or-later (where the user chooses GPLv3).

If you need a script for a fully compliant GPLv3-or-later project you are free to use and modify this one to suit your needs.

If you need a script for OpenWrt, use the GPLv2-or-later version in the official repository if you intend to distribute binaries (coming soon).

mooleshacat / catspeed.cc is not responsible for any potential license violations you create for yourself.


-----

## Current plan:
- Public Repo: Keep your highly customized, maximal freedom logic in a separate GPLv3-or-later repository. 
- Public Contribution: Submit the generic, stripped-down version as GPLv2-or-later to OpenWrt. 

Usage: You (and others) can use the OpenWrt version as a base and layer your private GPLv3 script on top of it locally.

-----

For neutered OpenWRT buildscript use:
```
# SPDX-License-Identifier: GPL-2.0-or-later
# (Optional) Copyright (C) 2024 Your Name <your@email.com>
```

For maximal freedom custom buildscript use:
```
# SPDX-License-Identifier: GPL-3.0-or-later
# (Optional) Copyright (C) 2024 Your Name <your@email.com>
```