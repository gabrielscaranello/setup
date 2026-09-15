#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

_configure_vscodium_repo() {
  local distro="$1"
  case "$distro" in
    debian)
      add_debian_vscodium_repo
      ;;
    fedora)
      add_fedora_vscodium_repo
      ;;
  esac
}

_install_vscodium() {
  local distro
  distro="$(require_supported_distro)" || return 1

  _configure_vscodium_repo "$distro"
  echo "Installing VSCodium..."
  install_packages vscodium
}

main() {
  echo "Setting up VSCodium..."
  _install_vscodium
  echo "setup-vscodium complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
