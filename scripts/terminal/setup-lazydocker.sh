#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

LAZYDOCKER_API_URL="https://api.github.com/repos/jesseduffield/lazydocker/releases/latest"

_fetch_remote_version() {
  local version=""
  version="$(fetch_url "$LAZYDOCKER_API_URL" | grep -Po '"tag_name":\s*"v\K[^"]*' || true)"
  echo "$version" | tr -d '[:space:]'
}

_get_local_version() {
  if command -v lazydocker >/dev/null 2>&1; then
    lazydocker --version 2>/dev/null | grep -Po 'version=\K[^,]*' || true
  elif [ -x "/usr/local/bin/lazydocker" ]; then
    /usr/local/bin/lazydocker --version 2>/dev/null | grep -Po 'version=\K[^,]*' || true
  elif [ -x "$HOME/.local/bin/lazydocker" ]; then
    "$HOME/.local/bin/lazydocker" --version 2>/dev/null | grep -Po 'version=\K[^,]*' || true
  fi
}

_is_lazydocker_up_to_date() {
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

_resolve_lazydocker_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
  i386 | i686) echo "x86" ;;
  aarch64 | arm64) echo "arm64" ;;
  *) echo "$arch" ;;
  esac
}

_install_lazydocker_binary() {
  local latest_version
  latest_version="$(_fetch_remote_version)"

  if [ -z "$latest_version" ]; then
    echo "Warning: Could not fetch latest lazydocker version from GitHub API" >&2
  fi

  if [ -n "$latest_version" ] && _is_lazydocker_up_to_date; then
    echo "lazydocker is already up to date (version: ${latest_version}), skipping installation."
    return 0
  fi

  install_packages curl wget tar || true

  local arch
  arch="$(_resolve_lazydocker_arch)"

  # Fallback if latest_version was empty
  if [ -z "$latest_version" ]; then
    latest_version="$(_fetch_remote_version)"
    if [ -z "$latest_version" ]; then
      echo "Failed to determine latest lazydocker release version" >&2
      return 1
    fi
  fi

  local file_name="lazydocker_${latest_version}_Linux_${arch}.tar.gz"
  local download_url="https://github.com/jesseduffield/lazydocker/releases/download/v${latest_version}/${file_name}"
  local output_file="/tmp/${file_name}"
  local extract_dir="/tmp/lazydocker-extract"
  local target_dir="/usr/local/bin"

  echo "Installing Lazydocker ($latest_version)..."

  echo "Removing old build files if they exist..."
  rm -rf "$output_file" "$extract_dir"

  echo "Downloading Lazydocker..."
  download_file "$download_url" "$output_file"

  echo "Extracting Lazydocker..."
  mkdir -p "$extract_dir"
  tar -xzf "$output_file" -C "$extract_dir"

  echo "Installing Lazydocker to $target_dir..."
  sudo install "$extract_dir/lazydocker" "$target_dir/"

  echo "Cleaning up temporary files..."
  rm -rf "$output_file" "$extract_dir"

  echo "Lazydocker installed successfully at $(command -v lazydocker || echo '/usr/local/bin/lazydocker')"
}

_install_lazydocker_repo() {
  echo "Installing lazydocker from distribution repository..."
  install_packages lazydocker
}

_install_lazydocker() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  pacman)
    _install_lazydocker_repo
    ;;
  apt | dnf)
    _install_lazydocker_binary
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up Lazydocker..."
  _install_lazydocker
  echo "setup-lazydocker complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
