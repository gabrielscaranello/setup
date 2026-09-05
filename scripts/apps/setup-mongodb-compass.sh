#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_mongodb_compass() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    debian | fedora | arch)
      echo "Installing MongoDB Compass with flatpak..."
      install_flatpak_app "mongodb.Compass" "MongoDB Compass"
      ;;
    *)
      echo "Unsupported distribution: $distro" >&2
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
