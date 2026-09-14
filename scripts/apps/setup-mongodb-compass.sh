#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

main() {
  echo "Setting up MongoDB Compass..."
  require_supported_distro > /dev/null || return 1
  echo "Installing MongoDB Compass with flatpak..."
  install_flatpak_app "com.mongodb.Compass" "MongoDB Compass"
  echo "setup-mongodb-compass complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
