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
        exit_with_error "❌ CRITICAL: OWRT_MFR is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_MODEL is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_MODEL" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_MODEL is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_SOC is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_SOC" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_SOC is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_SOC_CLASS is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_SOC_CLASS" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_SOC_CLASS is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_OS_TARGET is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_OS_TARGET" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_OS_TARGET is not set in 'etc/config.sh' - Aborting."
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
        exit_with_error "❌ CRITICAL: DEVICE_SUPPORTED is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate SUDO_ENABLE flag
    if [[ "${SUDO_ENABLE}" != "true" && "${SUDO_ENABLE}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: SUDO_ENABLE is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate DO_DTS_CPY flag
    if [[ "${DO_DTS_CPY}" != "true" && "${DO_DTS_CPY}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: DO_DTS_CPY is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate DO_IMGDIR_CPY flag
    if [[ "${DO_IMGDIR_CPY}" != "true" && "${DO_IMGDIR_CPY}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: DO_IMGDIR_CPY is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate DO_WEBSERVER_CPY flag
    if [[ "${DO_WEBSERVER_CPY}" != "true" && "${DO_WEBSERVER_CPY}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: DO_WEBSERVER_CPY is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate DO_DRIVERMOD_CPY flag
    if [[ "${DO_DRIVERMOD_CPY}" != "true" && "${DO_DRIVERMOD_CPY}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: DO_DRIVERMOD_CPY is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate DO_CALDATA_CPY flag
    if [[ "${DO_CALDATA_CPY}" != "true" && "${DO_CALDATA_CPY}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: DO_CALDATA_CPY is not set to true/false in 'etc/config.sh' - Aborting."
    fi

    # Validate ENABLE_SYMLINK_SHORTCUTS flag
    if [[ "${ENABLE_SYMLINK_SHORTCUTS}" != "true" && "${ENABLE_SYMLINK_SHORTCUTS}" != "false" ]]; then
        exit_with_error "❌ CRITICAL: ENABLE_SYMLINK_SHORTCUTS is not set to true/false in 'etc/config.sh' - Aborting."
    fi


    # ================
    # IS EMPTY CHECKS
    # ================

    # Validate OWRT_REMOTE_ALIAS is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_REMOTE_ALIAS" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_REMOTE_ALIAS is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_FORK_REPO is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_FORK_REPO" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_FORK_REPO is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_BASE_BRANCH is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_BASE_BRANCH" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_BASE_BRANCH is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate WORK_DIR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$WORK_DIR" ]]; then
        exit_with_error "❌ CRITICAL: WORK_DIR is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate PROJECT_DIR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$PROJECT_DIR" ]]; then
        exit_with_error "❌ CRITICAL: PROJECT_DIR is not set in 'etc/config.sh' - Aborting."
    fi

    # Validate OWRT_DEV_DIR is not empty (REQUIRED, CRITICAL)
    if [[ -z "$OWRT_DEV_DIR" ]]; then
        exit_with_error "❌ CRITICAL: OWRT_DEV_DIR is not set in 'etc/config.sh' - Aborting."
    fi

    # CONDITIONAL VALIDATION BASED ON BOOLS

    # Validate IMGDIR_SRC is not empty (REQUIRED, CRITICAL)
    if [[ "${DO_IMGDIR_CPY}" == "true" ]]; then
        if [[ -z "$IMGDIR_SRC" ]]; then
            exit_with_error "❌ CRITICAL: IMGDIR_SRC is not set in 'etc/config.sh' - Aborting."
        fi
    fi

    # Validate DTS_FNAME is not empty if DO_DTS_CPY = true (just validate not empty)
    if [[ "${DO_DTS_CPY}" == "true" ]]; then
        if [[ -z "$DTS_FNAME" ]]; then
            exit_with_error "❌ CRITICAL: DTS_FNAME is not set in 'etc/config.sh' - Aborting."
        fi
    fi

    # Validate WEBSERVER_USER is not empty (sane defaults already set, just validate not empty)
    if [[ "${DO_WEBSERVER_CPY}" == "true" ]]; then
        if [[ -z "$WEBSERVER_USER" ]]; then
            exit_with_error "❌ CRITICAL: WEBSERVER_USER is not set in 'etc/config.sh' - Aborting."
        fi
    fi

    # Validate WEBDIR_DEST is not empty (sane defaults already set, just validate not empty)
    if [[ "${DO_WEBSERVER_CPY}" == "true" ]]; then
        if [[ -z "$WEBDIR_DEST" ]]; then
            exit_with_error "❌ CRITICAL: WEBDIR_DEST is not set in 'etc/config.sh' - Aborting."
        fi
    fi

    # EXTRA VALIDATION REQUIRED

    # Validate DRIVERMOD_MODE is not empty (sane defaults already set, validate either patchmod or rawmod, and not empty)
    if [[ "${DO_DRIVERMOD_CPY}" == "true" ]]; then
        if [[ -z "$DRIVERMOD_MODE" || ("$DRIVERMOD_MODE" != "patchmod" && "$DRIVERMOD_MODE" != "rawmod") ]]; then
            exit_with_error "❌ CRITICAL: DRIVERMOD_MODE must be 'patchmod' or 'rawmod' in 'etc/config.sh'"
        fi
    fi

    # Validate RAWMOD_LIST is not empty IF enabled (sane defaults already set, validate either patchmod or rawmod, and not empty)
    if [[ "${DO_DRIVERMOD_CPY}" == "true" ]]; then
        if [[ -z "$RAWMOD_LIST" || ("$DRIVERMOD_MODE" != "patchmod" && "$DRIVERMOD_MODE" != "rawmod") ]]; then
            exit_with_error "❌ CRITICAL: RAWMOD_LIST is not set in 'etc/config.sh' - Aborting."
        fi
    fi

    # Validate CALDATA_LIST is not empty IF enabled
    if [[ "${DO_CALDATA_CPY}" == "true" ]]; then
        if [[ -z "$CALDATA_LIST" ]]; then
            exit_with_error "❌ CRITICAL: CALDATA_LIST is not set in 'etc/config.sh' - Aborting."
        fi
    fi


    # ===============================
    # AUTO DERIVED DIRECTORY DEFAULTS
    # ===============================

    # SOURCE DIRECTORIES

    # Validate WORK_DTS_DIR is not empty
    if [[ -z "$WORK_DTS_DIR" ]]; then
        WORK_DTS_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/dts"
        local msg=" >>> ⚠ WARNING: Using default auto-derived WORK_DTS_DIR ('$WORK_DTS_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # Validate WORK_CALDATA_DIR is not empty
    if [[ -z "$WORK_CALDATA_DIR" ]]; then
        WORK_CALDATA_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/caldata"
        local msg=" >>> ⚠ WARNING: Using default auto-derived WORK_CALDATA_DIR ('$WORK_CALDATA_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # Validate WORK_PATCHMODS_DIR is not empty
    if [[ -z "$WORK_PATCHMODS_DIR" ]]; then
        WORK_PATCHMODS_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/patchmods"
        local msg=" >>> ⚠ WARNING: Using default auto-derived WORK_PATCHMODS_DIR ('$WORK_PATCHMODS_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # Validate WORK_RAWMODS_DIR is not empty
    if [[ -z "$WORK_RAWMODS_DIR" ]]; then
        WORK_RAWMODS_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/rawmods"
        local msg=" >>> ⚠ WARNING: Using default auto-derived WORK_RAWMODS_DIR ('$WORK_RAWMODS_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # Validate WORK_IMAGEOUT_DIR is not empty
    if [[ -z "$WORK_IMAGEOUT_DIR" ]]; then
        WORK_IMAGEOUT_DIR="$WORK_DIR/$OWRT_SOC_CLASS_LOWER/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/image-out"
        local msg=" >>> ⚠ WARNING: Using default auto-derived WORK_IMAGEOUT_DIR ('$WORK_IMAGEOUT_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # DESTINATION DIRECTORIES

    # Validate DTS_DEST_DIR is not empty
    if [[ -z "$DTS_DEST_DIR" ]]; then
        DTS_DEST_DIR="$OWRT_DEV_DIR/target/$OWRT_OS_TARGET_LOWER/$OWRT_SOC_CLASS_LOWER/files-6.12/arch/arm/boot/dts/qcom"
        local msg=" >>> ⚠ WARNING: Using default auto-derived DTS_DEST_DIR ('$DTS_DEST_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi

    # Validate PATCHMOD_DEST_DIR is not empty
    if [[ -z "$PATCHMOD_DEST_DIR" ]]; then
        PATCHMOD_DEST_DIR="$OWRT_DEV_DIR/target/$OWRT_OS_TARGET_LOWER/$OWRT_SOC_CLASS_LOWER/patches-6.12"
        local msg=" >>> ⚠ WARNING: Using default auto-derived PATCHMOD_DEST_DIR ('$PATCHMOD_DEST_DIR')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi


    # ==============================
    # AUTO DERIVED VARIABLE DEFAULTS
    # ==============================

    # Validate OWRT_TARGET_BRANCH is not empty
    if [[ -z "$OWRT_TARGET_BRANCH" ]]; then
        OWRT_TARGET_BRANCH="${OWRT_MFR_LOWER}_${OWRT_MODEL_LOWER}-${OWRT_BASE_BRANCH}"
        local msg=" >>> ⚠ WARNING: Using default auto-derived OWRT_TARGET_BRANCH ('$OWRT_TARGET_BRANCH')"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi




    # ========================================
    # VALUE CONSTRAINT CHECKS (ex. $var -ge 6)
    # ========================================




    # ==============================================
    # Create the work/project dirs and clone openwrt
    # ==============================================

    # Create the required structure if not already exists
    if [[ ! -d "$WORK_DIR" ]]; then
        create_workdir
    fi

    # Create the required structure if not already exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        create_projectsdir
    fi

    # Clone openwrt fork
    if [[ ! -d "$OWRT_DEV_DIR" ]]; then
        clone_openwrt
    fi




    # =================
    # DIR EXISTS CHECKS
    # =================

    # Verify the critical directories actually exist:
    local critical_dirs=("$WORK_DIR" "$PROJECT_DIR" "$OWRT_DEV_DIR")
    for dir in "${critical_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            exit_with_error "❌ CRITICAL: Required directory does not exist: $dir"
        fi
    done




    # ==================
    # FILE EXISTS CHECKS
    # ==================




}

# Create work dir
create_workdir() {
    if [ ! -d "${WORK_DIR}" ]; then
        echo "Warning: Work directory '${WORK_DIR}' does not exist."
        read -r -p "Do you want to create it? [Y/n] " response
        case "$response" in
            [nN][oO]|[nN])
                exit_with_error "Please configure your paths in 'etc/config.sh' or accept the defaults"
                ;;
            *)
                echo "Creating ${WORK_DIR} structure..."
                mkdir -p "$WORK_DTS_DIR/oem"
                mkdir -p "$WORK_CALDATA_DIR"
                mkdir -p "$WORK_PATCHMODS_DIR"
                mkdir -p "$WORK_RAWMODS_DIR"
                mkdir -p "$WORK_IMAGEOUT_DIR"
                local msg=" >>> ✅ ${WORK_DIR} directory structure created"
                echo "$msg"
                SUMMARY_OUT+="${msg}"${NL}
                ;;
        esac
    fi
}

# Create projects dir
create_projectsdir() {
    if [ ! -d "${PROJECT_DIR}" ]; then
        echo "Warning: Project directory '${PROJECT_DIR}' does not exist."
        read -r -p "Do you want to create it? [Y/n] " response
        case "$response" in
            [nN][oO]|[nN])
                exit_with_error "Please configure your paths in 'etc/config.sh' or accept the defaults"
                ;;
            *)
                echo "Creating ${PROJECT_DIR}..."
                mkdir -p "${PROJECT_DIR}"
                local msg=" >>> ✅ ${PROJECT_DIR} directory structure created"
                echo "$msg"
                SUMMARY_OUT+="${msg}"${NL}
                ;;
        esac
    fi
}

clone_openwrt() {
    # TODO: if OWRT_DEV_DIR does not exist
    if [ ! -d "$OWRT_DEV_DIR" ]; then

        # 1) Test if the git repository exists
        if ! git ls-remote "$OWRT_FORK_REPO" >/dev/null 2>&1; then
            exit_with_error "Git repository $OWRT_FORK_REPO does not exist please check OWRT_FORK_REPO variable in \`etc/config.sh\` - Aborting."
        fi

        # 2) Prompt the user
        echo -n " >>> Cloning openwrt fork repository... Continue? [Y/n] "
        read -r reply
        reply=${reply:-Y} # Default to Y if empty

        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            exit_with_error "Please either configure the openwrt fork repository at the path in 'etc/config.sh' or continue with the clone."
        fi

        # cd to PROJECT_DIR directory
        cd "$PROJECT_DIR" || exit 1

        # stderr message only (cloning openwrt into OWRT_DEV_DIR)
        echo " >>> Cloning openwrt into $OWRT_DEV_DIR" >&2

        # clone OWRT_FORK_REPO into OWRT_DEV_DIR ; cd OWRT_DEV_DIR ; checkout OWRT_BASE_BRANCH ;
        git clone "$OWRT_FORK_REPO" "$OWRT_DEV_DIR" >&2
        cd "$OWRT_DEV_DIR" || exit 1

        git checkout "$OWRT_BASE_BRANCH" >&2

        # check if OWRT_TARGET_BRANCH exists if not create it from OWRT_BASE_BRANCH and checkout OWRT_TARGET_BRANCH
        if ! git rev-parse --verify "$OWRT_TARGET_BRANCH" >/dev/null 2>&1; then
            git checkout -b "$OWRT_TARGET_BRANCH" "$OWRT_BASE_BRANCH" >&2
        else
            git checkout "$OWRT_TARGET_BRANCH" >&2
        fi

        # cd back to STARTUP_PWD
        cd "$STARTUP_PWD" || exit 1

        # display final SUMMARY_OUT & stderr (successful openwrt fork clone into OWRT_DEV_DIR)
        local msg=" >>> ✅ Cloned openwrt fork into ${OWRT_DEV_DIR}"
        echo "$msg"
        SUMMARY_OUT+="${msg}"${NL}
    fi
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

    # Prompt user
    echo "The following packages will be installed: ${filtered_pkgs[*]}"
    read -r -p "Continue? (Y/n) " choice
    choice=${choice:-Y}

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
    echo "  🌿 Branch: ${GIT_BRANCH}"
    echo " ========================================================================================================================"
    echo "  📜 Script: $REAL_PATH"
    echo "  📁 PWD: $STARTUP_PWD"
    echo " ========================================================================================================================"
    echo "  💻 SOC: $OWRT_SOC_CLASS"
    echo "  🗜 MFR: $OWRT_MFR"
    echo "  💃 MODEL: $OWRT_MODEL"
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

    # Disable errexit to prevent silent exits in cleanup
    set +e

    cleanup_build_environment

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

    # Disable errexit to prevent silent exits in cleanup
    set +e

    cleanup_build_environment

    local err_msg="$1"
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

    local dest_dir="$WORK_IMAGEOUT_DIR"
    [[ -z "$dest_dir" ]] && exit_with_error "IMGDIR_DEST/WORK_IMAGEOUT_DIR is not set"

    # clobber the image out old files
    rm -rf "${dest_dir:?}/"* || exit_with_error "Clobber image-out dir"

    # copy the new files (use OWRT_BASE_BRANCH as subdir)
    cp -r "$IMGDIR_SRC/"* "$dest_dir/$OWRT_BASE_BRANCH/" || exit_with_error "Copy images to image-out"

    local msg=" >>> ✅ IMAGES COPIED TO WORK DIR: $IMGDIR_DEST"
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

}

copy_to_webserver() {

    if [ "$DO_WEBSERVER_CPY" == "true" ]; then
        # Do NOT quote the * so it expands properly
        echo " >>> Copying images to webserver..."

        local dest="$WORK_IMAGEOUT_DIR/$OWRT_BASE_BRANCH"

        mkdir -p "$dest"

        # clobber the image out old files
        rm -rf "$dest/"* || exit_with_error "Clobber webserver image-out dir: $(cleanup_path "$dest")"

        # copy the new files
        cp -r "$IMGDIR_SRC/"* "$dest/" || exit_with_error "Copy images to webserver image-out dir: $(cleanup_path "$dest")"

        # TODO: SET CORRECT PERMISSIONS (SEE DOCS LOL)

        local msg=" >>> ✅ Images copied to webserver: $(cleanup_path "$dest")"
        echo "$msg"
        SUMMARY_OUT+="${msg}"$NL
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
    local msg=" >>> ✅ Sources downloaded (all)"
    echo "$msg"
    SUMMARY_OUT+="$msg"${NL}

    if [ "$DO_DRIVERMOD_CPY" = true ]; then

        if [ "$DRIVERMOD_MODE" == "patchmod" ]; then

            if [ -z "${PATCHMOD_DEST_DIR}" ]; then
                exit_with_error "PATCHMOD_DEST_DIR is not set (check script config)"
            fi

    	    # Copy custom patches into the target directory
            # These will be picked up automatically by the 'prepare' step
            copy_patches_dir "$WORK_PATCHMODS_DIR" "$OWRT_DEV_DIR/$PATCHMOD_DEST_DIR"

            local msg=" >>> ✅ DRIVER PATCHES copied to source tree: $PATCHMOD_SRC_DIR"
            echo "$msg"
            SUMMARY_OUT+="$msg"${NL}

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
                local msg=" >>> ✅ IPQESS RAW DRIVER MOD ($RAWMOD_ENTRYNAME) copied to source tree: $(cleanup_path "$(dirname "$RAWMOD_SRC")")"
                echo "$msg"
                SUMMARY_OUT+="$msg"${NL}
            done <<< "$RAWMOD_LIST"

        fi

    fi

    # Prepare (Extract + Apply Patches)
    echo " >>> Running 'make target/linux/prepare'..."
    make target/linux/prepare ${MAKE_CMD_ADD} || exit_with_error "Make Prepare `linux`"
    local msg=" >>> ✅ Sources prepared (linux)"
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

    # Compile
    echo " >>> Running 'make target/linux/compile'..."
    make target/linux/compile ${MAKE_CMD_ADD} || exit_with_error "Make Compile `linux`"
    local msg=" >>> ✅ Sources compiled (linux) with custom patches applied"
    echo "$msg"
    SUMMARY_OUT+="${msg}"${NL}

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

    # Change to the openwrt directory
    cd "$OWRT_DEV_DIR"

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
    cd "$STARTUP_PWD" || true

}
