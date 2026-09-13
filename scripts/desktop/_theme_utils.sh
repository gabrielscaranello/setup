#!/bin/bash
set -euo pipefail

# Desktop Theme Helper Utilities
# Provides shared functions for cursor, icon, and GTK theme management,
# including directory installation, version tracking, and filesystem inspection.

# Source core utilities if not already loaded
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

# Checks if a theme directory exists in standard user or system paths
# Usage: is_theme_installed <theme_type> <theme_name> [subpath]
# Examples:
#   is_theme_installed "icons" "Bibata-Modern-Ice" "cursors"
#   is_theme_installed "themes" "adw-gtk3"
#   is_theme_installed "icons" "Papirus-Dark"
is_theme_installed() {
  local theme_type="$1"
  local theme_name="$2"
  local subpath="${3:-}"

  local check_path="${theme_name}"
  if [ -n "$subpath" ]; then
    check_path="${theme_name}/${subpath}"
  fi

  if [ -d "/usr/share/${theme_type}/${check_path}" ] \
    || [ -d "$HOME/.local/share/${theme_type}/${check_path}" ] \
    || [ -d "$HOME/.${theme_type}/${check_path}" ]; then
    return 0
  fi
  return 1
}

# Reads local version metadata from installed theme directory
# Usage: get_theme_local_version <theme_type> <theme_name>
get_theme_local_version() {
  local theme_type="$1"
  local theme_name="$2"

  if [ -f "$HOME/.local/share/${theme_type}/${theme_name}/.version" ]; then
    cat "$HOME/.local/share/${theme_type}/${theme_name}/.version"
  elif [ -f "/usr/share/${theme_type}/${theme_name}/.version" ]; then
    cat "/usr/share/${theme_type}/${theme_name}/.version"
  else
    echo ""
  fi
}

# Deploys an extracted theme directory to user and (optionally) system paths
# Usage: deploy_theme_directory <source_dir> <theme_type> [theme_name]
deploy_theme_directory() {
  local source_dir="$1"
  local theme_type="$2"
  local theme_name="${3:-$(basename "$source_dir")}"

  [ -d "$source_dir" ] || return 0

  local user_dir="$HOME/.local/share/${theme_type}"
  local legacy_dir="$HOME/.${theme_type}"
  local system_dir="/usr/share/${theme_type}"

  mkdir -p "$user_dir" "$legacy_dir"
  rm -rf "${user_dir:?}/${theme_name:?}"
  cp -r "$source_dir" "$user_dir/$theme_name"
  ln -sfn "$user_dir/$theme_name" "$legacy_dir/$theme_name"

  if [ -w "$system_dir" ]; then
    rm -rf "${system_dir:?}/${theme_name:?}"
    cp -r "$source_dir" "$system_dir/$theme_name"
  elif command -v sudo > /dev/null 2>&1 && sudo -n true 2> /dev/null; then
    sudo rm -rf "${system_dir:?}/${theme_name:?}" 2> /dev/null || true
    sudo cp -r "$source_dir" "$system_dir/$theme_name" 2> /dev/null || true
  fi
}
