#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

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

# Function to remove lock file
remove_lock() {
    if [[ -d "$LOCK_FILE" ]]; then
        rmdir "$LOCK_FILE" 2>/dev/null
    fi
}

create_lock() {
    # Attempt to create lock directory atomically
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        echo " ❌  CRITICAL: owrt-build-release is already running!"
        echo "     If this is an error, remove: $LOCK_FILE"
        exit 1
    fi

    # trap to cleanup lock
    trap 'remove_lock' EXIT
}

owrtds_branch_detect() {
    # Ensure we go to our script location (owrt-dev-suite repo)
    if ! cd "$SCRIPT_DIR" 2>/dev/null; then
        echo "Error: Unable to change directory to '$SCRIPT_DIR'. Script location invalid." >&2
        exit 1
    fi

    # Get the git branch for display
    OWRTDS_BRANCH=$(git branch --show-current 2>/dev/null)
    # Fallback for detached HEAD or old git versions
    if [ -z "$OWRTDS_BRANCH" ]; then
        OWRTDS_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi

    # Ensure we go back to the original PWD before build
    if ! cd "$STARTUP_PWD" 2>/dev/null; then
        echo "Warning: Unable to return to '$STARTUP_PWD'. Continuing in current directory." >&2
        # We don't exit here as the build might still proceed, but log the issue
    fi
}
