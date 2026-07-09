#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# ==============================================================================
# Developer Configuration Variables             (START CONFIGURING HERE)
# ==============================================================================

WORK_DIR="$HOME/work"
DEV_DIR="$HOME/my-repositories/openwrt-dev"

# DTS Paths
DTS_SRC="$WORK_DIR/dts/qcom-ipq4019-tew-829dru.dts"
DTS_DEST="$DEV_DIR/target/linux/ipq40xx/files-6.12/arch/arm/boot/dts/qcom"

# Patches paths
PATCHES_SRC_DIR="$WORK_DIR/PATCHES"
PATCHES_DEST_DIR="$DEV_DIR/target/linux/ipq40xx/patches-6.12"

# Image out paths
IMG_OUT_SRC="$DEV_DIR/bin/targets/ipq40xx/generic"
IMG_OUT_DEST="$WORK_DIR/image-out"


# DTSCOPY - Enable copy of DTS file
DO_DTS_CPY=true

# PATCHMOD - Enable either driver patch OR raw mod
DO_PATCHMOD=true

# RAWMOD - Enable raw driver mod instead of patch (DO_PATCHMOD must be true)
DO_RAWMOD=true

# CALDATA FLAG
DO_CALDATA_CPY=false




# ==========================================================
# RAWMOD_LIST INFINITE STRING PATCH LIST(S) BELOW (SEE DOCS)
# ==========================================================

# separator comment

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
# Calibration Data Paths
CALDATA_QCA4019_SRC_DIR="$WORK_DIR/BUILDSYS/QCA4019"
CALDATA_QCA9984_SRC_DIR="$WORK_DIR/BUILD_SYS/QCA9984"

# Set the caldata destination directory below
CALDATA_DEST_DIR=(./build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-firmware-*)

# Calibration Data Files
CALDATA_LIST+="qca4019-board-2.bin|$CALDATA_QCA4019_SRC_DIR/board-2.bin|$CALDATA_DEST_DIR/board-2.bin"$NL
CALDATA_LIST+="qca9984-board-2.bin|$CALDATA_QCA9984_SRC_DIR/board-2.bin|$CALDATA_DEST_DIR/board-2.bin"$NL


