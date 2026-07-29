#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# =============================================================================
# cleanup_path
# Description: Sanitizes a file path by removing the base startup directory prefix, returning a relative path.
# Parameters: $1 (absolute or relative filepath)
# Returns/Exit Codes: Echoes cleaned path; returns 0 on success, 1 if no filepath provided
# Usage Example:
#   cleanup_path "/home/user/project/src/file.c"
# =============================================================================
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

# =============================================================================
# verify_md5
# Description: Compares MD5 checksums of two files and reports success or mismatch.
# Parameters: $1 (source file path), $2 (destination file path)
# Returns/Exit Codes: Returns 0 if hashes match; returns 1 on mismatch
# Usage Example:
#   verify_md5 "/path/to/source" "/path/to/dest"
# =============================================================================
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

# =============================================================================
# copy_file
# Description: Copies a file from source to destination, creating directories as needed and verifying the copy via MD5.
# Parameters: $1 (source file path), $2 (destination file path)
# Returns/Exit Codes: Returns 0 on success; exits with error on failure
# Usage Example:
#   copy_file "/path/to/source" "/path/to/dest"
# =============================================================================
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
        SUMMARY_OUT+="${msg}"${NL}
        return 0
    else
        exit_with_error "$desc failed (MD5 mismatch)"
        return 1 # pragmatic safety: this shouldn't execute
    fi

}

# =============================================================================
# copy_patches_dir
# Description: Iterates through .patch files in a source directory and copies them to a destination directory.
# Parameters: $1 (source directory path), $2 (destination directory path)
# Returns/Exit Codes: Returns 0 on success; exits with error on failure
# Usage Example:
#   copy_patches_dir "/path/to/patches" "/path/to/target"
# =============================================================================
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
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

}

# =============================================================================
# copy_caldata
# Description: Finds the firmware build directory and copies calibration data files based on CALDATA_LIST configuration.
# Parameters: None
# Returns/Exit Codes: Exits with error on failure; returns 0 on success
# Usage Example:
#   copy_caldata
# =============================================================================
copy_caldata() {
    # Find the firmware build directory once
    FIRMWARE_BUILD_DIR=$(find "$OWRT_DEV_DIR/build_dir" -type d -name "linux-firmware-*" | head -n 1)

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

        # 3. Construct the full paths (Build Dir + Relative Path from Config)
        CALDATA_FINAL_DEST="$FIRMWARE_BUILD_DIR/$CALDATA_DEST"

        # 4. Extract the directory path by removing the filename
        #    $(dirname ".../hw1.0/board-2.bin") returns ".../hw1.0"
        mkdir -p "$(dirname "$CALDATA_FINAL_DEST")" || exit_with_error "Failed to create caldata directory structure"

        # 5. Now perform the copy safely
        copy_file "$CALDATA_SRC" "$CALDATA_FINAL_DEST" || exit_with_error "Copy Caldata"

        # 6. Generate success message and update summary
        local msg=" >>> ✅ ${CALDATA_BOARDNAME} caldata copied to: $(cleanup_path "$CALDATA_DEST")"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}

    done <<< "$CALDATA_LIST"
}

# =============================================================================
# copy_to_imgdir
# Description: Copies compiled images to the designated image output directory, clobbering previous contents.
# Parameters: None
# Returns/Exit Codes: Exits with error on failure; returns 0 on success
# Usage Example:
#   copy_to_imgdir
# =============================================================================
copy_to_imgdir() {

    [[ -z "$WORK_IMAGEOUT_DIR" ]] && exit_with_error "WORK_IMAGEOUT_DIR is not set"
    [[ -d "$WORK_IMAGEOUT_DIR" ]] || exit_with_error "WORK_IMAGEOUT_DIR directory does not exist: '$WORK_IMAGEOUT_DIR'"

    local dest_dir="$WORK_IMAGEOUT_DIR"

    # clobber the image out old files
    rm -rf "${dest_dir:?}/"* || exit_with_error "Clobber image-out dir"

    # missing piece :)
    mkdir -p "$dest_dir"

    # copy the new files (use OWRT_BASE_BRANCH as subdir)
    cp -r "$IMGDIR_SRC/"* "$dest_dir/" || exit_with_error "Copy images to image-out"

    local msg=" >>> ✅ IMAGES COPIED TO WORK DIR: $(cleanup_path "$dest_dir")"
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

}

