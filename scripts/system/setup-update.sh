#!/bin/bash

# System Packages & Repositories Update Script
# Refreshes package manager repositories and performs a full system upgrade
# across supported distributions (Debian 13, Fedora 44, Arch Linux).

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_update_debian() {
  echo "Refreshing APT repositories and upgrading Debian packages..."
  # Justification: install_packages does not abstract full-system upgrade operations
  sudo apt update
  sudo apt upgrade -y
}

_update_lmde() {
  echo "Refreshing APT repositories and upgrading LMDE packages..."
  if command -v mintupdate-cli > /dev/null 2>&1; then
    echo "Applying updates via mintupdate-cli..."
    sudo mintupdate-cli upgrade -r -y || {
      echo "mintupdate-cli exited with error; falling back to apt upgrade..."
      sudo apt update
      sudo apt upgrade -y
    }
  else
    sudo apt update
    sudo apt upgrade -y
  fi
}

_update_fedora() {
  echo "Refreshing DNF repositories and upgrading Fedora packages..."
  # Justification: install_packages does not abstract full-system upgrade operations
  sudo dnf upgrade -y --refresh
}

_update_arch() {
  echo "Refreshing Pacman databases and upgrading Arch Linux packages..."
  # Justification: install_packages does not abstract full-system upgrade operations
  sudo pacman -Syu --noconfirm
}

main() {
  echo "Starting system update and upgrade..."

  if [ "${UPDATE_SKIP_SYSTEM_UPGRADE:-0}" = "1" ]; then
    echo "UPDATE_SKIP_SYSTEM_UPGRADE is active. Skipping system upgrade."
    echo "setup-update complete"
    return 0
  fi

  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    debian)
      _update_debian
      ;;
    lmde)
      _update_lmde
      ;;
    fedora)
      _update_fedora
      ;;
    arch)
      _update_arch
      ;;
  esac

  echo "setup-update complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
