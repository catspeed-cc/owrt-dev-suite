#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


# Logs a message to both stderr AND SUMMARY_OUT
# Passing in --silent causes it to only log to SUMMARY_OUT
# For stderr only please simply use echo
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

# Safe Change Directory
# Usage:
#   change_directory "/path/to/dir"
#   change_directory "/path/to/dir" "Custom error message if cd fails"
# Exits with error if directory does not exist or cd fails
change_directory() {
  local target_dir="$1"
  local custom_msg="${2:-}"

  if [[ -z "$target_dir" ]]; then
    exit_with_error "❌ CRITICAL: change_directory called with no argument"
  fi

  if [[ ! -d "$target_dir" ]]; then
    # Use custom message if provided, otherwise default
    if [[ -n "$custom_msg" ]]; then
      exit_with_error "$custom_msg"
    else
      exit_with_error "Directory does not exist: $target_dir"
    fi
  fi

  cd "$target_dir" || {
    if [[ -n "$custom_msg" ]]; then
      exit_with_error "$custom_msg"
    else
      exit_with_error "❌ CRITICAL: Failed to cd into $target_dir (permissions?)"
    fi
  }
}

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

    # =======================
    # VERIFY ONLY THESE EARLY
    # =======================

    # Validate OWRT_MFR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_MFR" ]]; then
        exit_with_error "OWRT_MFR is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_MODEL is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_MODEL" ]]; then
        exit_with_error "OWRT_MODEL is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_SOC is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_SOC" ]]; then
        exit_with_error "OWRT_SOC is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_SOC_CLASS is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_SOC_CLASS" ]]; then
        exit_with_error "OWRT_SOC_CLASS is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_OS_TARGET is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_OS_TARGET" ]]; then
        exit_with_error "OWRT_OS_TARGET is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi


    # =====================================
    # INITIALIZE VARIABLES ON CONFIG VERIFY
    # =====================================

    # PURELY DERIVED FROM VALIDATED USER INPUT - NO USER OVERRIDE
    # DO NOT VALIDATE, ASSUME CORRECTNESS
    OWRT_MFR_LOWER="${OWRT_MFR,,}"
    OWRT_MODEL_LOWER="${OWRT_MODEL,,}"
    OWRT_SOC_LOWER="${OWRT_SOC,,}"
    OWRT_SOC_CLASS_LOWER="${OWRT_SOC_CLASS,,}"
    OWRT_OS_TARGET_LOWER="${OWRT_OS_TARGET,,}"


    # ===========================
    # VALIDATE BOOLS (USED BELOW)
    # ===========================

    # Validate DEVICE_SUPPORTED flag
    if [[ "${DEVICE_SUPPORTED}" != "true" && "${DEVICE_SUPPORTED}" != "false" ]]; then
        exit_with_error "DEVICE_SUPPORTED is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate SUDO_ENABLE flag
    if [[ "${SUDO_ENABLE}" != "true" && "${SUDO_ENABLE}" != "false" ]]; then
        exit_with_error "SUDO_ENABLE is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate DO_DTS_CPY flag
    if [[ "${DO_DTS_CPY}" != "true" && "${DO_DTS_CPY}" != "false" ]]; then
        exit_with_error "DO_DTS_CPY is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate DO_IMGDIR_CPY flag
    if [[ "${DO_IMGDIR_CPY}" != "true" && "${DO_IMGDIR_CPY}" != "false" ]]; then
        exit_with_error "DO_IMGDIR_CPY is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate DO_WEBSERVER_CPY flag
    if [[ "${DO_WEBSERVER_CPY}" != "true" && "${DO_WEBSERVER_CPY}" != "false" ]]; then
        exit_with_error "DO_WEBSERVER_CPY is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate DO_DRIVERMOD_CPY flag
    if [[ "${DO_DRIVERMOD_CPY}" != "true" && "${DO_DRIVERMOD_CPY}" != "false" ]]; then
        exit_with_error "DO_DRIVERMOD_CPY is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate DO_CALDATA_CPY flag
    if [[ "${DO_CALDATA_CPY}" != "true" && "${DO_CALDATA_CPY}" != "false" ]]; then
        exit_with_error "DO_CALDATA_CPY is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate ENABLE_SYMLINK_SHORTCUTS flag
    if [[ "${ENABLE_SYMLINK_SHORTCUTS}" != "true" && "${ENABLE_SYMLINK_SHORTCUTS}" != "false" ]]; then
        exit_with_error "ENABLE_SYMLINK_SHORTCUTS is not set to true/false in 'etc/config.sh' - Aborting." --nocleanup
    fi


    # ================
    # IS EMPTY CHECKS
    # ================

    # Validate OWRT_REMOTE_ALIAS is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_REMOTE_ALIAS" ]]; then
        exit_with_error "OWRT_REMOTE_ALIAS is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_FORK_REPO is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_FORK_REPO" ]]; then
        exit_with_error "OWRT_FORK_REPO is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_VERSION is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_VERSION" ]]; then
        exit_with_error "OWRT_VERSION is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_BASE_BRANCH is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_BASE_BRANCH" ]]; then
        exit_with_error "OWRT_BASE_BRANCH is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate WORK_DIR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$WORK_DIR" ]]; then
        exit_with_error "WORK_DIR is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate PROJECT_DIR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$PROJECT_DIR" ]]; then
        exit_with_error "PROJECT_DIR is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # Validate OWRT_DEV_DIR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_DEV_DIR" ]]; then
        exit_with_error "OWRT_DEV_DIR is not set in 'etc/config.sh' - Aborting." --nocleanup
    fi

    # CONDITIONAL VALIDATION BASED ON BOOLS

    # Validate IMGDIR_SRC is not empty (REQUIRED, CRITICAL)
    if [[ "${DO_IMGDIR_CPY}" == "true" ]]; then
        if [[ -z "$IMGDIR_SRC" ]]; then
            exit_with_error "IMGDIR_SRC is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # Validate DTS_FNAME is not empty if DO_DTS_CPY = true (just validate not empty)
    if [[ "${DO_DTS_CPY}" == "true" ]]; then
        if [[ -z "$DTS_FNAME" ]]; then
            exit_with_error "DTS_FNAME is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # Validate WEBSERVER_USER is not empty (sane defaults already set, just validate not empty)
    if [[ "${DO_WEBSERVER_CPY}" == "true" ]]; then
        if [[ -z "$WEBSERVER_USER" ]]; then
            exit_with_error "WEBSERVER_USER is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # Validate WEBSERVER_SHARED_GROUP is not empty (sane defaults already set, just validate not empty)
    if [[ "$DO_WEBSERVER_CPY" == "true" ]]; then
        if [[ -z "$WEBSERVER_SHARED_GROUP" ]]; then
            exit_with_error "WEBSERVER_SHARED_GROUP must be set in 'etc/config.sh' when DO_WEBSERVER_CPY=true" --nocleanup
        fi
    fi

    # Validate WEBSERVER_SHARED_DIR is not empty (sane defaults already set, just validate not empty)
    if [[ "${DO_WEBSERVER_CPY}" == "true" ]]; then
        if [[ -z "$WEBSERVER_SHARED_DIR" ]]; then
            exit_with_error "WEBSERVER_SHARED_DIR is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # Validate WEBSERVER_ROOT is not empty (sane defaults already set, just validate not empty)
    if [[ "${DO_WEBSERVER_CPY}" == "true" ]]; then
        if [[ -z "$WEBSERVER_ROOT" ]]; then
            exit_with_error "WEBSERVER_ROOT is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # Validate WEBSERVER_RESTART_CMD is not empty (sane defaults already set, just validate not empty)
    if [[ "${DO_WEBSERVER_CPY}" == "true" ]]; then
        if [[ -z "$WEBSERVER_RESTART_CMD" ]]; then
            exit_with_error "WEBSERVER_RESTART_CMD is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # EXTRA VALIDATION REQUIRED

    # Validate DRIVERMOD_MODE is not empty (sane defaults already set, validate either patchmod or rawmod, and not empty)
    if [[ "${DO_DRIVERMOD_CPY}" == "true" ]]; then
        if [[ -z "$DRIVERMOD_MODE" || ("$DRIVERMOD_MODE" != "patchmod" && "$DRIVERMOD_MODE" != "rawmod") ]]; then
            exit_with_error "DRIVERMOD_MODE must be 'patchmod' or 'rawmod' in 'etc/config.sh'" --nocleanup
        fi
    fi

    # Validate RAWMOD_LIST is not empty IF enabled (sane defaults already set, validate either patchmod or rawmod, and not empty)
    if [[ "${DO_DRIVERMOD_CPY}" == "true" ]]; then
        if [[ -z "$RAWMOD_LIST" || ("$DRIVERMOD_MODE" != "patchmod" && "$DRIVERMOD_MODE" != "rawmod") ]]; then
            exit_with_error "RAWMOD_LIST is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi

    # Validate CALDATA_LIST is not empty IF enabled
    if [[ "${DO_CALDATA_CPY}" == "true" ]]; then
        if [[ -z "$CALDATA_LIST" ]]; then
            exit_with_error "CALDATA_LIST is not set in 'etc/config.sh' - Aborting." --nocleanup
        fi
    fi


    # ===============================
    # AUTO DERIVED DIRECTORY DEFAULTS
    # ===============================

    # SOURCE DIRECTORIES

    # Validate WORK_DTS_DIR is not empty
    if [[ -z "$WORK_DTS_DIR" ]]; then
        WORK_DTS_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/dts"
        log_summary " >>> ⚠ WARNING: Using default auto-derived WORK_DTS_DIR ('$WORK_DTS_DIR')"
    fi

    # Validate WORK_CALDATA_DIR is not empty
    if [[ -z "$WORK_CALDATA_DIR" ]]; then
        WORK_CALDATA_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/caldata"
        log_summary " >>> ⚠ WARNING: Using default auto-derived WORK_CALDATA_DIR ('$WORK_CALDATA_DIR')"
    fi

    # Validate WORK_PATCHMODS_DIR is not empty
    if [[ -z "$WORK_PATCHMODS_DIR" ]]; then
        WORK_PATCHMODS_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/patchmods"
        log_summary " >>> ⚠ WARNING: Using default auto-derived WORK_PATCHMODS_DIR ('$WORK_PATCHMODS_DIR')"
    fi

    # Validate WORK_RAWMODS_DIR is not empty
    if [[ -z "$WORK_RAWMODS_DIR" ]]; then
        WORK_RAWMODS_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/rawmods"
        log_summary " >>> ⚠ WARNING: Using default auto-derived WORK_RAWMODS_DIR ('$WORK_RAWMODS_DIR')"
    fi

    # Validate WORK_IMAGEOUT_DIR is not empty
    if [[ -z "$WORK_IMAGEOUT_DIR" ]]; then
        WORK_IMAGEOUT_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/image-out"
        log_summary " >>> ⚠ WARNING: Using default auto-derived WORK_IMAGEOUT_DIR ('$WORK_IMAGEOUT_DIR')"
    fi

    # DESTINATION DIRECTORIES

    # Validate DTS_DEST_DIR is not empty
    if [[ -z "$DTS_DEST_DIR" ]]; then
        DTS_DEST_DIR="$OWRT_DEV_DIR/target/$OWRT_OS_TARGET_LOWER/$OWRT_SOC_CLASS_LOWER/files-6.12/arch/arm/boot/dts/qcom"
        log_summary " >>> ⚠ WARNING: Using default auto-derived DTS_DEST_DIR ('$DTS_DEST_DIR')"
    fi

    # Validate PATCHMOD_DEST_DIR is not empty
    if [[ -z "$PATCHMOD_DEST_DIR" ]]; then
        PATCHMOD_DEST_DIR="$OWRT_DEV_DIR/target/$OWRT_OS_TARGET_LOWER/$OWRT_SOC_CLASS_LOWER/patches-6.12"
        log_summary " >>> ⚠ WARNING: Using default auto-derived PATCHMOD_DEST_DIR ('$PATCHMOD_DEST_DIR')"
    fi


    # ==============================
    # AUTO DERIVED VARIABLE DEFAULTS
    # ==============================

    # Validate OWRT_TARGET_BRANCH is not empty
    if [[ -z "$OWRT_TARGET_BRANCH" ]]; then
        OWRT_TARGET_BRANCH="${OWRT_MFR_LOWER}_${OWRT_MODEL_LOWER}-${OWRT_BASE_BRANCH}"
        log_summary " >>> ⚠ WARNING: Using default auto-derived OWRT_TARGET_BRANCH ('$OWRT_TARGET_BRANCH')"
    fi




    # ========================================
    # VALUE CONSTRAINT CHECKS (ex. $var -ge 6)
    # ========================================




    # ==============================================
    # SETUP PHASE (Check & Create Directories)
    # ==============================================

    local SETUP_MODE=false

    # Create the required structure if not already exists
    if [[ ! -d "$WORK_DIR" ]]; then
        create_workdir
        SETUP_MODE=true
    fi

    # Create the required structure if not already exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        create_projectsdir
        SETUP_MODE=true
    fi

    # Clone openwrt fork
    if [[ ! -d "$OWRT_DEV_DIR" ]]; then
        clone_openwrt
        SETUP_MODE=true
    fi

    # Set up webserver shared directory
    if [[ ! -d "$WEBSERVER_SHARED_DIR" ]]; then
        create_webserver_shareddir
        SETUP_MODE=true
    fi

    # If we created anything, stop and let the user populate files
    if [[ "$SETUP_MODE" == true ]]; then
        log_summary " >>>"
        log_summary " >>> ✅  Initial setup completed successfully."
        log_summary " >>>"
        log_summary " >>> 📂  Please ensure your source files exist in: $WORK_DIR"
        log_summary " >>>     (e.g., DTS files, patches, caldata, driver mods)"
        log_summary " >>>"
        log_summary " >>> Once files are in place, run the script again to start compilation."
        log_summary " >>>"
        exit_with_success "Initial setup completed successfully." --nocleanup
    fi

    # create the workdir for the current port if it does not exist yet
    create_workdir

    # create the shared dir for the current port if it does not exist yet
    create_port_shareddir

    # checkout the correct branch!
    change_directory "$OWRT_DEV_DIR"
    git checkout "$OWRT_TARGET_BRANCH" || exit_with_error "Unable to checkout branch: $OWRT_TARGET_BRANCH" --nocleanup




    # =================
    # DIR EXISTS CHECKS
    # =================

    # Verify the critical directories actually exist:
    local critical_dirs=("$WORK_DIR" "$PROJECT_DIR" "$OWRT_DEV_DIR")
    for dir in "${critical_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            exit_with_error "Required directory does not exist: $dir" --nocleanup
        fi
    done




    # ==================
    # FILE EXISTS CHECKS
    # ==================




}

