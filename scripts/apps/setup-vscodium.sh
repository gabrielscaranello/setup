#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true
source "scripts/system/debian/_repositories.sh" 2>/dev/null || true
source "scripts/system/fedora/_repositories.sh" 2>/dev/null || true

_install_vscodium() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  apt)
    add_debian_vscodium_repo
    install_packages codium
    ;;
  dnf)
    add_fedora_vscodium_repo
    install_packages codium
    ;;
  pacman)
    echo "Installing Code (OSS) from Arch repositories..."
    install_packages code
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up VSCodium..."
  _install_vscodium
  echo "setup-vscodium complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
