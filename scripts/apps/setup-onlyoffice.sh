#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

main() {
  echo "Setting up ONLYOFFICE..."
  require_supported_distro > /dev/null || return 1
  echo "Installing ONLYOFFICE with flatpak..."
  install_flatpak_app "org.onlyoffice.desktopeditors" "ONLYOFFICE"
  echo "setup-onlyoffice complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