# Create work dir
create_workdir() {
    if [ ! -d "$WORK_DIR" ]; then
        echo " >>> Warning: Work directory '$WORK_DIR' does not exist."
        local response="Y"
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            read -r -p "Do you want to create it? [Y/n] " response
            response=${response:-Y}
        else
            echo " >>> [NON-INTERACTIVE] Auto-creating work directory structure..."
        fi

        case "$response" in
            [nN][oO]|[nN])
                exit_with_error "Please configure your paths in 'etc/config.sh' or accept the defaults" --nocleanup
                ;;
            *)
                echo " >>> Creating ${WORK_DIR} structure..."
                mkdir -p "$WORK_DTS_DIR/oem"
                mkdir -p "$WORK_CALDATA_DIR"
                mkdir -p "$WORK_PATCHMODS_DIR"
                mkdir -p "$WORK_RAWMODS_DIR"
                mkdir -p "$WORK_IMAGEOUT_DIR"
                log_summary " >>> ✅ $WORK_DIR directory structure created"
                ;;
        esac
    fi
}

# Create projects dir
create_projectsdir() {
    if [ ! -d "$PROJECT_DIR" ]; then
        echo " >>> Warning: Project directory '$PROJECT_DIR' does not exist."
        local response="Y"
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            read -r -p "Do you want to create it? [Y/n] " response
            response=${response:-Y}
        else
            echo " >>> [NON-INTERACTIVE] Auto-creating projects directory..."
        fi

        case "$response" in
            [nN][oO]|[nN])
                exit_with_error "Please configure your paths in 'etc/config.sh' or accept the defaults" --nocleanup
                ;;
            *)
                echo " >>> Creating $PROJECT_DIR..."
                mkdir -p "$PROJECT_DIR"
                log_summary " >>> ✅ $PROJECT_DIR directory structure created"
                ;;
        esac
    fi
}

