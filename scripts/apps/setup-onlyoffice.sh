#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_onlyoffice() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    debian | fedora | arch)
      echo "Installing ONLYOFFICE with flatpak..."
      install_flatpak_app "org.onlyoffice.desktopeditors" "ONLYOFFICE"
      ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac
}

main() {
  echo "Setting up ONLYOFFICE..."
  _install_onlyoffice
  echo "setup-onlyoffice complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
