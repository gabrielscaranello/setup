#!/bin/bash

# Desktop dconf helper functions (sourced as utility, not executed directly)

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

ensure_dconf() {
  if ! command -v dconf > /dev/null 2>&1; then
    echo "dconf not found in PATH, attempting to install..."
    install_packages dconf || true
  fi

  if ! command -v dconf > /dev/null 2>&1; then
    echo "Error: dconf CLI is not installed or not found in PATH." >&2
    return 1
  fi
}

dconf_exec() {
  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-run-session > /dev/null 2>&1; then
    dbus-run-session -- dconf "$@"
  else
    dconf "$@"
  fi
}

gsettings_exec() {
  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-run-session > /dev/null 2>&1; then
    dbus-run-session -- gsettings "$@"
  else
    gsettings "$@"
  fi
}

load_dconf_file() {
  local file_path="$1"
  local name
  name="$(basename "$file_path")"

  if [ ! -f "$file_path" ]; then
    echo "  Warning: Configuration file '$file_path' not found. Skipping." >&2
    return 0
  fi

  echo "  Loading dconf configuration: $name..."
  dconf_exec load / < "$file_path"
}

load_dconf_files() {
  local base_dir="$1"
  shift
  local files=("$@")

  if [ ! -d "$base_dir" ]; then
    echo "Error: Configuration directory '$base_dir' not found." >&2
    return 1
  fi

  for file in "${files[@]}"; do
    load_dconf_file "${base_dir}/${file}"
  done
}