clone_openwrt() {
    # TODO: if OWRT_DEV_DIR does not exist
    if [ ! -d "$OWRT_DEV_DIR" ]; then

        # 1) Test if the git repository exists
        if ! git ls-remote "$OWRT_FORK_REPO" >/dev/null 2>&1; then
            exit_with_error "Git repository $OWRT_FORK_REPO does not exist please check OWRT_FORK_REPO variable in \`etc/config.sh\` - Aborting." --nocleanup
        fi

        # 2) Prompt the user (or auto-proceed if non-interactive)
        local reply="Y"
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            echo -n " >>> Cloning openwrt fork repository... Continue? [Y/n] "
            read -r reply
            reply=${reply:-Y}
        else
            echo " >>> [NON-INTERACTIVE] Auto-proceeding with clone..."
        fi

        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            exit_with_error "Please either configure the openwrt fork repository at the path in 'etc/config.sh' or continue with the clone." --nocleanup
        fi

        # cd to PROJECT_DIR directory
        change_directory "$PROJECT_DIR"

        # stderr message only (cloning openwrt into OWRT_DEV_DIR)
        echo " >>> Cloning openwrt into $OWRT_DEV_DIR" >&2

        # clone OWRT_FORK_REPO into OWRT_DEV_DIR ; cd OWRT_DEV_DIR ; checkout OWRT_BASE_BRANCH ;
        git clone "$OWRT_FORK_REPO" "$OWRT_DEV_DIR" >&2
        change_directory "$OWRT_DEV_DIR"

        git checkout "$OWRT_BASE_BRANCH" >&2

        # check if OWRT_TARGET_BRANCH exists if not create it from OWRT_BASE_BRANCH and checkout OWRT_TARGET_BRANCH
        if ! git rev-parse --verify "$OWRT_TARGET_BRANCH" >/dev/null 2>&1; then
            git checkout -b "$OWRT_TARGET_BRANCH" "$OWRT_BASE_BRANCH" >&2
        else
            git checkout "$OWRT_TARGET_BRANCH" >&2
        fi

        # cd back to STARTUP_PWD
        change_directory "$STARTUP_PWD"

        # display final SUMMARY_OUT & stderr (successful openwrt fork clone into OWRT_DEV_DIR)
        log_summary " >>> ✅ Cloned openwrt fork into ${OWRT_DEV_DIR}"
    fi
}

