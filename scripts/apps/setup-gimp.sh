#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_install_gimp() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  fedora | arch)
    echo "Installing GIMP from distribution repository..."
    install_packages gimp
    ;;
  debian)
    echo "Installing GIMP with flatpak..."
    install_flatpak_app "org.gimp.GIMP" "GIMP"
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up GIMP..."
  _install_gimp
  echo "setup-gimp complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
