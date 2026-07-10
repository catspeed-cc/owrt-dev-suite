#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


# Calculates the difference between two HH:MM:SS strings
# Usage: get_time_diff "22:31:05" "23:45:10"
get_time_diff() {
  local start_time="$1"
  local end_time="$2"

  # Convert both times to seconds since epoch (using an arbitrary fixed date)
  # We use 'today' to ensure it works even if the times cross midnight relative to now, 
  # but for simple duration, a fixed date like 2000-01-01 is safer for pure time math.
  local start_sec=$(date -d "2000-01-01 $start_time" +%s)
  local end_sec=$(date -d "2000-01-01 $end_time" +%s)

  # Calculate difference in seconds
  local diff=$((end_sec - start_sec))

  # Handle negative difference (if end time is before start time)
  if [[ $diff -lt 0 ]]; then
    diff=$((diff * -1))
  fi

  # Convert seconds ($diff) to elapsed time format: Xh Ym Zs
  # Using pure arithmetic ensures no leading zeros (e.g., 1h 4m 5s instead of 01h 04m 05s)
  hours=$((diff / 3600))
  minutes=$(( (diff % 3600) / 60 ))
  seconds=$((diff % 60))

  printf "%dh %dm %ds\n" "$hours" "$minutes" "$seconds"
}

# Helper function to resolve glob paths safely
# Usage: resolve_glob_path "array_name" "pattern"
# Actually, simpler: just a validator function
validate_path_exists() {
  local path="$1"
  local name="$2"
  if [[ ! -d "$path" ]]; then
    echo "ERROR: $name directory not found: $path" >&2
    exit 1
  fi
}