# =============================================================================
# copy_to_webserver
# Description: Copies compiled images to the webserver shared directory using SetGID permissions for group access.
# Parameters: None
# Returns/Exit Codes: Exits with error on failure; returns 0 on success
# Usage Example:
#   copy_to_webserver
# =============================================================================
copy_to_webserver() {
    local owrt_version="$OWRT_VERSION"
    local owrt_mfr="$OWRT_MFR_LOWER"
    local owrt_model="$OWRT_MODEL_LOWER" # Note: Ensure this variable is actually lowercased if intended
    local owrt_base_branch="$OWRT_BASE_BRANCH"
    local webserver_shared_dir="$WEBSERVER_SHARED_DIR"
    local imgdir_src="$IMGDIR_SRC"

    if [ "$DO_WEBSERVER_CPY" == "true" ]; then

        [[ -z "$WEBSERVER_SHARED_DIR" ]] && exit_with_error "WEBSERVER_SHARED_DIR is not set"
        [[ -d "$WEBSERVER_SHARED_DIR" ]] || exit_with_error "WEBSERVER_SHARED_DIR directory does not exist: '$WEBSERVER_SHARED_DIR'"

        local dadd=""
        if [[ "$OWRT_STABLE" == "false" ]]; then
            dadd="-dev"
            log_debug "4" "[copy_to_webserver()]: unstable build - OWRT_STABLE: '$OWRT_STABLE'"
        else
            log_debug "4" "[copy_to_webserver()]: stable build - OWRT_STABLE: '$OWRT_STABLE'"
        fi

        local dest="$webserver_shared_dir/$owrt_mfr/$owrt_model/$owrt_version${dadd}"

        if [[ -d "$dest" ]]; then
            log_debug "4" "[copy_to_webserver()]: local var dest directory exists: '$dest'"
        else
            log_debug "1" "[copy_to_webserver()]: creating local var dest directory: '$dest'"
            mkdir -p "$dest"
        fi

        echo " >>> Copying images to webserver..."

        # Use sg to ensure we have write access to the SetGID directory
        # regardless of whether the user has run 'newgrp' in this session.
        sg "$WEBSERVER_SHARED_GROUP" -c "
            mkdir -p \"$dest\" &&
            rm -rf \"$dest/\"* &&
            cp -r \"$imgdir_src/\"* \"$dest/\" &&
            chmod -R g+rw \"$dest\"
        " || exit_with_error "Failed to copy images to webserver"

        log_summary " >>> ✅ Images copied to webserver: $(cleanup_path "$dest")"

        # hook to generate metadata - no summary out or log debug requred (handled within function)
        generate_metadata

    fi
}

# =============================================================================
# sync_config_to_etc_dir
# Description: Synchronizes the model-specific .config from the etc/ directory
#              to the OpenWrt build root ($OWRT_DEV_DIR). If successful, it records
#              the source path in .owrtds.cfghome for future reference.
# Parameters: None (uses global environment variables for paths)
# Returns/Exit Codes: Exits with error on copy failure; returns 0 on success or skip
# Usage Example:
#   sync_config_to_etc_dir
# =============================================================================
function sync_config_to_dev_dir() {
    local owrt_config_src="${SCRIPT_DIR}/etc/${OWRT_VERSION}/owrt/${OWRT_MFR_LOWER}_${OWRT_MODEL_LOWER}.config"

    if [[ -f "$owrt_config_src" ]]; then
        if cp "$owrt_config_src" "$OWRT_DEV_DIR/.config"; then
            printf '%s\n' "$owrt_config_src" > "$CONFIG_STATE_FILE"
            set +e
            if ! make -s defconfig > /dev/null 2>&1; then
                exit_with_error "make defconfig failed. Check your .config file." --nocleanup
            fi
            set -e
            # we log the .config sync elsewhere :)
        else
            exit_with_error "Failed to copy .config to $OWRT_DEV_DIR/.config" --nocleanup
        fi
    else
        # remove cfghome and .config file (there is no config, this must be old from previous run)
        rm -f "$OWRT_DEV_DIR/.config"
        rm -f "$OWRT_DEV_DIR/.owrtds.cfghome"
        log_summary " >>> ⏭️  No custom .config found at '$owrt_config_src'. Skipping sync." --silent
    fi
}

