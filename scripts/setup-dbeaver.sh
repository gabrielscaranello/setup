#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_install_dbeaver() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  pacman)
    echo "Installing DBeaver from distribution repository..."
    install_packages dbeaver
    ;;
  apt | dnf)
    echo "Installing DBeaver with flatpak..."
    install_flatpak_app "io.dbeaver.DBeaverCommunity" "DBeaver"
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up DBeaver..."
  _install_dbeaver
  echo "setup-dbeaver complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
