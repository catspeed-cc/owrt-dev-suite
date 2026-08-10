#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


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

    # determine caller for header
    if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
        local msg_str="Building release"
    elif [[ "$SCRIPT_NAME" == "owrt-build-all" ]]; then
        local msg_str="Building all releases"
    else
        local msg_str="unknown"
    fi

    # determine device string
    if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
        local device_str="- ${OWRT_MFR} ${OWRT_MODEL} / ${OWRT_SOC_CLASS} "
    elif [[ "$SCRIPT_NAME" == "owrt-build-all" ]]; then
        local device_str=""
    else
        local device_str="- unknown "
    fi

    if [[ "$OWRTDS_INTERACTIVE" == "false" ]]; then
        # Non-Interactive Mode: Compact, log-friendly header
        echo ""
        echo "=== OWRTDS ${OWRTDS_VERSION} - ${msg_str} ${device_str}($(date '+%Y-%m-%d %H:%M')) ==="

        if [[ "$build_finished" == "true" ]]; then
            echo "=== Elapsed: ${BUILD_ELAPSED} (${BUILD_ELAPSED_SECONDS}s) ==="
        fi

        echo ""

        # Skip colors, boxes, or pause prompts
        return 0
    fi

    echo ""
    echo " ========================================================================================================================"
    echo " |                                   'owrt-dev-suite' - Advanced OpenWRT build script                                   |"
    echo " ========================================================================================================================"
    echo "  🚀 ${msg_str}"
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

# =============================================================================
# show_help
# Description: Prints usage information and available command-line options to stdout.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 after printing help
# Usage Example:
#   show_help
# =============================================================================
show_help() {
    if [[ "$SCRIPT_NAME" == "owrt-build" ]]; then
        echo ""
        echo "Usage: ${SCRIPT_NAME} [OPTIONS]"
        echo ""
        echo "Options:"
        echo " -c, --config <path>        Override config file (supports relative/absolute paths)"
        echo " -mc, --make-clean          Run 'make clean' and prepare host tools/toolchain"
        echo " -uf, --update-feeds        Update and install feeds"
        echo " -v, --verbose              Enable verbose output"
        echo " -vv, --extra-verbose       Enable extra verbose output (V=99)"
        echo " -s, --slow                 Single-core compilation (default is multi-core)"
        echo " -ni, --non-interactive     Disable interactive prompts (for cron/CI)"
        echo " -d, --dry-run              Disable any file copy or make commands"
        echo " --debug [0-4]            Set debug verbosity"
        echo " -h, --help                 Show this help message"
        echo ""
    elif [[ "$SCRIPT_NAME" == "owrt-build-all" ]]; then
        echo ""
        echo "Usage: ${SCRIPT_NAME} [OPTIONS]"
        echo ""
        echo "Options:"
        echo " -v, --verbose              Enable verbose output"
        echo " -vv, --extra-verbose       Enable extra verbose output (V=99)"
        echo " -s, --slow                 Single-core compilation (default is multi-core)"
        echo " -ni, --non-interactive     Disable interactive prompts (for cron/CI)"
        echo " -d, --dry-run              Disable any file copy or make commands"
        echo " --debug [0-4]            Set debug verbosity"
        echo " -h, --help                 Show this help message"
        echo ""
    else
        echo "❌ Critical error. Unable to determine which script is running. Aborting." >&2
        exit 1
    fi
}
