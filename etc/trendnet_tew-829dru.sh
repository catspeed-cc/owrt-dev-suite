#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


# ==================================================================
# User Configuration Variables                       (INSTRUCTIONS)
# ==================================================================
#
# Define your configuration in this file. Ensure the required
# sections are filled out correctly:
#
#  - OPWNWRT SOURCE & REPO
#  - DEVICE IDENTIFICATION
#  - BASE DIRECTORIES
#
# Variables not required will be commented
# You may uncomment to override the auto-derived defaults
# It's highly recommended to use the symlinks & auto-derived paths
#
# owrt-dev-suite keeps your work and projects directories organized
#


# ==================================================================
# OPENWRT SOURCE & REPO                                  (REQUIRED)
# ==================================================================

# Remote Alias
# Use a unique remote ailias for each remote to keep them separate
# Non-functional, but set anyways for when multi-port arrives
OWRT_REMOTE_ALIAS="catspeed-cc"

# YOUR OPENWRT FORK REPOSITORY INFO
# Your fork of the openwrt repository where your ports will live
OWRT_FORK_REPO="https://github.com/catspeed-cc/openwrt.git"

# OpenWRT version to base the port branch off of
OWRT_VERSION="25.12"

# Base openwrt branch (which openwrt version?)
# Base branch to auto create custom port/model branches from
# If you want to target earlier openwrt versions, change this
OWRT_BASE_BRANCH="openwrt-$OWRT_VERSION"

# Target custom port/model branch (your port branch)
# We added the BASE_BRANCH so we can build multiple openwrt versions
# provided we add a new branch, backport it, and create configs
OWRT_TARGET_BRANCH="trendnet_tew-829dru-$OWRT_VERSION"

# DEVICE_SUPPORTED
# Mark as supported under two conditions, either:
#  - device is already supported in openwrt mainline
#  - your port is complete (caldata from art, driver patches complete)
DEVICE_SUPPORTED="false"

# ENABLE_SYMLINK_SHORTCUTS
# Each model will have a symlink in root to your port model's directory
# containing the DTS, image-out, rawmod, patchmod, caldata, directories
ENABLE_SYMLINK_SHORTCUTS="true"


# ==================================================================
# DEVICE IDENTIFICATION                                  (REQUIRED)
#
# Device information is used for display and path derivation
# These are required for operation. Please configure sane values
# ==================================================================

# CURRENT PORT INFORMATION (for display only)
# TODO: multi-port and git support (using infinite string)
OWRT_MFR="TRENDnet"
OWRT_MODEL="TEW-829DRU"
OWRT_SOC="ipq4019"
OWRT_SOC_CLASS="ipq40xx"


# ==================================================================
# BASE DIRECTORIES                                       (REQUIRED)
#
# These base paths are used below to derive other paths.
# These are required for operation. Please configure sane values
# ==================================================================

WORK_DIR="$HOME/work"
PROJECT_DIR="$HOME/projects"

# Example override: $PROJECT_DIR/openwrt-dev
OWRT_DEV_DIR="$PROJECT_DIR/openwrt-dev"

# Needed for both IMGDIR_CPY and WEBSERVER_CPY features
IMGDIR_SRC="$OWRT_DEV_DIR/bin/targets/ipq40xx/generic"

# ==================================================================
# SHORTCUT SYMLINKS                                      (OPTIONAL)
#
# Enable sudo commands (will ask for password). You can disable this
# if you use root account, but it is not reccommended.
#
# It is *HIGHLY* reccommended to use a regular user account that has
# access to sudo with password (encouraged)
#
# Default: false
# Required for auto-dependency install and auto webserver_cpy setup
# ==================================================================

SUDO_ENABLE=true


# ==================================================================
# WORK SUB-DIRECTORIES - Override Points                 (OPTIONAL)
#
# These paths are used by the auto-creator and build steps
# Users can override any of these by uncommenting and changing them
# ==================================================================

# DEVICE_WORK_DIR="$WORK_DIR/ipq40xx/trendnet/tew-829dru"

# Example override: $WORK_DIR/ipq40xx/trendnet/tew-829dru/<directory>
# WORK_DTS_DIR="$DEVICE_WORK_DIR/dts"
# WORK_CALDATA_DIR="$DEVICE_WORK_DIR/caldata"
# WORK_PATCHMODS_DIR="$DEVICE_WORK_DIR/patchmods"
# WORK_RAWMODS_DIR="$DEVICE_WORK_DIR/rawmods"
# WORK_IMAGEOUT_DIR="$DEVICE_WORK_DIR/image-out"




# =================================================================
# COPY DTS TO target/                                   (OPTIONAL)
#
# These paths are used by the auto-creator and build steps
# Users can override any of these by uncommenting and changing them
# ==================================================================

# DTS_CPY: Enable copy of DTS file
DO_DTS_CPY=true

