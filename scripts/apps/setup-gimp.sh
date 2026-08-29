#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_install_gimp() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    echo "Installing GIMP from distribution repository..."
    install_packages gimp
    ;;
  apt)
    echo "Installing GIMP with flatpak..."
    install_flatpak_app "org.gimp.GIMP" "GIMP"
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
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