# =============================================================================
# sync_config_from_etc_dir
# Description: Reads the target path from $OWRT_DEV_DIR/.owrtds.cfghome and
#              copies $OWRT_DEV_DIR/.config back to that location.
# Parameters: None (uses global environment variables for paths)
# Returns/Exit Codes: Exits with error on copy failure; returns 0 on success or skip
# Usage Example:
#   sync_config_from_etc_dir
# =============================================================================
function sync_config_from_dev_dir() {
    local cfg_home_file="$CONFIG_STATE_FILE"
    local config_src="$OWRT_DEV_DIR/.config"

    # Guard: no longer skip, we try and copy .config for user based on CONFIG_FILE (cli flag)
    if [[ ! -f "$cfg_home_file" ]]; then
        log_summary " >>> ⏭️  No tracked .config source found. Skipping sync." --silent
        # Must be first run, custom config was not found thus not tracked
        # Let's check OWRT_DEV_DIR/.config exists, and copy that to auto-derived filename based on CONFIG_FILE
        if [[ -f "$OWRT_DEV_DIR/.config" ]]; then
            # We found a .config to copy. Now where to copy it?
            # Replace ".build" in CONFIG_FILE with ".config"
            local config_dest="${SCRIPT_DIR}/etc/${OWRT_VERSION}/owrt/${CONFIG_FILE%.build}.config"

            # Ensure the target directory exists (in case it's the first run)
            mkdir -p "$(dirname "$config_dest")"

            if cp "$OWRT_DEV_DIR/.config" "$config_dest"; then
                log_summary " >>> ✅ Initial .config saved to: $config_dest"
                # Track it immediately so next run uses this path
                printf '%s\n' "$config_dest" > "$cfg_home_file"
            else
                exit_with_error "Failed to copy initial .config to $config_dest" --nocleanup
            fi
        else
            # There is no custom config in the etc/*/ dir, AND there is no .config in the OWRT_DEV_DIR
            exit_with_error "No '.config' exists. Please run 'make menuconfig' from $OWRT_DEV_DIR to create one."
        fi
        return 0
    fi

    local owrt_config_dest
    owrt_config_dest=$(cat "$cfg_home_file")

    # Guard: skip if path is empty
    if [[ -z "$owrt_config_dest" ]]; then
        log_summary " >>> ⏭️  Tracked .config path is empty. Skipping sync." --silent
        return 0
    fi

    # Ensure destination directory exists
    local dest_dir
    dest_dir=$(dirname "$owrt_config_dest")
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" || exit_with_error "Failed to create .config destination dir" --nocleanup
    fi

    # Guard: skip if build didn't produce a .config
    if [[ ! -f "$config_src" ]]; then
        log_summary " >>> ⚠️  $config_src does not exist. Skipping sync." --silent
        return 0
    fi

    # Copy the config back to owrt-dev-suite repo dir (or wherever it came from, as logged in the file)
    if [[ "$OWRTDS_INTERACTIVE" == "false" ]]; then
        echo " >>> Synchronizing .config back to work directory..."
    fi

    if cp -f "$config_src" "$owrt_config_dest"; then
        log_summary " >>> ✅ .config synchronized to $(cleanup_path "$owrt_config_dest")" --silent
    else
        exit_with_error "Failed to copy .config to $owrt_config_dest" --nocleanup
    fi
}