# DTS Paths
# SHARED BETWEEN SRC (WORK_DTS_DIR AND DTS_DEST_DIR)
DTS_FNAME="qcom-ipq4019-tew-829dru.dts"
DTS_DEST_DIR="$OWRT_DEV_DIR/target/linux/ipq40xx/files-6.12/arch/arm/boot/dts/qcom"


# =================================================================
# COPY IMAGES TO WORK_IMAGEOUT_DIR                      (OPTIONAL)
#
# These paths are used to copy build images into WORK_IMAGEOUT_DIR
# Users can override any of these by uncommenting and changing them
#
# Default: true
# ==================================================================

# DO_IMGDIR_CPY: Enable image copy to work dir on build
DO_IMGDIR_CPY=true


# =================================================================
# COPY IMAGES TO WEBSERVER DIR                          (OPTIONAL)
#
# This feature will copy the images to your webserver shared
# directory. It will organize in similar manner to your WORK_DIR.
# A link will be made from the shared directory to your webserver
# downloads/ directory.
#
# Users can override any of these by uncommenting and changing them
# ==================================================================
#
# REQUIRED:
#  - fully configured webserver (NGINX, Lighttpd, Apache, etc.)
#  - configured downloads/ directory with file listing enabled
#

# DO_IMGDIR_CPY: Enable image copy to webserver shared dir on build
DO_WEBSERVER_CPY=true

# Webserver configuration
WEBSERVER_USER="www-data"
WEBSERVER_SHARED_GROUP="openwrt-build"
WEBSERVER_SHARED_DIR="/srv/openwrt-builds"
WEBSERVER_ROOT="/var/www/catspeed.cc/downloads"


# Commands to restart your webserver (choose one)
#
# `sudo` should be required, because you use a user account right?
# you certainly wouldn't run as root like a neanderthal, not you.

# Nginx
WEBSERVER_RESTART_CMD="sudo systemctl restart nginx"

# Lighttpd
# WEBSERVER_RESTART_CMD="sudo systemctl restart lighttpd"

# Apache
# WEBSERVER_RESTART_CMD="sudo systemctl restart apache2"

# Direct init script
# WEBSERVER_RESTART_CMD="sudo /etc/init.d/webserver reload"


# =================================================================
# APPLY PATCHES OR RAW DRIVER MOD                       (OPTIONAL)
#
# This feature will copy your patch and apply it to the source tree
# to be built into the image.
#
# Users can override any of these by uncommenting and changing them
# ==================================================================

# DO_DRIVERMOD_CPY: Enable drivermod (patchmod & rawmod)
DO_DRIVERMOD_CPY=true

# Select either `patchmod` or `drivermod` mode
DRIVERMOD_MODE=rawmod

# TODO: Update PATCHMOD_DEST_DIR to use full path by using OWRT_DEV_DIR

# Patches destination path (inside OWRT_DEV_DIR)
PATCHMOD_DEST_DIR="target/linux/ipq40xx/patches-6.12/"


# ===================================
# IPQESS DUAL NETDEV RAWMOD (EXAMPLE)
# ===================================

# IPQESS Mod Files
RAWMOD_LIST+="ipqess.h|$WORK_RAWMODS_DIR/ipqess/ipqess.h.modified|$OWRT_DEV_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-ipq40xx_generic/linux-6.12.91/drivers/net/ethernet/qualcomm/ipqess/ipqess.h"$NL
RAWMOD_LIST+="ipqess.c|$WORK_RAWMODS_DIR/ipqess/ipqess.c.modified|$OWRT_DEV_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-ipq40xx_generic/linux-6.12.91/drivers/net/ethernet/qualcomm/ipqess/ipqess.c"$NL
RAWMOD_LIST+="ipqess_ethtool.c|$WORK_RAWMODS_DIR/ipqess/ipqess_ethtool.c.modified|$OWRT_DEV_DIR/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-ipq40xx_generic/linux-6.12.91/drivers/net/ethernet/qualcomm/ipqess/ipqess_ethtool.c"$NL


# =================================================================
# COPY CALDATA TO IMAGE                                 (OPTIONAL)
#
# This feature will copy your caldata to the correct location
# to be built into the image.
#
# Note: You generally only need caldata when just starting DTS
#       work and can't pull it from ART yet or are debugging.
#
# Note: You will need to do a clean build and update feeds.
#
# Users can override any of these by uncommenting and changing them
# ==================================================================

# CALDATA FLAG
DO_CALDATA_CPY=false

# Calibration Data Files
CALDATA_LIST+="qca4019-board-2.bin|$WORK_CALDATA_DIR/QCA4019/qca4019-artcaldata.bin|ath10k/QCA4019/hw1.0/board-2.bin"$NL
CALDATA_LIST+="qca9984-board-2.bin|$WORK_CALDATA_DIR/QCA9984/qca9984-artcaldata.bin|ath10k/QCA9984/hw1.0/board-2.bin"$NL

