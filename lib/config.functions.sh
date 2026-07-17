#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>


# =============================================================================
# verify_configuration
# Description: Validates required configuration variables, applies defaults, checks boolean flags, and initializes directory structures if needed.
# Parameters: None
# Returns/Exit Codes: Exits with code 1 on validation failure; returns 0 on success
# Usage Example:
#   verify_configuration
# =============================================================================
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

    # `DEVICE_SUPPORTED=true` should disable `DO_DTS_CPY`, `DO_DRIVERMOD_CPY`, & `DO_CALDATA_CPY`
    if [[ -z "$DEVICE_SUPPORTED" == "true" ]]; then
        DO_DTS_CPY=false
        DO_DRIVERMOD_CPY=false
        DO_CALDATA_CPY=false
        log_summary " >>> ⚠ WARNING: Disabled DO_DTS_CPY, DO_DRIVERMOD_CPY, & DO_CALDATA_CPY because device is supported!"
    fi




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
    git checkout -q "$OWRT_TARGET_BRANCH" || exit_with_error "Unable to checkout branch: $OWRT_TARGET_BRANCH" --nocleanup




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
