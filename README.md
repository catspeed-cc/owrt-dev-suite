# owrt-dev-suite

Private build script under GPLv3-or-later to be released publicly under same license.

`owrt-dev-suite` is a full development suite for OpenWRT developers intending to port devices to OpenWRT. These are the tools built (using AI) to help me port the TRENDnet TEW-829DRU router (also using AI) after they sent me an EOL notice in arly 2026. The centerpiece of the suite is of course, the advanced build script itself, which is highly configurable and customizable for your workflow.

Included tools: GPIO probing utility scripts.

To be released publicly under GPLv3-or-later

## ⚠️ LICENSE WARNING: GPLv2 / GPLv3 INCOMPATIBILITY⚠️

This build script is licensed under GPLv3-or-later. It is NOT compatible with GPLv2-only projects (such as the Linux Kernel or OpenWrt).

DO NOT use this script to build binaries for distribution if the underlying source code is licensed GPLv2-only.  Doing so creates a license conflict that makes the resulting binary undistributable and constitutes a copyright violation.

This script is intended for:

- Private use only (no distribution of binaries).
- Projects that are fully GPLv3 or GPLv2-or-later (where the user chooses GPLv3).

If you need a script for a fully compliant GPLv3-or-later project you are free to use and modify this one to suit your needs.

If you need a script for OpenWrt, use the GPLv2-or-later version in the official repository if you intend to distribute binaries (coming soon).

mooleshacat / catspeed.cc is not responsible for any potential license violations you create for yourself.

## 🛠️ OpenWRT Developer Suite Utils

`owrt-dev-suite-utils` is integrated within this GPLv3-or-later project which contains useful scripts for probing GPIO's. Though please proceed at your own risk :)

When cloning this repository, you may use `git clone --recursive --remote https://github.com/catspeed-cc/owrt-dev-suite.git` OR after cloning the repository run `git submodule update --init --recursive --remote`

For advanced porting tools (GPIO Probe, DTS Extractor, etc.), see the dedicated **GPLv3 `owrt-dev-suite-utils`**:<br />
👉 [github.com/catspeed-cc/owrt-dev-suite-utils](https://github.com/catspeed-cc/owrt-dev-suite-utils)

-----

## Current plan:
- Public Repo: Keep your highly customized, maximal freedom logic in a separate public GPLv3-or-later repository. 
- Public Contribution: Submit the generic, stripped-down version as GPLv2-or-later to OpenWrt to remain compliant with licenses.

Usage: You (and others) can use the OpenWrt version as a base and layer your private GPLv3 script on top of it locally.

-----

For OpenWRT slimmed down GPLv2 buildscript use:
```
# SPDX-License-Identifier: GPL-2.0-or-later
# (Optional) Copyright (C) 2024 Your Name <your@email.com>
```

For advanced configurable & customized maximal freedom buildscript use:
```
# SPDX-License-Identifier: GPL-3.0-or-later
# (Optional) Copyright (C) 2024 Your Name <your@email.com>
```
