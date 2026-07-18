#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


# ============================================
# NOTE: DO NOT CONFIGURE ANYTHING IN THIS FILE
# Edit `./etc/config.sh` to configure
# ============================================


# Version Information
OWRTDS_VERSION=$(cat .version)

# mutex / lock file
LOCK_FILE="$STARTUP_PWD/.owrtds.lock"

# Guard variable to prevent double cleanup
CLEANED=false

# Import earlyscript.functions.sh
if ! source "$SCRIPT_DIR/lib/earlyscript.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/earlyscript.functions.sh - Aborting." >&2
    exit 1
fi

# Create the mutex lock
create_lock

# Detect the OWRTDS_BRANCH
OWRTDS_BRANCH=""
owrtds_branch_detect

# Set up for infinite strings (NEEDED IN `lib/config.sh`)
NL=$'\n' # leave this alone (used in multiple areas)

# Flags default values (safe defaults)
DO_CLEAN=false
DO_UPDATE_FEEDS=false
DO_VERBOSE=false
DO_XVERBOSE=false
DO_SLOW=false

CONFIG_FILE="$SCRIPT_DIR/etc/config.sh"
OWRTDS_CUSTOM_CONFIG=""

# Populate build start time
BUILD_START_DATE=$(date "+%a %d %b %Y")
BUILD_START_TIME=$(date +%H:%M:%S)

# Populated at the end of script
BUILD_STOP_DATE=""
BUILD_STOP_TIME=""
BUILD_ELAPSED=""
export BUILD_ELAPSED_SECONDS=""

# Required to start blank/empty
SUMMARY_OUT=""
MAKE_CMD_ADD=""
CUSTOM_CONFIG_PATH=""

# Interactive Mode Control
OWRTDS_INTERACTIVE=true
# Auto-detect non-interactive mode (e.g., piped input, cron jobs, CI/CD)
if [[ ! -t 0 ]]; then
    OWRTDS_INTERACTIVE=false
fi

# ====================================================================================
# TO AVOID FAILURE IN `set -euo pipefail` MODE DEFINE USER VARIABLES WHICH ARE EITHER:
#  - only user defined in lib/config.sh
#  - derived from user defined but user overrideable in lib/config.sh
# Internal/Derived only variables will remain defined inline where used
# ====================================================================================
#
# DO NOT MANUAL EDIT THESE - THEY ARE DEFAULTS. USER EDITS IN `etc/config.sh`.
#
# USER CONFIG VARIABLES (DEFAULTS)
#
OWRT_REMOTE_ALIAS=""
OWRT_FORK_REPO=""
OWRT_VERSION=""
OWRT_BASE_BRANCH=""
OWRT_TARGET_BRANCH=""

DEVICE_SUPPORTED="true"
ENABLE_SYMLINK_SHORTCUTS="true"

OWRT_MFR=""
OWRT_MODEL=""
OWRT_SOC=""
OWRT_SOC_CLASS=""

OWRT_MFR_LOWER=""
OWRT_MFR_LOWER=""
OWRT_MODEL_LOWER=""
OWRT_SOC_LOWER=""
OWRT_SOC_CLASS_LOWER=""

WORK_DIR=""
PROJECT_DIR=""
OWRT_DEV_DIR=""
IMGDIR_SRC=""

SUDO_ENABLE="false"

DEVICE_WORK_DIR=""

WORK_DTS_DIR=""
WORK_CALDATA_DIR=""
WORK_PATCHMODS_DIR=""
WORK_RAWMODS_DIR=""
WORK_IMAGEOUT_DIR=""

DO_DTS_CPY="false"
DTS_FNAME=""
DTS_DEST_DIR=""

DO_IMGDIR_CPY="true"

DO_WEBSERVER_CPY="false"
WEBSERVER_USER=""
WEBSERVER_SHARED_GROUP=""
WEBSERVER_SHARED_DIR=""
WEBSERVER_ROOT=""
WEBSERVER_RESTART_CMD=""

DEVICE_SHARED_DIR=""

DO_DRIVERMOD_CPY="false"
DRIVERMOD_MODE=""
PATCHMOD_DEST_DIR=""
RAWMOD_LIST=""