create_port_shareddir() {
    local port_shareddir="$WEBSERVER_SHARED_DIR/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/$OWRT_BASE_BRANCH"

    if [ ! -d "${port_shareddir}" ]; then
        echo " >>> Warning: Webserver shareddir directory for port '$port_shareddir' does not exist."

        local response="Y"
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            read -r -p "Do you want to create it? [Y/n] " response
            response=${response:-Y}
        else
            echo " >>> [NON-INTERACTIVE] Auto-creating port shareddir..."
        fi

        case "$response" in
            [nN][oO]|[nN])
                exit_with_error "Please create the directory '$port_shareddir' yourself or allow it to be created for you." --nocleanup
                ;;
            *)
                echo " >>> Creating ${port_shareddir} directory..."
                    mkdir -p "$port_shareddir"
                    chown root:"$WEBSERVER_SHARED_GROUP" "$port_shareddir"
                    chmod 2775 "$port_shareddir"
                    log_summary " >>> ✅ ${port_shareddir} directory created"
                    ;;
            esac
        else
            # Non-interactive mode: Auto-create to prevent hanging
            echo " >>> Non-interactive mode detected. Auto-creating ${port_shareddir} directory..."
            mkdir -p "$port_shareddir"
            chown root:"$WEBSERVER_SHARED_GROUP" "$port_shareddir"
            chmod 2775 "$port_shareddir"
            log_summary " >>> ✅ ${port_shareddir} directory created (auto)"
        fi
    fi
}

