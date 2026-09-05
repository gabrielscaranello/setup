#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true
source "scripts/system/debian/_repositories.sh" 2>/dev/null || true
source "scripts/system/fedora/_repositories.sh" 2>/dev/null || true

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

_install_vscodium_packages() {
  local distro="$1"
  case "$distro" in
  debian | fedora)
    install_packages codium
    ;;
  arch)
    echo "Installing Code (OSS) from Arch repositories..."
    install_packages code
    ;;
  esac
}

_install_vscodium() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  debian | fedora | arch)
    _configure_vscodium_repo "$distro"
    _install_vscodium_packages "$distro"
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
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
