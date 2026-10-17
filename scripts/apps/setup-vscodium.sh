#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

_install_vscodium() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    debian)
      add_debian_vscodium_repo
      ;;
    fedora)
      add_fedora_vscodium_repo
      ;;
  esac

  echo "Installing VSCodium..."
  install_packages vscodium
  _setup_vscodium_desktop_integration
}

_setup_vscodium_desktop_integration() {
  local app_dir="/usr/share/applications"
  local code_oss_desktop="${app_dir}/com.visualstudio.CodeOSS.desktop"
  local codium_desktop="${app_dir}/codium.desktop"

  if [ -f "$code_oss_desktop" ] && [ ! -f "$codium_desktop" ]; then
    echo "Creating compatibility symlink for codium.desktop..."
    sudo ln -sf "$code_oss_desktop" "$codium_desktop" 2> /dev/null || true
  fi

  if command -v update-desktop-database > /dev/null 2>&1; then
    sudo update-desktop-database "$app_dir" 2> /dev/null || true
  fi
}

main() {
  echo "Setting up VSCodium..."
  _install_vscodium
  echo "setup-vscodium complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
