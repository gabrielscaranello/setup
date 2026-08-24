#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_install_prereqs() {
  install_packages curl wget tar xz-utils || true
}

_fetch_remote_version() {
  local version_url="https://sw.kovidgoyal.net/kitty/current-version.txt"
  local version=""
  version="$(fetch_url "$version_url")"
  echo "$version" | tr -d '[:space:]'
}

_get_local_version() {
  local bin_path="$HOME/.local/kitty.app/bin/kitty"
  if [ -x "$bin_path" ]; then
    "$bin_path" --version 2>/dev/null | awk '{print $2}' || true
  fi
}

_is_kitty_up_to_date() {
  local local_ver remote_ver
  local_ver="$(_get_local_version)"
  if [ -z "$local_ver" ]; then
    return 1
  fi

  remote_ver="$(_fetch_remote_version)"
  if [ -n "$remote_ver" ] && [ "$local_ver" = "$remote_ver" ]; then
    return 0
  fi

  return 1
}

_setup_desktop_integration() {
  local base_dir="$HOME/.local/kitty.app"
  local bin_kitty="$base_dir/bin/kitty"
  local bin_kitten="$base_dir/bin/kitten"
  local user_bin="$HOME/.local/bin"
  local apps_dir="$HOME/.local/share/applications"
  local icon_path="$base_dir/share/icons/hicolor/256x256/apps/kitty.png"

  echo "Setting up desktop integration and PATH symlinks for kitty..."

  mkdir -p "$user_bin" "$apps_dir" "$HOME/.config"

  # Create symbolic links to add kitty and kitten to PATH
  if [ -x "$bin_kitty" ]; then
    ln -sf "$bin_kitty" "$user_bin/kitty"
  fi
  if [ -x "$bin_kitten" ]; then
    ln -sf "$bin_kitten" "$user_bin/kitten"
  fi

  # Place the kitty.desktop and kitty-open.desktop files in applications directory
  if [ -f "$base_dir/share/applications/kitty.desktop" ]; then
    cp "$base_dir/share/applications/kitty.desktop" "$apps_dir/"
  fi
  if [ -f "$base_dir/share/applications/kitty-open.desktop" ]; then
    cp "$base_dir/share/applications/kitty-open.desktop" "$apps_dir/"
  fi

  # Update the paths to kitty and its icon in the desktop file(s)
  if [ -f "$icon_path" ]; then
    sed -i "s|Icon=kitty|Icon=${icon_path}|g" "$apps_dir"/kitty*.desktop 2>/dev/null || true
  fi
  if [ -x "$bin_kitty" ]; then
    sed -i "s|Exec=kitty|Exec=${bin_kitty}|g" "$apps_dir"/kitty*.desktop 2>/dev/null || true
  fi

  # Make xdg-terminal-exec use kitty if config file is set
  echo 'kitty.desktop' >"$HOME/.config/xdg-terminals.list"
}

_install_kitty_binary() {
  if _is_kitty_up_to_date; then
    local current_ver
    current_ver="$(_get_local_version)"
    echo "kitty is already up to date (version: ${current_ver}), skipping installation."
    _setup_desktop_integration
    return 0
  fi

  echo "Installing/updating kitty from upstream binary installer..."
  _install_prereqs

  local installer_url="https://sw.kovidgoyal.net/kitty/installer.sh"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$installer_url" | sh /dev/stdin launch=n
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$installer_url" | sh /dev/stdin launch=n
  else
    echo "Neither curl nor wget available to download kitty" >&2
    return 1
  fi

  _setup_desktop_integration

  echo "kitty installed successfully at $HOME/.local/kitty.app/bin/kitty"
}

_install_kitty_repo() {
  echo "Installing kitty from distribution repository..."
  install_packages kitty
}

_install_kitty() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    _install_kitty_repo
    ;;
  apt)
    _install_kitty_binary
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up kitty..."
  _install_kitty
  echo "setup-kitty complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
