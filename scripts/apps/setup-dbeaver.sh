#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_install_dbeaver() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  arch)
    echo "Installing DBeaver from distribution repository..."
    install_packages dbeaver
    ;;
  debian | fedora)
    echo "Installing DBeaver with flatpak..."
    install_flatpak_app "io.dbeaver.DBeaverCommunity" "DBeaver"
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
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
