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
# create_pidfile
# Description: Creates a script-wide PID file for locking and signals.
#              Checks for stale PIDs and prevents concurrent execution.
# =============================================================================
create_pidfile() {
    local pid_dir="$TMP_DIR"
    local pid_file="$PID_FILE"
    local current_pid=$$

    # Determine which PID file based on the current SCRIPT_NAME
    if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
        local pid_fpath="${TMP_DIR}/${OWRT_BUILD_PID_FILE}"
    elif [[ "$SCRIPT_NAME" == "owrt-build-all" ]]; then
        local pid_fpath="${TMP_DIR}/${OWRT_BUILD_ALL_PID_FILE}"
    else
        log_debug "1" "[lib/earlyscript.functions.sh:create_pidfile()]: unable to determin running script - SCRIPT_NAME: '${SCRIPT_NAME}'"
        echo "Critical: Unable to determine running script."
        exit 1
    fi
    log_debug "4" "[lib/earlyscript.functions.sh:create_pidfile()]: determined pidfile - SCRIPT_NAME: '${SCRIPT_NAME}', PID_FILE: '${pid_fpath}'"

    mkdir -p "$pid_dir" || {
        echo "ERROR: Failed to create PID directory: $pid_dir" >&2
        log_debug "1" "[lib/earlyscript.functions.sh:create_pidfile()]: mkdir failed for '${pid_dir}'"
        exit 1
    }

    # Check if PID file exists and contains an active process
    if [[ -f "${pid_fpath}" ]]; then
        local old_pid
        old_pid=$(cat "$pid_fpath")

        if kill -0 "$old_pid" 2>/dev/null; then
            echo "ERROR: '${SCRIPT_NAME}' already running (PID: ${old_pid} PID_FILE: ${pid_fpath})" >&2
            log_debug "1" "[lib/earlyscript.functions.sh:create_pidfile()]: Active process found - SCRIPT_NAME: '${SCRIPT_NAME}', old_pid: '${old_pid}'"
            exit 1
        else
            log_debug "2" "[lib/earlyscript.functions.sh:create_pidfile()]: Stale PID file cleaned - old_pid: '${old_pid}', PID_FILE: '${pid_fpath}'"
            rm -f "$pid_fpath"
        fi
    fi

    # Write current PID to file
    if echo "$current_pid" > "$pid_fpath"; then
        log_debug "1" "[lib/earlyscript.functions.sh:create_pidfile()]: PID file created - PID_FILE: '${pid_fpath}', pid: '${current_pid}'"
    else
        echo "ERROR: Failed to write PID file: $pid_fpath" >&2
        log_debug "1" "[lib/earlyscript.functions.sh:create_pidfile()]: Failed to write PID - PID_FILE: '${pid_fpath}', pid: '${current_pid}'"
        exit 1
    fi
}


# =============================================================================
# remove_pidfile
# Description: Removes the script-wide PID file. Safe to call even if file
#              doesn't exist. Typically called from EXIT functions or trap.
# =============================================================================
remove_pidfile() {
    local pid_dir="$TMP_DIR"
    local pid_file="$PID_FILE"

    # Determine which PID file based on the current SCRIPT_NAME
    if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
        local pid_fpath="${TMP_DIR}/${OWRT_BUILD_PID_FILE}"
    elif [[ "$SCRIPT_NAME" == "owrt-build-all" ]]; then
        local pid_fpath="${TMP_DIR}/${OWRT_BUILD_ALL_PID_FILE}"
    else
        log_debug "1" "[lib/earlyscript.functions.sh:create_pidfile()]: unable to determin running script - SCRIPT_NAME: '${SCRIPT_NAME}'"
        echo "Critical: Unable to determine running script."
    fi
    log_debug "4" "[lib/earlyscript.functions.sh:create_pidfile()]: determined pidfile - SCRIPT_NAME: '${SCRIPT_NAME}', PID_FILE: '${pid_fpath}'"

    if [[ -f "$pid_fpath" ]]; then
        local old_pid
        old_pid=$(cat "$pid_file")
        rm -f "$pid_fpath"

        if [[ ! -f "$pid_fpath" ]]; then
            log_debug "2" "[lib/earlyscript.functions.sh:remove_pidfile()]: PID file removed - PID_FILE: '${pid_fpath}', pid: '${old_pid}'"
        else
            log_debug "1" "[lib/earlyscript.functions.sh:remove_pidfile()]: WARNING - PID file still exists after rm - PID_FILE: '${pid_fpath}'"
        fi
    else
        log_debug "3" "[lib/earlyscript.functions.sh:remove_pidfile()]: PID file does not exist - PID_FILE: '${pid_fpath}'"
    fi
}


# =============================================================================
# create_project_dir_lock
# Description: Creates a per-repository mutex lock in the centralized state dir.
# =============================================================================
create_project_dir_lock() {
    local lock_dir="$SCRIPT_DIR/var/state"
    mkdir -p "$lock_dir" 2>/dev/null || true
    LOCK_FILE="${lock_dir}/${REPO_KEY}.lock"

    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        log_debug "1" "unable to obtain lock file - LOCK_FILE: '$LOCK_FILE'"
        echo " ❌  CRITICAL: owrt-build is already running for this repository!"
        echo "     If this is an error, remove: $LOCK_FILE"
        exit 1
    fi

    trap 'remove_project_dir_lock' EXIT || log_debug "1" "trap cleanup failed (EXIT)"
}

# =============================================================================
# remove_project_dir_lock
# Description: Safely removes the per-repository lock file/directory.
# =============================================================================
remove_project_dir_lock() {
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

    # Guard: Return to startup directory (custom error handling, not wrapped in run_command)
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

# Usage: run_command "<command>" "<type>" [optional_custom_description]
# Format: type: command (unless custom description provided)
# Examples:
#   run_command "make" "command"
#   run_command "make prepare blablabla" "command"
#   run_command "cp $from $to" "operation"
#   run_command "cp $from $to" "" "operation: 'cp $from $to'"
#   run_command "make" "command" "Building OpenWRT kernel"
run_command() {
    local cmd="$1"
    local cmd_type="${2:-command}"  # "command" or "operation" for logging
    local description="${3:-}"      # optional: override auto-description
    
    # Auto-derive description if not provided
    if [[ -z "$description" ]]; then
        description="$cmd_type: $cmd"
    fi
    
    # Dry-run gate
    if [[ "$DO_DRYRUN" == "true" ]]; then
        log_debug "4" "[run_command()]: DRY-RUN - would execute: $description"
        return 0
    fi
    
    # Non-interactive gate
    if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
        log_debug "3" "[run_command()]: Executing: $description"
        eval "$cmd"
        local status=$?
    else
        log_debug "3" "[run_command()]: Executing (silent): $description"
        eval "$cmd" > /dev/null 2>&1
        local status=$?
    fi
    
    # Log result
    if [[ $status -eq 0 ]]; then
        log_debug "4" "[run_command()]: Success - $description"
    else
        log_summary " >>> ⚠ ERROR in $description (exit code: $status)"
    fi
    
    return $status
}
