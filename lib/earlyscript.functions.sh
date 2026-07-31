#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

#
# ⚠ PRECEDENCE WARNING ⚠
#
# EARLY FUNCTIONS FILE - THIS FILE IS UNIQUE, PLEASE PAY ATTENTION!
#
# These functions are required early in the program to be able to startup.
#
# They are required so early that the main functions files are not yet
# loaded or available.
#
# The following helpers are especially not available:
#    - verify_configuration
#    - exit_with_success
#    - exit_with_error
#    - change_directory
#    - log_summary
#    - show_header
#
# In addition to this, none of the user config or global variables are
# verified or set.
#
# Ensure all functions are self contained, and do not rely on existing helpers.
#

# =============================================================================
# create_lock
# Description: Creates a per-repository mutex lock in the centralized state dir.
# =============================================================================
create_lock() {
    local lock_dir="$SCRIPT_DIR/var/state"
    mkdir -p "$lock_dir" 2>/dev/null || true
    LOCK_FILE="${lock_dir}/${REPO_KEY}.lock"

    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        log_debug "1" "unable to obtain lock file - LOCK_FILE: '$LOCK_FILE'"
        echo " ❌  CRITICAL: owrt-build is already running for this repository!"
        echo "     If this is an error, remove: $LOCK_FILE"
        exit 1
    fi

    trap 'remove_lock' EXIT || log_debug "1" "trap cleanup failed (EXIT)"
}

# =============================================================================
# remove_lock
# Description: Safely removes the per-repository lock file/directory.
# =============================================================================
remove_lock() {
    if [[ -n "${LOCK_FILE:-}" && -d "$LOCK_FILE" ]]; then
        log_debug "1" "removed lock - LOCK_FILE: '$LOCK_FILE'"
        rmdir "$LOCK_FILE" 2>/dev/null || true
    fi
}

owrtds_branch_detect() {
    # Ensure we go to our script location (owrt-dev-suite repo)
    if ! cd "$SCRIPT_DIR" 2>/dev/null; then
        echo "Error: Unable to change directory to '$SCRIPT_DIR'. Script location invalid." >&2
        log_debug "1" "'cd $SCRIPT_DIR failed'"
        exit 1
    fi

    # Get the git branch for display
    OWRTDS_BRANCH=$(git branch --show-current 2>/dev/null)
    # Fallback for detached HEAD or old git versions
    if [ -z "$OWRTDS_BRANCH" ]; then
        OWRTDS_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi
    log_debug "1" "OWRTDS_BRANCH: '$OWRTDS_BRANCH'"

    # Ensure we go back to the original PWD before build
    if ! cd "$STARTUP_PWD" 2>/dev/null; then
        echo "Warning: Unable to return to '$STARTUP_PWD'. Continuing in current directory." >&2
        log_debug "1" "'cd $STARTUP_DIR failed'"
        # We don't exit here as the build might still proceed, but log the issue
    fi
}

# TODO: comments explaining function in same format as others
reset_config_variables() {

    log_debug "1" "reset config vars"
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
    OWRT_FORK_REPO=""
    OWRT_VERSION=""
    OWRT_BASE_BRANCH=""
    OWRT_TARGET_BRANCH=""

    OWRT_SUPPORTED="true"
    OWRT_STABLE="false"

    OWRTDS_ENABLE_BATCH_BUILD="false"

    SUDO_ENABLE="false"

    ENABLE_SYMLINK_SHORTCUTS="false"

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

    declare -A RAWMOD_LIST
    declare -A CALDATA_LIST

}

log_debug() {
    local level="$1"
    local message="$2"

    # Ensure OWRTDS_DEBUG is treated as a number (defaults to 0 if unset)
    local debug_level="${OWRTDS_DEBUG:-0}"

    # Exit immediately if global debug is off
    if [[ "$debug_level" -eq 0 ]]; then
        return 0
    fi

    # Print only if the message level is <= global debug level
    if [[ "$level" -le "$debug_level" ]]; then
        echo "[DEBUG L${level}] ${message}" >&2
    fi
}
