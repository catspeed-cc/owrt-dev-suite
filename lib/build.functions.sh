#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

build_kernel_sources() {

    # TODO: UPDATE SELECTION LOGIC (patchmod/rawmod)

    # Download sources (Prerequisite)
    echo " >>> Running 'make download'..."
    make download ${MAKE_CMD_ADD} || exit_with_error "Make Download"
    log_summary " >>> ✅ Sources downloaded (all)"

    if [ "$DO_DRIVERMOD_CPY" = true ]; then

        if [ "$DRIVERMOD_MODE" == "patchmod" ]; then

            if [ -z "${PATCHMOD_DEST_DIR}" ]; then
                exit_with_error "PATCHMOD_DEST_DIR is not set (check script config)"
            fi

            # Copy custom patches into the target directory
            # These will be picked up automatically by the 'prepare' step
            copy_patches_dir "$WORK_PATCHMODS_DIR" "$OWRT_DEV_DIR/$PATCHMOD_DEST_DIR"

            log_summary " >>> ✅ DRIVER PATCHES copied to source tree: $OWRT_DEV_DIR/$PATCHMOD_DEST_DIR"

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
                log_summary " >>> ✅ IPQESS RAW DRIVER MOD ($RAWMOD_ENTRYNAME) copied to source tree: $(cleanup_path "$(dirname "$RAWMOD_SRC")")"
            done <<< "$RAWMOD_LIST"

        fi

    fi

    # Prepare (Extract + Apply Patches)
    echo " >>> Running 'make target/linux/prepare'..."
    make target/linux/prepare ${MAKE_CMD_ADD} || exit_with_error "Make Prepare 'linux'"
    log_summary " >>> ✅ Sources prepared (linux)"

    # Compile
    echo " >>> Running 'make target/linux/compile'..."
    make target/linux/compile ${MAKE_CMD_ADD} || exit_with_error "Make Compile 'linux'"
    log_summary " >>> ✅ Sources compiled (linux) with custom patches applied"

}

cleanup_build_environment() {
    # NOTICE: DO NOT 'echo "$msg"' inside the cleanup function!
    #         ONLY output SUMMARY_OUT
    #
    # NOTICE: WE ARE CALLED BY EXIT_WITH_ERROR AND EXIT_WITH_SUCCESS
    #         THEREFORE WE CANNOT CALL IT INSIDE THIS FUNCTION
    #

    # Guard: exit immediately if already cleaned
    [[ "${CLEANED}" == "true" ]] && return 0

    # SET CLEANED=TRUE IMMEDIATELY TO PREVENT DUPLICATE CALLS
    CLEANED=true
    CLEAN_SUCCESS=true

    # Disable errexit inside cleanup to prevent silent exits (incase exit function does not)
    set +e

    # Return to the original directory where the script was launched
    # Silently ignore failure to avoid masking the original error
    if [[ -n "$OWRT_DEV_DIR" && -d "$OWRT_DEV_DIR" ]]; then
        cd "$OWRT_DEV_DIR" || true
    fi

    local msg=" >>> 🧹 Cleaning up temporary build modifications..."
    SUMMARY_OUT+="${msg}"${NL}

    # 1. Remove temporary patches from target directory
    if [ -n "${PATCHMOD_DEST_DIR}" ] && [ -d "${PATCHMOD_DEST_DIR}" ]; then
        for patch_file in "${PATCHMOD_DEST_DIR}"/*.patch; do
            [ -e "$patch_file" ] || continue
            local filename
            filename=$(basename "$patch_file")

            if [ -f "$WORK_PATCHMODS_DIR/${filename}" ]; then
                rm -f "$patch_file"
                local msg=" >>> 🗑️  Removed temp patch: I"$(cleanup_path "$patch_file")
                echo "$msg"
                SUMMARY_OUT+="${msg}"${NL}
            fi
        done
    fi

    # 2. Restore modified source files (e.g., drivers) to original Git state
    local msg=" >>> ♻ Restoring modified files in target/ to original state..."
    SUMMARY_OUT+="${msg}"${NL}

    if git diff --quiet -- 'target/'; then
        local msg=" >>> ✅ No patches, caldata, or modified files found in target/"
        SUMMARY_OUT+="${msg}"${NL}
    else
        echo "    🔄 Resetting modified files:"
        git diff --name-only -- 'target/' | while read -r file; do
            echo "        - ${file}"
        done

        git checkout HEAD -- 'target/' || {
            local msg=" >>> ⚠️  WARNING: Failed to restore target files (non-fatal during cleanup)"
            echo "$msg" >&2
            SUMMARY_OUT+="${msg}"${NL}
            CLEAN_SUCCESS=false
        }

    fi

    if [ "$CLEAN_SUCCESS" == true ]; then
        local msg=" >>> ✅ Cleanup complete. Environment is pristine."
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # Return to the original directory where the script was launched
    # Silently ignore failure to avoid masking the original error
    if [[ -n "$STARTUP_PWD" && -d "$STARTUP_PWD" ]]; then
        cd "$STARTUP_PWD" || true
    fi

    # Return silently to allow the original exit code to pass through
    return 0

}
