#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_fetch_remote_version() {
  local ver
  ver="$(fetch_github_latest_version "jesseduffield/lazydocker")"
  echo "${ver#v}"
}

_get_local_version() {
  if command -v lazydocker > /dev/null 2>&1; then
    lazydocker --version 2> /dev/null | grep -Po 'version=\K[^,]*' || true
  elif [ -x "/usr/local/bin/lazydocker" ]; then
    /usr/local/bin/lazydocker --version 2> /dev/null | grep -Po 'version=\K[^,]*' || true
  elif [ -x "$HOME/.local/bin/lazydocker" ]; then
    "$HOME/.local/bin/lazydocker" --version 2> /dev/null | grep -Po 'version=\K[^,]*' || true
  fi
}

_is_lazydocker_up_to_date() {
  local target_ver="${1:-$(_fetch_remote_version)}"
  is_version_up_to_date "$(_get_local_version)" "$target_ver"
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

  if [ -n "$latest_version" ] && _is_lazydocker_up_to_date "$latest_version"; then
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
  install_github_binary "Lazydocker" "jesseduffield/lazydocker" "$latest_version" "$file_name" "lazydocker"
}

_install_lazydocker() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    arch)
      echo "Installing lazydocker from distribution repository..."
      install_packages lazydocker
      ;;
    debian | fedora)
      _install_lazydocker_binary
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
