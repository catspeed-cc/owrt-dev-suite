#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# =============================================================================
# log_summary
# Description: Appends a message to the global SUMMARY_OUT buffer and optionally echoes it to stderr.
# Parameters: $1 (message string), $2 (silent flag, defaults to false)
# Returns/Exit Codes: None (returns 0 implicitly)
# Usage Example:
#   log_summary "Build completed successfully" "--silent"
# =============================================================================
log_summary() {
  local message="$1"
  local silent="${2:-false}"

  # Always append to the summary buffer
  SUMMARY_OUT+="${message}${NL}"

  # Only echo to stderr if NOT silent
  if [[ "$silent" != "--silent" && "$silent" != "true" ]]; then
    echo "$message" >&2
  fi
}

# =============================================================================
# show_header
# Description: Prints a formatted build script header containing version, branch, paths, SOC info, and timing data.
# Parameters: None
# Returns/Exit Codes: None (returns 0 implicitly)
# Usage Example:
#   show_header
# =============================================================================
show_header() {

    # Check our variables are not empty (at least set to blank - unbound protection)
    if [[ -z "$BUILD_STOP_DATE" || -z "$BUILD_STOP_TIME" || -z "$BUILD_ELAPSED" ]]; then
        BUILD_STOP_DATE=""
        BUILD_STOP_TIME=""
        BUILD_ELAPSED=""
        BUILD_ELAPSED_SECONDS=""
        local build_finished=false
    else
        local build_finished=true
    fi

    if [[ "$OWRTDS_INTERACTIVE" == "false" ]]; then
        # Non-Interactive Mode: Compact, log-friendly header
        echo ""
        echo "=== OWRTDS ${OWRTDS_VERSION} Build: ${OWRT_MFR} ${OWRT_MODEL} ($(date '+%Y-%m-%d %H:%M')) ==="

        if [[ "$build_finished" == "false" ]]; then
            echo "Mfr: ${OWRT_MFR} | Model: ${OWRT_MODEL} | SOC Class: ${OWRT_SOC_CLASS}"
        else
            echo "Mfr: ${OWRT_MFR} | Model: ${OWRT_MODEL} | SOC Class: ${OWRT_SOC_CLASS} | Elapsed: ${BUILD_ELAPSED} (${BUILD_ELAPSED_SECONDS}s)"
        fi

        echo ""
        # Skip colors, boxes, or pause prompts
        return 0
    fi

    echo ""
    echo " ========================================================================================================================"
    echo " |                                   'owrt-dev-suite' - Advanced OpenWRT build script                                   |"
    echo " ========================================================================================================================"
    echo "  🚀 Build Script Started"
    echo "  📦 Version: ${OWRTDS_VERSION}"
    echo "  🌿 Branch: ${OWRTDS_BRANCH}"
    echo " ========================================================================================================================"
    echo "  📜 Script: $REAL_PATH"
    echo "  📁 PWD: $STARTUP_PWD"
    echo "  ⚙️ Config: $(basename "${CONFIG_FILE:-Not Set}")"
    echo " ========================================================================================================================"
    echo "  💻 SOC: $OWRT_SOC_CLASS"
    echo "  🗜  MFR: $OWRT_MFR"
    echo "  💃 MODEL: $OWRT_MODEL"
    echo "  🌿 Base Branch: ${OWRT_BASE_BRANCH}"
    echo "  🌿 Port Branch: ${OWRT_TARGET_BRANCH}"
    echo " ========================================================================================================================"
    echo "  📅 Start Date: $BUILD_START_DATE"
    echo "  📅 Start Time: $BUILD_START_TIME"

    if [[ "$build_finished" == "true" ]]; then
        echo "  📅 Stop Date: $BUILD_STOP_DATE"
        echo "  📅 Stop Time: $BUILD_STOP_TIME"
        echo " ========================================================================================================================"
        echo "  📅 Elapsed: $BUILD_ELAPSED (${BUILD_ELAPSED_SECONDS}s)"
    fi

    echo " ========================================================================================================================"
    echo ""

}
