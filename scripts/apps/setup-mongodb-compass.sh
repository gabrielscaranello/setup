#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_install_mongodb_compass() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  apt | dnf | pacman)
    echo "Installing MongoDB Compass with flatpak..."
    install_flatpak_app "mongodb.Compass" "MongoDB Compass"
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up MongoDB Compass..."
  _install_mongodb_compass
  echo "setup-mongodb-compass complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
