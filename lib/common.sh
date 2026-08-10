#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


# ============================================
# NOTE: DO NOT CONFIGURE ANYTHING IN THIS FILE
# Edit `./etc/config.sh` to configure
# ============================================

# DEBUG FLAG (0 = off, 1+ = more verbose)
OWRTDS_DEBUG=0

# Temporary Directory
TMP_DIR="/tmp/owrt-dev-suite"

# PID files
OWRT_BUILD_PID_FILE="owrt-build.pid"
OWRT_BUILD_ALL_PID_FILE="owrt-build-all.pid"

# NOTICE: THIS IS REQUIRED FOR SCRIPT! DO NOT REMOVE!
#
# REASONS:
# - Script is heavy in file operations
# - One unbound variable within a derived path can mangle an undesired location
# - I need to see and know when something is unbound and fix it
set -Eemuo pipefail

# Obtain STARTUP_PWD & ensure STARTUP_PWD does not have a trailing slash for consistent matching
STARTUP_PWD=$(pwd)
STARTUP_PWD="${STARTUP_PWD%/}"

# REQUIRED FOR SOURCE LINES (DO NOT MODIFY)
REAL_PATH=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null)

# Fallback for macOS (BSD readlink doesn't support -f)
if [ -z "$REAL_PATH" ]; then
    REAL_PATH="${BASH_SOURCE[0]}"
    while [ -h "$REAL_PATH" ]; do
        DIR="$(dirname "$REAL_PATH")"
        # Check if directory exists before cd-ing
        if [ ! -d "$DIR" ]; then
            echo " >>> ❌ CRITICAL: Directory does not exist: $DIR" >&2
            exit 1
        fi
        DIR=$(cd -P "$DIR" && pwd)

        REAL_PATH=$(readlink "$REAL_PATH")
        [[ $REAL_PATH != /* ]] && REAL_PATH="$DIR/$REAL_PATH"
    done

    # Final resolve of the last step if it wasn't a symlink loop
    if [ -e "$REAL_PATH" ]; then
        DIR="$(dirname "$REAL_PATH")"
        # Check if directory exists before cd-ing
        if [ ! -d "$DIR" ]; then
            echo " >>> ❌ CRITICAL: Directory does not exist: $DIR" >&2
            exit 1
        fi
        REAL_PATH=$(cd -P "$DIR" && pwd)/$(basename "$REAL_PATH")
    fi
fi

# REQUIRED FOR SOURCE LINES (DO NOT MODIFY)
SCRIPT_DIR=$(dirname "$REAL_PATH")
SCRIPT_NAME=$(basename "$REAL_PATH")

# ===========================================================================================
# 2. PARSE CLI ARGUMENTS (Detects --config/-c override before sourcing config)
# ===========================================================================================
# Import cli.bootstrap.sh
if ! source "$SCRIPT_DIR/lib/cli.bootstrap.sh"; then
    echo "❌ CRITICAL: Unable to source lib/cli.bootstrap.sh - Aborting." >&2
    exit 1
else
    if [[ "$OWRTDS_DEBUG" -gt "0" ]]; then echo "[DEBUG] sourced lib/cli.bootstrap.sh" >&2; fi
fi

parse_arguments "$@"

# probably want to resolve configuration next because header will need that too


# Import logging.bootstrap.sh
if ! source "$SCRIPT_DIR/lib/logging.bootstrap.sh"; then
    echo "❌ CRITICAL: Unable to source lib/logging.bootstrap.sh - Aborting." >&2
    exit 1
else
    if [[ "$OWRTDS_DEBUG" -gt "0" ]]; then echo "[DEBUG] sourced lib/logging.bootstrap.sh" >&2; fi
fi

log_debug "4" "Debug function loaded and working"

# Import earlyscript.functions.sh
if ! source "$SCRIPT_DIR/lib/earlyscript.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/earlyscript.functions.sh - Aborting." >&2
    exit 1
else
    if [[ "$OWRTDS_DEBUG" -gt "0" ]]; then echo "[DEBUG] sourced lib/earlyscript.functions.sh" >&2; fi
fi

# call to create_pidfile regardless (both scripts will create PID files)
create_pidfile


# log_debug now avaialble


# Version Information
# TOD: Refactor to compare to master branch .version file and give debug "current running version greater than master (v0.2.0 > v0.1.0)" or 
#                                                                        "current running version less than master (v0.1.0 < v1.0.0)" or
#                                                                        "current running version equals master version (v0.1.0 = v0.1.0)
if [[ ! -f "$SCRIPT_DIR/.owrtds.version" ]]; then
    echo "❌ CRITICAL: .owrtds.version missing" >&2; exit 1
else
    log_debug "3" "$SCRIPT_DIR/.owrtds.version exists"
fi
OWRTDS_VERSION=$(cat "$SCRIPT_DIR/.owrtds.version")
if [[ -z "$OWRTDS_VERSION" ]]; then
     log_debug "1" "OWRTDS_VERSION IS BLANK"
else
     log_debug "3" "OWRTDS_VERSION='$OWRTDS_VERSION'"
fi

# Guard variable to prevent double cleanup
CLEANED=false


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
DO_DRYRUN=false

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

# Arrays
declare -A RAWMOD_LIST
declare -A CALDATA_LIST

# Interactive Mode Control
OWRTDS_INTERACTIVE=true
# Auto-detect non-interactive mode (e.g., piped input, cron jobs, CI/CD)
if [[ ! -t 0 ]]; then
    log_debug "1" "Non-interactive mode detected & activated"
    OWRTDS_INTERACTIVE=false
else
    log_debug "1" "Interactive mode detected & activated"
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
reset_config_variables


# ===========================================================================================


# ===========================================================================================
# 1. SOURCE LIBRARIES FIRST (Defines functions like parse_arguments, install_dependencies)
# ===========================================================================================
if ! source "$SCRIPT_DIR/lib/dependencies.sh"; then
    echo "❌ CRITICAL: Unable to source lib/dependencies.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/dependencies.sh"
fi

if ! source "$SCRIPT_DIR/lib/utils.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/utils.functions.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/utils.functions.sh"
fi

if ! source "$SCRIPT_DIR/lib/exit.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/exit.functions.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/exit.functions.sh"
fi

if ! source "$SCRIPT_DIR/lib/config.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/config.functions.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/config.functions.sh"
fi

if ! source "$SCRIPT_DIR/lib/file-io.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/file-io.functions.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/file-io.functions.sh"
fi

if ! source "$SCRIPT_DIR/lib/setup.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/setup.functions.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/setup.functions.sh"
fi

if ! source "$SCRIPT_DIR/lib/build.functions.sh"; then
    echo "❌ CRITICAL: Unable to source lib/build.functions.sh - Aborting." >&2
    exit 1
else
    log_debug "4" "Sourced lib/build.functions.sh"
fi




# ===========================================================================================
# 3. RESOLVE & SOURCE CONFIG (Uses CLI override if present, otherwise default)
# ===========================================================================================
resolve_configuration_file

# Source the determined config
if ! source "$CONFIG_FILE"; then
    echo "❌ CRITICAL: Unable to source $CONFIG_FILE - Aborting." >&2
    exit 1
else
    if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
        log_summary " >>> ✅ Config file loaded: $CONFIG_FILE" --silent
        log_debug "1" "loaded configuration file '$CONFIG_FILE'"
    fi
fi

# Generate unique repository key from OWRT_DEV_DIR for state isolation
# Placed here to ensure OWRT_DEV_DIR is populated, but before verify_configuration()
REPO_KEY=$(echo "$OWRT_DEV_DIR" | tr '/' '_' | md5sum | cut -c1-12)

# Create centralized state directory structure within owrt-dev-suite repo
mkdir -p "$SCRIPT_DIR/var/state" 2>/dev/null || true

# Define paths for locks and config tracking (moved out of OWRT_DEV_DIR)
LOCK_FILE="$SCRIPT_DIR/var/state/${REPO_KEY}.lock"
CONFIG_STATE_FILE="$SCRIPT_DIR/var/state/${REPO_KEY}.cfghome"

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
    exit_with_error "No '.config' file found. Ensure the file exists. (run 'make menuconfig' to create one, then copy it to your work directory for the device)"
else
    log_debug "1" "'.config' landed correctly in $OWRT_DEV_DIR/.config"
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
    log_debug "3" "DO_SLOW: '$DO_SLOW', NUM_PROC: '$NUM_PROC', MAKE_CMD_ADD: '$MAKE_CMD_ADD'"
else
    MAKE_CMD_ADD="${MAKE_CMD_ADD}-j1"
    log_debug "3" "DO_SLOW: '$DO_SLOW', MAKE_CMD_ADD: '$MAKE_CMD_ADD'"
fi

# Handle Verbosity
if [ "$DO_VERBOSE" = true ]; then
    MAKE_CMD_ADD="${MAKE_CMD_ADD} V=s"
    log_debug "3" "DO_XVERBOSE: '$DO_XVERBOSE', MAKE_CMD_ADD: '$MAKE_CMD_ADD'"
elif [ "$DO_XVERBOSE" = true ]; then
    MAKE_CMD_ADD="${MAKE_CMD_ADD} V=99"
    log_debug "3" "DO_XVERBOSE: '$DO_XVERBOSE', MAKE_CMD_ADD: '$MAKE_CMD_ADD'"
fi

# Handle silent make in non-interactive mode
if [[ "$OWRTDS_INTERACTIVE" == "false" ]]; then
    MAKE_CMD_ADD="${MAKE_CMD_ADD} -s"
    log_debug "3" "OWRTDS_INTERACTIVE: '$OWRTDS_INTERACTIVE', MAKE_CMD_ADD: '$MAKE_CMD_ADD'"
fi

log_debug "1" "MAKE_CMD_ADD: '$MAKE_CMD_ADD'"

# Enable trap only for owrt-build (not owrt-build-all)
if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
    log_debug "1" "script is 'owrt-build': setting INT TERM HUP traps"
    # Register the trap ONLY for interruption signals (INT, TERM, HUP)
    # Do NOT trap EXIT here; let your wrappers handle normal exits.
    # Define specific handlers for each signal to pass the name correctly
    trap 'exit_with_error "Caught by trap - user pressed CTRL+C (SIGINT). Aborting."' INT
    trap 'exit_with_error "Caught by trap - script terminated (SIGTERM). Aborting."' TERM
    trap 'exit_with_error "Caught by trap - connection hung up (SIGHUP). Aborting."' HUP
    # we skipped my idea of using a trap exit handler - neat!
elif [[ "$SCRIPT_NAME" == "owrt-build-all" ]]; then
    # owrt-build-all trap enable
    # only need to trap INT because build script does all the work and traps for child cleanup :)
    trap 'build_all_custom_trap_func' INT
else
    # shouldn't arrive here, let's at least log this
    # traps not being set is not fatal
    log_debug "1" "[lib/common.sh]: SCRIPT_NAME: '$SCRIPT_NAME'"
fi
