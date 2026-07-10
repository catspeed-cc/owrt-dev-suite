# owrt-dev-suite

Private build script under GPLv3-or-later to be released publicly under same license.

`owrt-dev-suite` is a full development suite for OpenWRT developers intending to port devices to OpenWRT. These are the tools built (using AI) to help me port the TRENDnet TEW-829DRU router (also using AI) after they sent me an EOL notice in arly 2026. The centrepiece of the suite is of course, the advanced build script itself, which is highly configurable and customizable for your workflow.

Included tools: GPIO probing utility scripts.

To be released publicly under GPLv3-or-later

## ⚠️ LICENSE WARNING: GPLv2 / GPLv3 INCOMPATIBILITY⚠️

This build script is licensed under GPLv3-or-later. It is NOT compatible with GPLv2-only projects (such as the Linux Kernel or OpenWrt). It should be used only in development and testing, privately.

DO NOT use this script to build binaries for distribution if the underlying source code is licensed GPLv2-only.  Doing so creates a license conflict that makes the resulting binary undistributable and constitutes a copyright violation.

This script is intended for:

- Private use only (no distribution of binaries).
- Projects that are fully GPLv3 or GPLv2-or-later (where the user chooses GPLv3).

If you need a script for a fully compliant GPLv3 project you are free to use and modify this one to suit your needs.

If you need a script for OpenWrt and you intend to distribute binaries, use the GPLv2 version in the official repository to build those binaries (potentially coming soon).

If you need a script for private usage with OpenWRT and intend to keep the binaries to yourself, you may use this GPLv3 version.

**mooleshacat / catspeed.cc is not responsible for any potential license violations you create for yourself.**

## 🛠️ OpenWRT Developer Suite Utils

`owrt-dev-suite-utils` is integrated within this GPLv3-or-later project which contains useful scripts for probing GPIO's. Though please proceed at your own risk 😅

When cloning `owrt-dev-suite` repository, you may use `git clone --recursive --remote https://github.com/catspeed-cc/owrt-dev-suite.git` OR after cloning the repository run `git submodule update --init --recursive --remote` to obtain & update these useful utility scripts.

For advanced porting tools (GPIO Probe, DTS Extractor, etc.) to use in your GPLv3 project, see the dedicated **GPLv3 `owrt-dev-suite-utils`** repository:<br />
👉 [github.com/catspeed-cc/owrt-dev-suite-utils](https://github.com/catspeed-cc/owrt-dev-suite-utils)