create_webserver_shareddir() {
    # ALL CAPS vars are global, validated, and defaulted already.
    local sudo_enable="$SUDO_ENABLE"
    local current_user="$USER"
    local webserver_user="$WEBSERVER_USER"
    local shared_group="$WEBSERVER_SHARED_GROUP"
    local webserver_shared_dir="$WEBSERVER_SHARED_DIR"
    local webserver_root_dir="$WEBSERVER_ROOT"
    local webserver_restart_cmd="$WEBSERVER_RESTART_CMD"
    local symlink_name="openwrt-builds"

    # TODO: deprecate symlink_name hardcode, determine directory name from webserver_shared_dir (WEBSERVER_SHARED_DIR) and use same for symlink name

    # Early exit if DO_WEBSERVER_CPY is not enabled
    if [[ "$DO_WEBSERVER_CPY" != "true" ]]; then
        log_summary " >>> ⏭️  Webserver copy disabled (DO_WEBSERVER_CPY=false), skipping setup"
        return 0
    fi

    echo " >>> 🚀  Setting up webserver shared directory..."
    echo " >>>     Shared group: $shared_group"
    echo " >>>     Shared webserver directory: $webserver_shared_dir"
    echo " >>>     Webserver root: $webserver_root_dir"

    # GLOBALS ARE VALIDATED ALREADY

    # ========== Step 0: Check sudo ==========
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        needs_sudo=true
    fi

    # Handle sudo requirement logic
    if [[ "$needs_sudo" == true ]]; then
        if [[ "$sudo_enable" != "true" ]]; then
            log_summary " >>> ⚠️  Sudo required to setup shared web directory"
            echo ""

            local response="Y"
            if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
                read -p "Continue with automated setup? (Y/n): " -r response
                response=${response:-Y}
            else
                echo " >>> [NON-INTERACTIVE] Auto-proceeding with webserver setup..."
            fi

            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit_with_error "Please either allow automated setup (requires: SUDO_ENABLE=true) or manually set up the shared web directory" --nocleanup
            fi
        fi

        # Verify sudo access is available
        if ! sudo -n true 2>/dev/null; then
            log_summary " >>> ⚠️   Passwordless sudo not available, you may be prompted for your password"
        fi
    else
        log_summary " >>> ✅  Running as root, sudo not required"
    fi

    # ========== Step 1: Group Management ==========
    echo " >>> 📋  Step 1: Group Management"

    if ! getent group "$shared_group" > /dev/null 2>&1; then
        echo " >>> 📦  Creating shared group: $shared_group"
        sudo groupadd "$shared_group" || exit_with_error "Failed to create group $shared_group" --nocleanup
        log_summary " >>> ✅  Created $shared_group group"
    else
        log_summary " >>> ✅  $shared_group group already exists"
    fi

    # Add current user to group
    if ! groups "$current_user" | grep -q "$shared_group"; then
        echo " >>> 👤  Adding $current_user to $shared_group"
        set +e
        sudo usermod -aG "$shared_group" "$current_user" || exit_with_error "Failed to add $current_user to $shared_group" --nocleanup
        set -e
        log_summary " >>> ✅  Added $current_user to $shared_group"
    else
        log_summary " >>> ✅  $current_user already member of $shared_group"
    fi

    if ! groups "$webserver_user" 2>/dev/null | grep -q "$shared_group"; then
        echo " >>> 🌐  Adding $webserver_user to $shared_group"
        set +e
        sudo usermod -aG "$shared_group" "$webserver_user" || exit_with_error "Failed to add $webserver_user to $shared_group" --nocleanup
        set -e
        log_summary " >>> ✅  Added $webserver_user to $shared_group"
    else
        log_summary " >>> ✅  $webserver_user already member of $shared_group"
    fi

    # ========== Step 2: Directory Creation & Permissions ==========
    echo " >>> 📁  Step 2: Directory Creation & Permissions"

    if [[ ! -d "$webserver_shared_dir" ]]; then
        set +e
        sudo mkdir -p "$webserver_shared_dir" || exit_with_error "Failed to create directory $webserver_shared_dir" --nocleanup
        set -e
        log_summary " >>> ✅  Created directory at $webserver_shared_dir"
    else
        log_summary " >>> ✅  $webserver_shared_dir already exists"
    fi

    echo " >>> 🔐  Setting ownership to root:$shared_group"
    set +e
    sudo chown -R root:"$shared_group" "$webserver_shared_dir" || exit_with_error "Failed to set ownership" --nocleanup
    set -e
    log_summary " >>> ✅  Ownership of $webserver_shared_dir set to 'root:$shared_group'"

    echo " >>> 🔐  Setting permissions to 2775 (SetGID + rwxrwxr-x)"
    set +e
    sudo chmod -R 2775 "$webserver_shared_dir" || exit_with_error "Failed to set permissions" --nocleanup
    set -e
    log_summary " >>> ✅  Permissions of $webserver_shared_dir set to 775 (SetGID + rwxrwxr-x)"

    # ========== Step 3: Permission Verification ==========
    echo " >>> ✨  Step 3: Permission Verification"

    local perms_output
    perms_output=$(ls -ld "$webserver_shared_dir" 2>/dev/null)

    if [[ -z "$perms_output" ]]; then
        exit_with_error "Failed to verify directory" --nocleanup
    fi

    echo " >>>     Directory: $perms_output"

    if echo "$perms_output" | grep -q "drwxrwsr-x"; then
        log_summary " >>> ✅  SetGID bit correctly applied"
    else
        log_summary " >>> ⚠️  SetGID bit may not be set correctly"
    fi

    # ========== Step 4: Symlink Creation ==========
    echo " >>> 🔗  Step 4: Symlink Creation"

    if [[ -n "$webserver_shared_dir" ]] && [[ -d "$webserver_root_dir" ]]; then
        if change_directory "$webserver_root_dir"; then
            local symlink_path="$webserver_root_dir/$symlink_name"

            if [[ -L "$symlink_path" ]]; then
                log_summary " >>> ✅  Symlink already exists"
            elif [[ -e "$symlink_path" ]]; then
                exit_with_error "Path exists but is not a symlink: $symlink_path" --nocleanup
            else
                echo " >>> 🔗  Creating symlink: $symlink_name → $webserver_shared_dir"
                set +e
                sudo ln -s "$webserver_shared_dir" "$symlink_path" || exit_with_error "Failed to create symlink" --nocleanup
                set -e
                log_summary " >>> ✅  Symlink created"
            fi
        fi
    else
        log_summary " >>> ⏭️  Skipping symlink (WEBDIR_ROOT not set or missing)"
    fi

    # ========== Step 5: Webserver Restart ==========

    echo " >>> 🔄  Step 5: Webserver Restart"

    # Only attempt restart if the user provided a command
    if [[ -n "$webserver_restart_cmd" ]]; then
        echo " >>> 🔄  Executing: $webserver_restart_cmd"
        set +e
        # Execute the user-defined restart command
        if eval "$webserver_restart_cmd" 2>/dev/null; then
            log_summary " >>> ✅  Webserver restarted successfully"
        else
            log_summary " >>> ⚠️  Failed to restart webserver (Command: $webserver_restart_cmd)"
        fi
        set -e
    else
        log_summary " >>> ℹ️  No webserver restart command defined (WEBSERVER_RESTART_CMD is empty). Skipping."
    fi

    # ========== Summary ==========
    log_summary " >>>"
    log_summary " >>> 🎉  Webserver shared directory setup complete!"
    log_summary " >>>"

}


