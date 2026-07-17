#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

exit_with_success() {
    local err_msg="$1"
    local no_cleanup_flag="${2:-}"

    # Disable errexit to prevent silent exits in cleanup
    set +e

    # Perform cleanup ONLY if the --nocleanup flag is NOT provided
    if [[ "$no_cleanup_flag" != "--nocleanup" ]]; then
        cleanup_build_environment
    fi

    # remove lock - only remaining is output and exit
    remove_lock

    show_header
    echo " >>>"
    echo " >>> SUMMARY REPORT:"
    echo " >>>"
    echo -n "$SUMMARY_OUT"
    echo " >>>"
    echo " >>> ✅ SUCCESS: ${err_msg}!"
    echo " >>>"
    echo ""
    exit 0
}

exit_with_error() {
    local err_msg="$1"
    local no_cleanup_flag="${2:-}"

    # Disable errexit to prevent silent exits in cleanup
    set +e

    # Perform cleanup ONLY if the --nocleanup flag is NOT provided
    # (Usually you want cleanup on error, but this allows overriding if needed)
    if [[ "$no_cleanup_flag" != "--nocleanup" ]]; then
        cleanup_build_environment
    fi

    # remove lock - only remaining is output and exit
    remove_lock

    show_header
    echo " >>>"
    echo " >>> SUMMARY REPORT:"
    echo " >>>"
    echo -n "$SUMMARY_OUT"
    echo " >>>"
    echo " >>> ❌ CRITICAL: ${err_msg}!"
    echo " >>>"
    exit 1
}