DO_CALDATA_CPY="false"
CALDATA_LIST=""

# ===========================================================================================

# ===========================================================================================
# 1. SOURCE LIBRARIES FIRST (Defines functions like parse_arguments, install_dependencies)
# ===========================================================================================
if ! source "$SCRIPT_DIR/lib/dependencies.sh"; then
    echo "❌ CRITICAL: Unable to source lib/dependencies.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/utils.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/utils.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/logging.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/logging.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/exit.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/exit.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/cli.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/cli.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/config.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/config.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/file-io.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/file-io.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/setup.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/setup.functions.sh - Aborting." >&2
    exit 1
fi
if ! source "$SCRIPT_DIR/lib/build.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/build.functions.sh - Aborting." >&2
    exit 1
fi



# ===========================================================================================
# 2. PARSE CLI ARGUMENTS (Detects --config/-c override before sourcing config)
# ===========================================================================================
parse_arguments "$@"


# ===========================================================================================
# 3. RESOLVE & SOURCE CONFIG (Uses CLI override if present, otherwise default)
# ===========================================================================================

resolve_configuration_file

# Source the determined config
if ! source "$CONFIG_FILE"; then
    echo "❌ CRITICAL: Unable to source $CONFIG_FILE - Aborting." >&2
    exit 1
else
    log_summary " >>> ✅ Config file loaded: $CONFIG_FILE" --silent
fi


# ===========================================================================================
# 4. INSTALL DEPENDENCIES (Now available since functions.sh is sourced)
# ===========================================================================================
install_dependencies


# ===========================================================================================
# 5. verify config - vars above this point must not use eachother (EXCEPT CRITICAL startup vars)
# ===========================================================================================
verify_configuration
# ===========================================================================================
# 5. verify config - vars below this point can use each other to autoconfigure
# ===========================================================================================


# ===========================================================================================
# 6. Synchronize OpenWRT .config from Work Directory
# ===========================================================================================
sync_config_to_dev_dir


# ===========================================================================================
# 7. Show our pretty header :3
# ===========================================================================================

# Show the header (now that config is loaded and verified)
show_header


# ===========================================================================================
# 8. Check if there is a .config file , if not exit_with_error
# ===========================================================================================

# Checks if there is a .config in the OWRT_DEV_DIR after having copied it from sync_config_to_etc_dir above
if [[ ! -f "$OWRT_DEV_DIR/.config" ]]; then
    exit_with_error "No .config file found. Ensure the file exists. (run 'make menuconfig' to create one, then copy it to your work directory for the device)"
fi


# ==============================================================================
# 9. Execution Preperation
# ==============================================================================

# Ensure we go back to the original PWD before build
change_directory "$STARTUP_PWD"

# Handle Concurrency
if [ "$DO_SLOW" = false ]; then
    NUM_PROC=$(nproc)
    MAKE_CMD_ADD="${MAKE_CMD_ADD}-j${NUM_PROC}"
else
    MAKE_CMD_ADD="${MAKE_CMD_ADD}-j1"
fi

# Handle Verbosity
if [ "$DO_VERBOSE" = true ]; then
    MAKE_CMD_ADD="${MAKE_CMD_ADD} V=s"
elif [ "$DO_XVERBOSE" = true ]; then
    MAKE_CMD_ADD="${MAKE_CMD_ADD} V=99"
fi

# Handle silent make in non-interactive mode
if [[ "$OWRTDS_INTERACTIVE" == "false" ]]; then
    MAKE_CMD_ADD="${MAKE_CMD_ADD} -s"
fi

# Register the trap ONLY for interruption signals (INT, TERM, HUP)
# Do NOT trap EXIT here; let your wrappers handle normal exits.
# Define specific handlers for each signal to pass the name correctly
trap 'exit_with_error "Caught by trap - user pressed CTRL+C (SIGINT). Aborting."' INT
trap 'exit_with_error "Caught by trap - script terminated (SIGTERM). Aborting."' TERM
trap 'exit_with_error "Caught by trap - connection hung up (SIGHUP). Aborting."' HUP
# we skipped my idea of using a trap exit handler - neat!