# ==============================================================================
# Dependency Installation
# ==============================================================================

install_dependencies() {
    local distro_pkg_manager=""
    local packages_to_install=()
    local manual_install_cmd=""

    # Detect package manager and map requested names to distribution-specific equivalents
    if command -v apt-get &>/dev/null; then
        distro_pkg_manager="apt"
        # Debian/Ubuntu names
        # Debian/Ubuntu (Bookworm/Jammy+)
        packages_to_install=($DEBIAN_PACKAGES)
        manual_install_cmd="sudo apt-get update && sudo apt-get install -y ${packages_to_install[*]}"

    elif command -v dnf &>/dev/null; then
        distro_pkg_manager="dnf"
        # Fedora/RHEL names (glibc-devel, zlib-devel)
        packages_to_install=($FEDORA_PACKAGES)
        manual_install_cmd="sudo dnf install -y ${packages_to_install[*]}"

    elif command -v yum &>/dev/null; then
        distro_pkg_manager="yum"
        # Older RHEL/CentOS names
        packages_to_install=($FEDORA_PACKAGES)
        manual_install_cmd="sudo yum install -y ${packages_to_install[*]}"

    elif command -v pacman &>/dev/null; then
        distro_pkg_manager="pacman"
        # Arch names (python, not python3; glibc/zlib are base but safe to list)
        packages_to_install=($ARCH_PACKAGES)
        manual_install_cmd="sudo pacman -S --needed ${packages_to_install[*]}"
    else
        echo "ERROR: Unsupported package manager. Please install dependencies manually." >&2
        echo "Required packages: binutils bzip2 diff find flex gawk gcc getopt grep libc-dev libz-dev make perl python3 rsync subversion unzip which"
        return 1
    fi

    # Retrieve currently installed packages for the detected manager
    local installed_pkgs=()
    case "$distro_pkg_manager" in
        apt) installed_pkgs=($(dpkg -l 2>/dev/null | awk '/^ii/ {print $2}' | sed 's/:.*//')) ;;
        dnf|yum) installed_pkgs=($(rpm -qa --qf '%{NAME}\n' 2>/dev/null)) ;;
        pacman) installed_pkgs=($(pacman -Qq 2>/dev/null)) ;;
    esac

    # Filter out already installed packages
    local filtered_pkgs=()
    for pkg in "${packages_to_install[@]}"; do
        local is_installed=false
        for inst in "${installed_pkgs[@]}"; do
            # Exact match for the package itself
            if [[ "$inst" == "$pkg" ]]; then
                is_installed=true
                break
            fi
            # Exact match for common dev variants (prevents 'git' matching 'git-all')
            # We explicitly check for '-dev' or '-devel' suffixes on the INSTALLED name
            if [[ "$inst" == "${pkg}-dev" ]] || [[ "$inst" == "${pkg}-devel" ]]; then
                is_installed=true
                break
            fi
        done

        # If NOT installed, add to filtered list
        if [[ "$is_installed" == false ]]; then
            filtered_pkgs+=("$pkg")
        fi
    done

    # If nothing to install, exit successfully
    if [ ${#filtered_pkgs[@]} -eq 0 ]; then
        echo "All required dependencies are already installed."
        return 0
    fi

    # Prompt user (or auto-proceed if non-interactive)
    local choice="Y"
    if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
        echo "The following packages will be installed: ${filtered_pkgs[*]}"
        read -r -p "Continue? (Y/n) " choice
        choice=${choice:-Y}
    else
        echo " >>> [NON-INTERACTIVE] Auto-proceeding with dependency installation..."
    fi

    if [[ "$choice" =~ ^[Nn]$ ]]; then
        echo ""
        echo "Automatic installation skipped."
        echo "Please run the following command manually to install dependencies:"
        echo "---------------------------------------------------------"
        echo "$manual_install_cmd"
        echo "---------------------------------------------------------"
        exit 0
    fi

    # Install dependencies using sudo
    echo "Installing dependencies..."
    case "$distro_pkg_manager" in
        apt) sudo apt-get update && sudo apt-get install -y "${filtered_pkgs[@]}" ;;
        dnf) sudo dnf install -y "${filtered_pkgs[@]}" ;;
        yum) sudo yum install -y "${filtered_pkgs[@]}" ;;
        pacman) sudo pacman -S --needed "${filtered_pkgs[@]}" ;;
    esac
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
    echo "  📦 Version: ${OWRTDS_VERSION}"
    echo "  🌿 Branch: ${OWRTDS_BRANCH}"
    echo " ========================================================================================================================"
    echo "  📜 Script: $REAL_PATH"
    echo "  📁 PWD: $STARTUP_PWD"
    echo " ========================================================================================================================"
    echo "  💻 SOC: $OWRT_SOC_CLASS"
    echo "  🗜  MFR: $OWRT_MFR"
    echo "  💃 MODEL: $OWRT_MODEL"
    echo "  🌿 Base Branch: ${OWRT_BASE_BRANCH}"
    echo "  🌿 Port Branch: ${OWRT_TARGET_BRANCH}"
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
    local CUSTOM_CONFIG_PATH=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -mc|--make-clean)
                DO_CLEAN=true
                shift
                ;;
            -c|--config)
                if [[ $# -lt 1 ]]; then
                    exit_with_error "Option $1 requires a path argument." --nocleanup
                fi
                CUSTOM_CONFIG_PATH="$2"
                shift 2
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
            -ni|--non-interactive)
                OWRTDS_INTERACTIVE=false
                shift
                ;;
            -C|--config)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --config/-C requires a path argument." >&2
                    exit 1
                fi
                OWRTDS_CUSTOM_CONFIG="$2"
                shift 2
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

    # Resolve and apply config override if provided
    if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
        local resolved_config
        if [[ "$CUSTOM_CONFIG_PATH" == /* ]]; then
            resolved_config="$CUSTOM_CONFIG_PATH"
        else
            resolved_config="$(pwd)/$CUSTOM_CONFIG_PATH"
        fi

        if [[ ! -f "$resolved_config" ]]; then
            exit_with_error "Config file not found: $resolved_config" --nocleanup
        fi

        # Interactive mode: automatically update default config symlink
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            local default_config="$SCRIPT_DIR/etc/config.sh"
            rm -f "$default_config" 2>/dev/null || true
            ln -s "$resolved_config" "$default_config" || exit_with_error "Failed to create config symlink at $default_config" --nocleanup
            log_summary " >>> ✅ Config override applied. Default config now points to $(cleanup_path "$resolved_config")"
        fi

        export CUSTOM_CONFIG_PATH="$resolved_config"
    fi
}


# ==============================================================================
# Script Termination
# ==============================================================================

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
        SUMMARY_OUT+="${msg}"${NL}
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
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

}

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

copy_to_imgdir() {

    [[ -z "$WORK_IMAGEOUT_DIR" ]] && exit_with_error "WORK_IMAGEOUT_DIR is not set"

    local dest_dir="$WORK_IMAGEOUT_DIR/$OWRT_VERSION"

    # clobber the image out old files
    rm -rf "${dest_dir:?}/"* || exit_with_error "Clobber image-out dir"

    # missing piece :)
    mkdir -p "$dest_dir"

    # copy the new files (use OWRT_BASE_BRANCH as subdir)
    cp -r "$IMGDIR_SRC/"* "$dest_dir/" || exit_with_error "Copy images to image-out"

    local msg=" >>> ✅ IMAGES COPIED TO WORK DIR: $(cleanup_path "$dest")"
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

}

copy_to_webserver() {
    local owrt_version="$OWRT_VERSION"
    local owrt_mfr="$OWRT_MFR_LOWER"
    local owrt_model="$OWRT_MODEL_LOWER" # Note: Ensure this variable is actually lowercased if intended
    local owrt_base_branch="$OWRT_BASE_BRANCH"
    local webserver_shared_dir="$WEBSERVER_SHARED_DIR"
    local imgdir_src="$IMGDIR_SRC"

    [[ -z "$WEBSERVER_SHARED_DIR" ]] && exit_with_error "WEBSERVER_SHARED_DIR is not set"

    local dest="$webserver_shared_dir/$owrt_mfr/$owrt_model/$owrt_version"

    if [ "$DO_WEBSERVER_CPY" == "true" ]; then

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

    fi
}


# ==============================================================================
# Build Operations
# ==============================================================================

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


# ==============================================================================
# Cleanup Operations
# ==============================================================================

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