# Helper to resolve a glob pattern to a single path
# Returns the path via echo, or exits on error
resolve_single_glob() {
  local pattern="$1"
  local desc="$2"

  # Create a temporary array to expand the glob
  local matches=($pattern)

  if [[ ${#matches[@]} -eq 0 ]] || [[ ! -d "${matches[0]}" ]]; then
    echo "ERROR: No directory found for pattern: $pattern" >&2
    exit 1
  fi

  if [[ ${#matches[@]} -gt 1 ]]; then
    echo "WARNING: Multiple directories found for '$desc'. Using the first one: ${matches[0]}" >&2
  fi

  echo "${matches[0]}"
}

#########################################

# ====================
# AUTOCONFIG VARIABLES
# ====================

# Verify all user configured variables from above
verify_configuration() {

    # TODO: Fill in the rest of checks :D


    # ================
    # NOT EMPTY CHECKS
    # ================

    # Validate PATCHMOD_DEST_DIR
    if [ -z "${PATCHMOD_DEST_DIR}" ]; then
        exit_with_error "PATCHMOD_DEST_DIR is not set (check script config)"
    fi

    # Validate STARTUP_PWD exists
    if [[ -z "$STARTUP_PWD" ]]; then
        echo "Error: STARTUP_PWD is not set" >&2
        return 1
    fi




    # =========================================
    # VALUE CONSTRAINT CHECKS (ex. "$var"=true)
    # =========================================




    # =================
    # DIR EXISTS CHECKS
    # =================




    # ==================
    # FILE EXISTS CHECKS
    # ==================




}


# ==============================================================================
# Argument Parsing
# ==============================================================================

show_header() {

    # Check our variables are not empty (at least set to blank - unbound protection)
    if [[ -z "$BUILD_STOP_DATE" || -z "$BUILD_STOP_TIME" || -z "$BUILD_ELAPSED" ]]; then
        BUILD_STOP_DATE=""
        BUILD_STOP_TIME=""
        BUILD_ELAPSED=""
        local no_stop=true
    else
        local no_stop=false
    fi

    echo ""
	echo " ========================================================================================================================"
	echo " |                                   'owrt-dev-suite' - Advanced OpenWRT build script                                   |"
	echo " ========================================================================================================================"
    echo "  🚀 Build Script Started"
    echo "  📦 Branch: ${GIT_BRANCH}"
    echo "  📜 Script: $REAL_PATH"
    echo "  📅 Date: $(date)"
    echo "  📁 PWD: $STARTUP_PWD"
    echo " ========================================================================================================================"
    echo "  📅 Start Date: $BUILD_START_DATE"
    echo "  📅 Start Time: $BUILD_START_TIME"

    if [ "$no_stop" == "false" ]; then
        echo "  📅 Stop Date: $BUILD_STOP_DATE"
        echo "  📅 Stop Time: $BUILD_STOP_TIME"
        echo " ========================================================================================================================"
        echo "  📅 Elapsed: $BUILD_ELAPSED"
    fi

    echo " ========================================================================================================================"
    echo ""

}

show_help() {

    echo ""
    echo "Usage: ${SCRIPT_NAME} [--help|-h]"
    echo "Usage: ${SCRIPT_NAME} [-clean|-c] [-updatefeeds|-uf] [-verbose|-v] [-extraverbose|-vv] [-slow|-s]"
    echo ""
    echo " -clean|-c            = make clean"
    echo " -updatefeeds|-uf     = update feeds"
    echo " -verbose|-v          = verbose"
    echo " -extraverbose|-vv    = extra verbose"
    echo " -slow|-s             = slow compile (single core, default is all cores)"
    echo ""

}

parse_arguments() {

    while [[ $# -gt 0 ]]; do
        case $1 in
            -clean|-c)
                DO_CLEAN=true
                DO_UPDATE_FEEDS=true
                shift
                ;;
            -updatefeeds|-uf)
                DO_CLEAN=true
                DO_UPDATE_FEEDS=true
                shift
                ;;
            -verbose|-v)
                DO_VERBOSE=true
                shift
                ;;
            -extraverbose|-vv)
                DO_XVERBOSE=true
                shift
                ;;
            -slow|-s)
                DO_SLOW=true
                shift
                ;;
            --help|-h)
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


# ==============================================================================
# Script Termination
# ==============================================================================

exit_with_success() {

    show_header
    echo " >>>"
    echo " >>> SUMMARY REPORT:"
    echo " >>>"
    echo -n "$SUMMARY_OUT"
    echo " >>>"
    echo " >>> ✅ BUILD COMPLETED SUCCESSFULLY!"
    echo " >>>"
    echo ""
    exit 0

}

exit_with_error() {

    local err_msg="$1"
    echo " >>>"
    echo " >>> SUMMARY REPORT:"
    echo " >>>"
    echo "$SUMMARY_OUT"
    echo " >>>"
    echo " >>> ❌ CRITICAL: ${err_msg}!"
    echo " >>>"
    exit 1

}


# ==============================================================================
# File Operations
# ==============================================================================

cleanup_path() {
    local filepath="$1"

    # Validate local input
    if [[ -z "$filepath" ]]; then
        echo "Error: No filepath provided" >&2
        return 1
    fi

    # Check if filepath starts with base_path followed by a slash or is exactly base_path
    if [[ "$filepath" == "$STARTUP_PWD" ]]; then
        # If filepath is exactly the same as STARTUP_PWD, return current dir indicator or empty
        echo "."
        return 0
    elif [[ "$filepath" == "$STARTUP_PWD/"* ]]; then
        # Remove the base_path and the following slash
        echo "${filepath#$STARTUP_PWD/}"
        return 0
    else
        # If filepath does not start with STARTUP_PWD, return it unchanged
        echo "$filepath"
        return 0
    fi
}

verify_md5() {
    # Parameters
    local file_src="$1"
    local file_dest="$2"

    # Local vars
    local desc="Checking MD5"

    # Calculate and sanitize hashes
    local file_src_md5=$(md5sum "$file_src" | awk '{print $1}')
    local file_dest_md5=$(md5sum "$file_dest" | awk '{print $1}')

    if [ "$file_src_md5" == "$file_dest_md5" ]; then
        return 0
    else
        echo " >>>"
        echo " >>> ❌ FAILURE: $desc - MISMATCH!"
        echo " >>>      Source:      '$file_src' -> '$file_src_md5'"
        echo " >>>      Destination: '"$(cleanup_path "$file_dest")"' -> '$file_dest_md5'"
        echo " >>>"
        return 1
    fi
}

copy_file() {

    # Parameters
    local file_src="$1"
    local file_dest="$2"

    # Local variables
    local desc="Copying File"
    local dest_dir

    # Ensure source file exists or exit_with_error
    if [ ! -f "$file_src" ]; then
        exit_with_error "$desc failed: ${file_src} doesn't exist"
    fi

    # Fetch the file's directory
    dest_dir="$(dirname "$file_dest")"

    # Create directory if it doesn't exist (including parents)
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
    fi

    # Remove destination file if it already exists
    if [ -f "$file_dest" ]; then
        rm "$file_dest"
    fi

    # Copy file
    if ! cp "$file_src" "$file_dest"; then
        exit_with_error "$desc failed: "$(cleanup_path "$file_dest")
    fi

    # Verify md5 & output messages
    if verify_md5 "$file_src" "$file_dest"; then
	local msg=" >>> ✅ $desc "$(cleanup_path "$file_dest")" (MATCH)"
        echo "$msg"
        SUMMARY_OUT+="${msg}"$'\n'
        return 0
    else
        exit_with_error "$desc failed (MD5 mismatch)"
        return 1 # pragmatic safety: this shouldn't execute
    fi

}

copy_patches_dir() {

    # Parameters
    local dir_src="$1"
    local dir_dest="$2"

    echo " >>> Copying Patches Directory ${dir_src}"

    # Check if source directory exists
    if [ ! -d "${dir_src}" ]; then
        exit_with_error "Source directory does not exist: ${dir_src}"
    fi

    # Check if destination directory exists
    if [ ! -d "${dir_dest}" ]; then
        exit_with_error "Destination directory does not exist: ${dir_dest}"
    fi

    # Loop over each .patch file non-recursively and copy using your function
    for src_file in "${dir_src}"/*.patch; do

        # Check if glob matched any files (handles empty directory case)
        [ -e "$src_file" ] || continue

        # Extract just the filename for the destination
        filename="$(basename "$src_file")"
        dest_file="${dir_dest}/${filename}"

        # Use your existing copy_file function
        copy_file "$src_file" "$dest_file"

    done

    local msg=" >>> ✅ Patches Directory Copied "$(cleanup_path "$dir_dest")
    echo $msg
    SUMMARY_OUT+="${msg}"$'\n'

}

copy_caldata() {
    # Find the firmware build directory once
    FIRMWARE_BUILD_DIR=$(find "$DEV_DIR/build_dir" -type d -name "linux-firmware-*" | head -n 1)

    if [ -z "$FIRMWARE_BUILD_DIR" ]; then
        exit_with_error "Could not find linux-firmware build directory after prepare."
    fi

    # Loop over each line in CALDATA_LIST
    # We use a here-string <<< to feed the variable into the loop
    while IFS= read -r line; do
        # 1. Discard empty lines (handles the trailing newline in the list)
        [ -z "$line" ] && continue

        # 2. Split the line by pipe '|' into local variables
        # CALDATA_BOARDNAME (Group 1), CALDATA_SRC (Group 2), CALDATA_DEST (Group 3)
        IFS='|' read -r CALDATA_BOARDNAME CALDATA_SRC CALDATA_DEST <<< "$line"

        # Perform the copy using the new dynamic variables
        copy_file "$CALDATA_SRC" "$CALDATA_DEST" || exit_with_error "Copy Caldata"

        # Generate success message and update summary
        local msg=" >>> ✅ ${CALDATA_BOARDNAME} copied to: $(cleanup_path "$CALDATA_DEST")"
        echo "$msg"
        SUMMARY_OUT+="${msg}"$'\n'

    done <<< "$CALDATA_LIST"
}


# ==============================================================================
# Build Operations
# ==============================================================================

build_kernel_sources() {

    # Download sources (Prerequisite)
    echo " >>> Running 'make download'..."
    make download ${MAKE_CMD_ADD} || exit_with_error "Make Download"
    local msg=" >>> ✅ Sources downloaded (all)"
    echo $msg
    SUMMARY_OUT+="$msg"$'\n'

    if [ "$DO_PATCHMOD" = true ]; then

        if [ -z "${PATCHMOD_DEST_DIR}" ]; then
            exit_with_error "PATCHMOD_DEST_DIR is not set (check script config)"
        fi

        if [ "$DO_RAWMOD" != true ]; then

    	    # Copy custom patches into the target directory
            # These will be picked up automatically by the 'prepare' step
            copy_patches_dir "${PATCHMOD_SRC_DIR}" "${PATCHMOD_DEST_DIR}"

            local msg=" >>> ✅ DRIVER PATCHES copied to source tree: $PATCHMOD_SRC_DIR"
            echo $msg
            SUMMARY_OUT+="$msg"$'\n'

        else

            # Loop over each line in RAWMOD_LIST
            while IFS= read -r line; do
                # Discard empty lines
                [ -z "$line" ] && continue

                # Split the line by pipe '|' into local variables
                # RAWMOD_FILENAME (Group 1), RAWMOD_SRC (Group 2), RAWMOD_DEST (Group 3)
                IFS='|' read -r RAWMOD_ENTRYNAME RAWMOD_SRC RAWMOD_DEST <<< "$line"

                # Perform the copy
                copy_file "$RAWMOD_SRC" "$RAWMOD_DEST" || exit_with_error "Copying Driver Mod ($RAWMOD_ENTRYNAME)"

                # Single summary message for the whole RAWMOD operation
                local msg=" >>> ✅ IPQESS RAW DRIVER MOD ($RAWMOD_ENTRYNAME) copied to source tree: $(cleanup_path "$RAWMOD_SRC")"
                echo "$msg"
                SUMMARY_OUT+="$msg"$'\n'
            done <<< "$RAWMOD_LIST"

                local msg=" >>> ✅ IPQESS RAW DRIVER MOD ($RAWMOD_ENTRYNAME) copied to source tree: $(cleanup_path "$(dirname "$RAWMOD_SRC")")"
            echo $msg
            SUMMARY_OUT+="$msg"$'\n'

        fi

    fi

    # Prepare (Extract + Apply Patches)
    echo " >>> Running 'make target/linux/prepare'..."
    make target/linux/prepare ${MAKE_CMD_ADD} || exit_with_error "Make Prepare `linux`"
    local msg=" >>> ✅ Sources prepared (linux)"
    echo $msg
    SUMMARY_OUT+="${msg}"$'\n'

    # Compile
    echo " >>> Running 'make target/linux/compile'..."
    make target/linux/compile ${MAKE_CMD_ADD} || exit_with_error "Make Compile `linux`"
    local msg=" >>> ✅ Sources compiled (linux) with custom patches applied"
    echo $msg
    SUMMARY_OUT+="${msg}"$'\n'

}

do_final_build() {

    MAKE_CMD="make ${MAKE_CMD_ADD}"
    echo " >>> Starting compilation: ${MAKE_CMD}"
    $MAKE_CMD

    if [ $? -eq 0 ]; then

        # clobber the image out old files
        rm -rf "${IMGDIR_DEST}/"* || exit_with_error "Clobber image-out dir"

        # copy the new files
        cp -r "$IMGDIR_SRC/"* "$IMGDIR_DEST/" || exit_with_error "Copy images to image-out"

        local msg=" >>> ✅ IMAGES COPIED TO WORK DIR: $IMGDIR_DEST"
        echo $msg
        SUMMARY_OUT+="${msg}"$'\n'

        #exit_with_success

    else

        exit_with_error "BUILD FAILED"

    fi

}


# ==============================================================================
# Cleanup Operations
# ==============================================================================

cleanup_build_environment() {

    cd "$STARTUP_PWD"

    echo " >>> Cleaning up temporary build modifications..."

    # 1. Remove temporary patches from target directory
    #    This ensures no test patches linger if you forget to run 'prepare' again
    if [ -n "${PATCHMOD_DEST_DIR}" ] && [ -d "${PATCHMOD_DEST_DIR}" ]; then
        # Only remove patches that match your source directory (optional safety)
        # Or simply remove all .patch files if this dir is exclusively for temp patches
        for patch_file in "${PATCHMOD_DEST_DIR}"/*.patch; do
            [ -e "$patch_file" ] || continue
            local filename
            filename=$(basename "$patch_file")

            # Check if this patch exists in your source dir. 
            # If NOT, it might be an orphan or upstream patch you don't want to touch.
            # If YES, remove it to force a fresh copy next time.
            if [ -f "${PATCHMOD_SRC_DIR}/${filename}" ]; then
                rm -f "$patch_file"
                local msg=" >>> 🗑️  Removed temp patch: I"$(cleanup_path "$patch_file")
                echo $msg
                SUMMARY_OUT+="${msg}"$'\n'
            fi
        done
    fi

    # 2. Restore modified source files (e.g., drivers) to original Git state
    #    This is crucial if you manually edited files in build_dir or target/
    #    We only reset files in the 'target' directory to avoid touching other repos
    echo " >>> Restoring modified files in target/ to original state..."

    # Check if there are any modified files in target/
    if git diff --quiet -- 'target/'; then
        local msg=" >>> ✅ No modified files found in target/"
        echo $msg
        SUMMARY_OUT+="${msg}"$'\n'
    else
        # List modified files for logging
        echo "    🔄 Resetting modified files:"
        git diff --name-only -- 'target/' | while read -r file; do
            echo "        - ${file}"
        done

        # Hard reset only the target/ directory to HEAD
        # This discards all local changes in target/ and restores original upstream files
        git checkout HEAD -- 'target/' || exit_with_error "Failed to restore target files"
    fi

    local msg=" >>> ✅ Cleanup complete. Environment is pristine."
    echo $msg
    SUMMARY_OUT+="${msg}"$'\n'
}

