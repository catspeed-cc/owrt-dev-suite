#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# ==============================================================================
# Developer Configuration Variables             (START CONFIGURING HERE)
# ==============================================================================

WORK_DIR="$HOME/work"
DEV_DIR="$HOME/my-repositories/openwrt-dev"


# DTS_CPY: Enable copy of DTS file
DO_DTS_CPY=true

# DTS Paths
DTS_SRC="$WORK_DIR/dts/qcom-ipq4019-tew-829dru.dts"
DTS_DEST_DIR="$DEV_DIR/target/linux/ipq40xx/files-6.12/arch/arm/boot/dts/qcom"

# Patches paths
PATCHMOD_SRC_DIR="$WORK_DIR/PATCHES"
PATCHMOD_DEST_DIR="$DEV_DIR/target/linux/ipq40xx/patches-6.12"

# IMGDIR_CPY: Enable image copy on build
DO_IMGDIR_CPY=true

# Image out paths
IMGDIR_SRC="$DEV_DIR/bin/targets/ipq40xx/generic"
IMGDIR_DEST="$WORK_DIR/image-out"

# TODO: move caldata dirs here

# WEBSERVER_CPY: Copy images to webserver
# USAGE: when enabled it will copy the images also to your webserver directory
DO_WEBSERVER_CPY=true

# Webserver configuration
WEBSERVER_USER="www-data"
WEBDIR_DEST="/srv/openwrt-builds/ipq40xx/trendnet/tew-829dru/25.12"


# PATCHMOD: Enable BOTH driver patch AND raw mod (see DO_RAWMOD below to pick)
# IMPORTANT: set `DO_PATCHMOD=true` if you want to use either the patch or the raw driver mod
# USAGE: toggle between the two with `DO_RAWMOD=true` & `DO_RAWMOD=false`
DO_PATCHMOD=true

# ==========================================================
# RAWMOD_LIST INFINITE STRING PATCH LIST(S) BELOW (SEE DOCS)
# ==========================================================

# RAWMOD - Enable raw driver mod instead of patch (DO_PATCHMOD must be true)
DO_RAWMOD=true

# ========================
# IPQESS DUAL NETDEV PATCH
# ========================
# IPQESS Mod Paths
IPQESS_MOD_SRC_DIR="$WORK_DIR/IPQESS_DRIVER_MOD"

# Set the caldata destination directory below
IPQESS_MOD_DEST_DIR=($DEV_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-ipq40xx_generic/linux-6.12.91/drivers/net/ethernet/qualcomm/ipqess)

# IPQESS Mod Files
RAWMOD_LIST+="ipqess.h|$IPQESS_MOD_SRC_DIR/ipqess.h.modified|$IPQESS_MOD_DEST_DIR/ipqess.h"$NL
RAWMOD_LIST+="ipqess.c|$IPQESS_MOD_SRC_DIR/ipqess.c.modified|$IPQESS_MOD_DEST_DIR/ipqess.c"$NL
RAWMOD_LIST+="ipqess_ethtool.c|$IPQESS_MOD_SRC_DIR/ipqess_ethtool.c.modified|$IPQESS_MOD_DEST_DIR/ipqess_ethtool.c"$NL




# ===========================================================
# CALDATA_LIST INFINITE STRING PATCH LIST(S) BELOW (SEE DOCS)
# ===========================================================

# CALDATA FLAG
DO_CALDATA_CPY=false

# Calibration Data Paths
CALDATA_QCA4019_SRC_DIR="$WORK_DIR/BUILDSYS/QCA4019"
CALDATA_QCA9984_SRC_DIR="$WORK_DIR/BUILD_SYS/QCA9984"

# Set the caldata destination directory below
CALDATA_DEST_DIR=(./build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-firmware-*)

# Calibration Data Files
CALDATA_LIST+="qca4019-board-2.bin|$CALDATA_QCA4019_SRC_DIR/board-2.bin|$CALDATA_DEST_DIR/board-2.bin"$NL
CALDATA_LIST+="qca9984-board-2.bin|$CALDATA_QCA9984_SRC_DIR/board-2.bin|$CALDATA_DEST_DIR/board-2.bin"$NL


