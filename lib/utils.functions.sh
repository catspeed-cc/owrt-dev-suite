#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

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

