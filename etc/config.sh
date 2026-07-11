#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

        # TODO: check if OWRT_PORT_BRANCH exists if not create it from OPENWRT_FORK_REPO_BRANCH and checkout OWRT_PORT_BRANCH
        # TODO: cd back to STARTUP_PWD
        # TODO: display

# ==============================================================================
# Developer Configuration Variables             (START CONFIGURING HERE)
# ==============================================================================


WORK_DIR="$HOME/work"
PROJECT_DIR="$HOME/projects"
OWRT_OWRT_DEV_DIR="$PROJECT_DIR/openwrt-dev"

# YOUR OPENWRT FORK REPOSITORY INFO
OPENWRT_FORK_REPO="https://github.com/catspeed-cc/openwrt.git"

# TARGET OPENWRT BASE BRANCH
# we create fork model branches based off this
OPENWRT_FORK_REPO_BRANCH="25.12"

# CURRENT PORT INFORMATION (for display only)
# TODO: multi-port and git support (using infinite string)
OWRT_SOC="ipq40xx"
OWRT_MFR="TRENDnet"
OWRT_MODEL="TEW-829DRU"
OWRT_TARGET="linux"

# Enable sudo commands (will ask for password)
# Ensure user account either is root (discouraged) or has sudo with password (encouraged)
# Required for auto-dependency install, auto webserver_cpy setup, and other auto configurations
SUDO_ENABLE=true

# DTS_CPY: Enable copy of DTS file
DO_DTS_CPY=true

# DTS Paths
DTS_DEST_DIR="files-6.12/arch/arm/boot/dts/qcom"
DTS_DEST_FNAME="qcom-ipq4019-tew-829dru.dts"

# Patches paths
PATCHMOD_SRC_DIR="$WORK_DIR/PATCHES"
PATCHMOD_DEST_DIR="patches-6.12"

# IMGDIR_CPY: Enable image copy on build
DO_IMGDIR_CPY=true

# Image out paths
IMGDIR_SRC="$OWRT_DEV_DIR/bin/targets/ipq40xx/generic"
IMGDIR_DEST="$WORK_DIR/image-out"

# TODO: move caldata dirs here

# WEBSERVER_CPY: Copy images to webserver
# USAGE: when enabled it will copy the images also to your webserver directory
DO_WEBSERVER_CPY=true

# Webserver configuration
WEBSERVER_USER="www-data"
WEBDIR_DEST="/srv/openwrt-builds/"


# PATCHMOD: Enable BOTH driver patch AND raw mod (see DO_RAWMOD below to pick)
# IMPORTANT: set `DO_PATCHMOD=true` if you want to use either the patch or the raw driver mod
# USAGE: toggle between the two with `DO_RAWMOD=true` & `DO_RAWMOD=false`
DO_PATCHMOD=true

# ==========================================================
# RAWMOD_LIST INFINITE STRING PATCH LIST(S) BELOW (SEE DOCS)
# ==========================================================

# Note: You generally only need rawmod when making a driver
#       modification and building it from the source. 
#       Otherwise you would use a patch.
#
# Note: You will need to do a clean build and update feeds.

# RAWMOD - Enable raw driver mod instead of patch (DO_PATCHMOD must be true)
DO_RAWMOD=true

# ========================
# IPQESS DUAL NETDEV PATCH
# ========================

# Set the caldata destination directory below
IPQESS_MOD_DEST_DIR=($OWRT_DEV_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-ipq40xx_generic/linux-6.12.91/drivers/net/ethernet/qualcomm/ipqess)

# IPQESS Mod Files
RAWMOD_LIST+="ipqess.h|$WORK_DIR/IPQESS_DRIVER_MOD/ipqess.h.modified|$IPQESS_MOD_DEST_DIR/ipqess.h"$NL
RAWMOD_LIST+="ipqess.c|$WORK_DIR/IPQESS_DRIVER_MOD/ipqess.c.modified|$IPQESS_MOD_DEST_DIR/ipqess.c"$NL
RAWMOD_LIST+="ipqess_ethtool.c|$WORK_DIR/IPQESS_DRIVER_MOD/ipqess_ethtool.c.modified|$IPQESS_MOD_DEST_DIR/ipqess_ethtool.c"$NL




# ===========================================================
# CALDATA_LIST INFINITE STRING PATCH LIST(S) BELOW (SEE DOCS)
# ===========================================================

# Note: You generally only need caldata when just starting DTS
#       work and can't pull it from ART yet or are debugging.
#
# Note: You will need to do a clean build and update feeds.

# CALDATA FLAG
DO_CALDATA_CPY=false

# Set the caldata destination directory below
# TODO: Dynamically determine this based on the .config / build environment
CALDATA_DEST_DIR=(./build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-firmware-*)

# Calibration Data Files
CALDATA_LIST+="qca4019-board-2.bin|$WORK_DIR/BUILDSYS/QCA4019/board-2.bin|$CALDATA_DEST_DIR/board-2.bin"$NL
CALDATA_LIST+="qca9984-board-2.bin|$WORK_DIR/BUILD_SYS/QCA9984/board-2.bin|$CALDATA_DEST_DIR/board-2.bin"$NL


