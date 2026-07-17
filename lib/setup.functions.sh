#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# =============================================================================
# create_workdir
# Description: Creates the work directory structure if it doesn't exist, prompting the user interactively or auto-creating in non-interactive mode.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 on success; exits with error on failure
# Usage Example:
#   create_workdir
# =============================================================================
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

# =============================================================================
# create_projectsdir
# Description: Creates the project directory structure if it doesn't exist, prompting the user interactively or auto-creating in non-interactive mode.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 on success; exits with error on failure
# Usage Example:
#   create_projectsdir
# =============================================================================
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

# =============================================================================
# clone_openwrt
# Description: Clones the OpenWRT fork repository if it doesn't exist, handles branch checkout, and sets up the development directory.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 on success; exits with error on failure
# Usage Example:
#   clone_openwrt
# =============================================================================
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

# =============================================================================
# create_port_shareddir
# Description: Creates the port-specific shared directory structure with appropriate permissions if it doesn't exist.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 on success; exits with error on failure
# Usage Example:
#   create_port_shareddir
# =============================================================================
create_port_shareddir() {
    local port_shareddir="$WEBSERVER_SHARED_DIR/$OWRT_MFR_LOWER/$OWRT_MODEL_LOWER/$OWRT_VERSION"

    if [ ! -d "${port_shareddir}" ]; then
        echo " >>> Warning: Webserver shareddir directory for port '$port_shareddir' does not exist."

        local response="Y"
        if [[ "$OWRTDS_INTERACTIVE" == "true" ]]; then
            read -r -p "Do you want to create it? [Y/n] " response
            response=${response:-Y}
        else
            echo " >>> [NON-INTERACTIVE] Auto-creating port shareddir..."
            response="Y" # Force auto-create in non-interactive mode
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
    fi
}

# =============================================================================
# create_webserver_shareddir
# Description: Sets up web server shared directory structure, handles group
#              management, permissions, symlink creation, and optional webserver
#              restart.
# Parameters: None
# Returns/Exit Codes: Exits with code 0 on success; exits with error on failure
# Usage Example:
#   create_webserver_shareddir
# =============================================================================
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

# =============================================================================
# install_dependencies
# Description: Detects the OS package manager, identifies missing dependencies,
#              and installs them (with user confirmation or auto-proceed).
# Parameters: None
# Returns/Exit Codes: Exits with code 0 on success; returns 1 if unsupported
#                     package manager is detected
# Usage Example:
#   install_dependencies
# =============================================================================
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
        log_summary ">>> ✅ All required dependencies are already installed." --silent
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
