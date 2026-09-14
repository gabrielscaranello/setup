#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

main() {
  echo "Setting up DBeaver..."
  require_supported_distro > /dev/null || return 1
  echo "Installing DBeaver with flatpak..."
  install_flatpak_app "io.dbeaver.DBeaverCommunity" "DBeaver"
  echo "setup-dbeaver complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