generate_metadata() {
    local owrt_fork_repo="$OWRT_FORK_REPO"
    local owrt_version="$OWRT_VERSION"
    local owrt_soc="$OWRT_SOC_LOWER"
    local owrt_mfr="$OWRT_MFR_LOWER"
    local owrt_model="$OWRT_MODEL_LOWER"
    local owrt_base_branch="$OWRT_BASE_BRANCH"
    local owrt_target_branch="${OWRT_TARGET_BRANCH}"
    local build_date="$BUILD_START_DATE"
    local webserver_shared_dir="$WEBSERVER_SHARED_DIR"

    [[ -z "$WEBSERVER_SHARED_DIR" ]] && exit_with_error "WEBSERVER_SHARED_DIR is not set"
    [[ -d "$WEBSERVER_SHARED_DIR" ]] || exit_with_error "WEBSERVER_SHARED_DIR directory does not exist: '$WEBSERVER_SHARED_DIR'"

    local dadd=""
    local dadd_alt=""
    if [[ "$OWRT_STABLE" == "false" ]]; then
        local dadd="-dev"
        local dadd_alt="dev"
        log_debug "4" "[generate_metadata()]: unstable build - OWRT_STABLE: '$OWRT_STABLE'"
    else
        log_debug "4" "[generate_metadata()]: stable build - OWRT_STABLE: '$OWRT_STABLE'"
    fi

    local info_file="$webserver_shared_dir/$owrt_mfr/$owrt_model/$owrt_version${dadd}/BUILD_NOTICE.md"
    local device_name="$owrt_mfr / $owrt_model (${owrt_soc})"

    if [[ -d "$(dirname "$info_file")" ]]; then
        log_debug "4" "[generate_metadata()]: local var info_file directory exists: '$info_file'"
    else
        exit_with_error "[generate_metadata()]: local var info_file directory does not exist: '$info_file'"
    fi

    # Header
    cat > "${info_file}" <<EOF
    # OpenWrt Build Information

    - **Device**: ${device_name}
    - **Build Date**: ${build_date}
    - **OpenWrt Version**: ${owrt_version}
    - **OpenWrt Repository**: ${owrt_fork_repo}
    - **OpenWrt Base Branch**: ${owrt_base_branch}
    - **OpenWrt Target/Port Branch**: ${owrt_target_branch}
EOF

    # Logic for Status Section
    if [ "$OWRT_SUPPORTED" = true ]; then
        cat >> "${info_file}" <<EOF
        - **Status**: ✅ **Officially Supported**
        - **Description**: This image is built from the mainline OpenWrt repository.
        - **Support**: Issues can be reported to the official OpenWrt forums or bug tracker.
        - **Repository**: https://git.openwrt.org/openwrt/openwrt.git
EOF
    elif [ "$OWRT_STABLE" = true ]; then
        cat >> "${info_file}" <<EOF
        - **Status**: ⚠️ **Community Port (Stable)**
        - **Description**: This port is functionally complete and considered stable by the maintainer, but is **not** part of the official OpenWrt release.
        - **Support**: Do **not** report issues to the official OpenWrt project. Contact the maintainer via the repository below.
        - **Maintainer Repository**: ${OWRT_FORK_REPO}
        - **Note**: Suitable for daily use, but updates depend on the maintainer.
EOF
    else
        cat >> "${info_file}" <<EOF
        - **Status**: 🛑 **Experimental / Work-in-Progress (dev-build)**
        - **Description**: This build is actively under development. Features may be broken, unstable, or incomplete.
        - **Support**: Do **not** report issues to the official OpenWrt project. Only for developers and testers.
        - **Maintainer Repository**: ${OWRT_FORK_REPO}
        - **Warning**: Use at your own risk. Not suitable for production environments.
EOF
    fi

    if [[ -f "$info_file" ]]; then
        log_debug "1" "[generate_metadata()]: created metadata file: '$info_file'"
    else
        exit_with_error "[generate_metadata()]: generated metadata file does not exist: '$info_file'"
    fi

    local dest="${webserver_shared_dir}/${owrt_mfr}/${owrt_model}_${owrt_version}_${dadd_alt}_BUILD_NOTICE.md"

    if [[ "$ENABLE_SYMLINK_SHORTCUTS" == "true" ]]; then

        # Use sg to ensure we have write access to the SetGID directory
        # regardless of whether the user has run 'newgrp' in this session.
        local link-created="true"
        sg "$WEBSERVER_SHARED_GROUP" -c "
            rm -rf \"$dest/\"* &&
            ln -s "$info_file" "$dest" &&
            chmod -R g+rw \"$dest\"
        " || link-created="false"

        if [[ "$link-created" == "true" ]]; then
            log_debug "1" "[generate_metadata()]: created link to metadata"
        else
            log_debug "1" "[generate_metadata()]: failed to create link to metadata file: from '$info_file' to '$dest'"
        fi

    else
        log_debug "1" "[generate_metadata()]: skipping create metadata link: '$dest'"
    fi

}
