#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# =============================================================================
# show_help
# Description: Prints usage information and available command-line options to stdout.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 after printing help
# Usage Example:
#   show_help
# =============================================================================
show_help() {
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
    echo " -h, --help                 Show this help message"
    echo ""
}

# =============================================================================
# parse_arguments
# Description: Parses command-line flags and arguments, populating global variables.
# Parameters: $@ (command-line arguments)
# Returns/Exit Codes: 0 on success; exits with code 1 on unknown option or missing arg
# Usage Example:
#   parse_arguments "$@"
# =============================================================================
parse_arguments() {

    while [[ $# -gt 0 ]]; do
        case $1 in
            -mc|--make-clean)
                DO_CLEAN=true
                shift
                ;;
            -c|--config)
                # Check if the NEXT argument ($2) exists. 
                # We need at least 2 args total: the flag ($1) and the path ($2).
                if [[ $# -lt 2 ]]; then
                    exit_with_error "Option $1 requires a path argument." --nocleanup
                fi
                CUSTOM_CONFIG_PATH="$2"
                shift 2
                ;;
            -uf|--update-feeds)
                DO_CLEAN=true
                DO_UPDATE_FEEDS=true
                shift
                ;;
            -v|--verbose)
                DO_VERBOSE=true
                shift
                ;;
            -vv|--extra-verbose)
                DO_XVERBOSE=true
                shift
                ;;
            -s|--slow)
                DO_SLOW=true
                shift
                ;;
            -ni|--non-interactive)
                OWRTDS_INTERACTIVE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo ""
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

}

