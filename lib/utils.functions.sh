#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# =============================================================================
# change_directory
# Description: Changes the current working directory to the target path, exiting with an error if it fails or does not exist.
# Parameters: $1 (target directory path), $2 (optional custom error message)
# Returns/Exit Codes: Exits with code 1 on failure; returns 0 on success
# Usage Example:
#   change_directory "/path/to/dir" "Custom error if fails"
# =============================================================================
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

# =============================================================================
# get_time_diff
# Description: Calculates the elapsed time between two time strings and formats it as Xh Ym Zs.
# Parameters: $1 (start time string), $2 (end time string)
# Returns/Exit Codes: Echoes formatted duration string and total seconds; returns 0
# Usage Example:
#   get_time_diff "14:30:00" "16:45:30"
# =============================================================================
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

  printf "%dh %dm %ds\n" "$hours" "$minutes" "$seconds" "$diff"
}


# =============================================================================
# validate_path_exists
# Description: Checks if a directory exists at the given path and exits with an error if it does not.
# Parameters: $1 (directory path), $2 (descriptive name for error message)
# Returns/Exit Codes: Exits with code 1 on failure; returns 0 on success
# Usage Example:
#   validate_path_exists "/path/to/dir" "Project Directory"
# =============================================================================
validate_path_exists() {
  local path="$1"
  local name="$2"
  if [[ ! -d "$path" ]]; then
    echo "ERROR: $name directory not found: $path" >&2
    exit 1
  fi
}

# =============================================================================
# resolve_single_glob
# Description: Expands a glob pattern and returns the first matching directory, issuing a warning if multiple matches exist.
# Parameters: $1 (glob pattern), $2 (description for warning message)
# Returns/Exit Codes: Echoes the resolved path; exits with code 1 on failure
# Usage Example:
#   resolve_single_glob "/path/to/*/config" "Configuration Directory"
# =============================================================================
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

