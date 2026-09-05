#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

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

_link_binary() {
  local src="$1"
  local name="$2"
  local user_bin="$HOME/.local/bin"

  if [ ! -x "$src" ]; then
    return 0
  fi

  ln -sf "$src" "$user_bin/$name"

  if [ -w "/usr/local/bin" ]; then
    ln -sf "$src" "/usr/local/bin/$name"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo ln -sf "$src" "/usr/local/bin/$name" 2>/dev/null || true
  fi
}

_create_binary_symlinks() {
  local base_dir="$1"
  local bin_kitty="$base_dir/bin/kitty"
  local bin_kitten="$base_dir/bin/kitten"

  _link_binary "$bin_kitty" "kitty"
  _link_binary "$bin_kitty" "x-terminal-emulator"
  _link_binary "$bin_kitten" "kitten"
}

_install_desktop_entries() {
  local base_dir="$1"
  local apps_dir="$HOME/.local/share/applications"
  local icon_path="$base_dir/share/icons/hicolor/256x256/apps/kitty.png"
  local bin_kitty="$base_dir/bin/kitty"

  if [ -f "$base_dir/share/applications/kitty.desktop" ]; then
    cp "$base_dir/share/applications/kitty.desktop" "$apps_dir/"
  fi
  if [ -f "$base_dir/share/applications/kitty-open.desktop" ]; then
    cp "$base_dir/share/applications/kitty-open.desktop" "$apps_dir/"
  fi

  if [ -f "$icon_path" ]; then
    sed -i "s|Icon=kitty|Icon=${icon_path}|g" "$apps_dir"/kitty*.desktop 2>/dev/null || true
  fi
  if [ -x "$bin_kitty" ]; then
    sed -i "s|Exec=kitty|Exec=${bin_kitty}|g" "$apps_dir"/kitty*.desktop 2>/dev/null || true
  fi
}

_setup_desktop_integration() {
  local base_dir="$HOME/.local/kitty.app"

  echo "Setting up desktop integration and PATH symlinks for kitty..."

  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

  _create_binary_symlinks "$base_dir"
  _install_desktop_entries "$base_dir"
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
  install_packages curl wget tar xz-utils || true

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
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  arch | fedora)
    _install_kitty_repo
    ;;
  debian)
    _install_kitty_binary
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
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
