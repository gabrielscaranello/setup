#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

LAZYGIT_API_URL="https://api.github.com/repos/jesseduffield/lazygit/releases/latest"

_install_prereqs() {
  install_packages curl wget tar || true
}

_fetch_remote_version() {
  local version=""
  if command -v curl >/dev/null 2>&1; then
    version="$(curl -s "$LAZYGIT_API_URL" 2>/dev/null | grep -Po '"tag_name":\s*"v\K[^"]*' || true)"
  elif command -v wget >/dev/null 2>&1; then
    version="$(wget -qO- "$LAZYGIT_API_URL" 2>/dev/null | grep -Po '"tag_name":\s*"v\K[^"]*' || true)"
  fi

  echo "$version" | tr -d '[:space:]'
}

_get_local_version() {
  if command -v lazygit >/dev/null 2>&1; then
    lazygit --version 2>/dev/null | grep -Po 'version=\K[^,]*' || true
  elif [ -x "/usr/local/bin/lazygit" ]; then
    /usr/local/bin/lazygit --version 2>/dev/null | grep -Po 'version=\K[^,]*' || true
  fi
}

_is_lazygit_up_to_date() {
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

_install_lazygit_binary() {
  local latest_version
  latest_version="$(_fetch_remote_version)"

  if [ -z "$latest_version" ]; then
    echo "Warning: Could not fetch latest lazygit version from GitHub API" >&2
  fi

  if [ -n "$latest_version" ] && _is_lazygit_up_to_date; then
    echo "lazygit is already up to date (version: ${latest_version}), skipping installation."
    return 0
  fi

  _install_prereqs

  # Fallback if latest_version was empty
  if [ -z "$latest_version" ]; then
    latest_version="$(_fetch_remote_version)"
    if [ -z "$latest_version" ]; then
      echo "Failed to determine latest lazygit release version" >&2
      return 1
    fi
  fi

  local file_name="lazygit_${latest_version}_Linux_x86_64.tar.gz"
  local download_url="https://github.com/jesseduffield/lazygit/releases/download/v${latest_version}/${file_name}"
  local output_file="/tmp/${file_name}"
  local extract_dir="/tmp/lazygit-extract"
  local target_dir="/usr/local/bin"

  echo "Installing Lazygit ($latest_version)..."

  echo "Removing old build files if they exist..."
  rm -rf "$output_file" "$extract_dir"

  echo "Downloading Lazygit..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$download_url" -o "$output_file"
  else
    wget -qO "$output_file" "$download_url"
  fi

  echo "Extracting Lazygit..."
  mkdir -p "$extract_dir"
  tar -xzf "$output_file" -C "$extract_dir"

  echo "Installing Lazygit to $target_dir..."
  sudo install "$extract_dir/lazygit" "$target_dir/"

  echo "Cleaning up temporary files..."
  rm -rf "$output_file" "$extract_dir"

  echo "Lazygit installed successfully at $(command -v lazygit || echo '/usr/local/bin/lazygit')"
}

_install_lazygit_repo() {
  echo "Installing lazygit from distribution repository..."
  install_packages lazygit
}

_install_lazygit() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  pacman)
    _install_lazygit_repo
    ;;
  apt | dnf)
    _install_lazygit_binary
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up Lazygit..."
  _install_lazygit
  echo "setup-lazygit complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
