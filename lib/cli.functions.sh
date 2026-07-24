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
# Description: Parses command-line flags and arguments, populating global variables for script configuration.
# Parameters: $@ (command-line arguments)
# Returns/Exit Codes: 0 on success; exits with code 1 on unknown option or missing argument
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
                # IGNORE if running as wrapper
                if [[ "$SCRIPT_NAME" == "owrt-build-release" ]]; then
                    # Check if the NEXT argument ($2) exists.
                    # We need at least 2 args total: the flag ($1) and the path ($2).
                    if [[ $# -lt 2 ]]; then
                        exit_with_error "Option $1 requires a path argument." --nocleanup
                    fi
                    CUSTOM_CONFIG_PATH="$2"
                else
                    log_summary " >>> ⚠  WARNING: ignoring --config/-c parameter. owrt-build-all-releases does not support this flag." --silent
                    CUSTOM_CONFIG_PATH=""
                fi
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

resolve_configuration_file() {
    # Check if user provided a custom config via CLI
    if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
        # 1. Resolve relative paths against repository root ($SCRIPT_DIR)
        if [[ "$CUSTOM_CONFIG_PATH" != /* ]]; then
            CUSTOM_CONFIG_PATH="$SCRIPT_DIR/$CUSTOM_CONFIG_PATH"
        fi

        # 2. Validate file exists
        if [[ ! -f "$CUSTOM_CONFIG_PATH" ]]; then
            echo "❌ CRITICAL: Custom config file not found: $CUSTOM_CONFIG_PATH" >&2
            exit 1
        fi

        # 3. Interactive mode: Update default config symlink
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            default_config="$SCRIPT_DIR/etc/config.sh"
            # Remove existing file/link
            rm -f "$default_config" 2>/dev/null || true
            # Create new symlink (use absolute path for reliability or relative if preferred)
            ln -s "$CUSTOM_CONFIG_PATH" "$default_config" || exit_with_error "Failed to create config symlink" --nocleanup
            log_summary " >>> ✅ Config override applied. Default config now points to $(cleanup_path "$CUSTOM_CONFIG_PATH")" --silent
        fi

        # 4. Set the final config file to source
        CONFIG_FILE="$CUSTOM_CONFIG_PATH"
    fi
}
