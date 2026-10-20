#!/bin/bash

# System Packages & Repositories Update Script
# Refreshes package manager repositories and performs a full system upgrade
# across supported distributions (Debian 13, Fedora 44, Arch Linux).

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

main() {
  echo "Starting system update and upgrade..."

  if [ "${UPDATE_SKIP_SYSTEM_UPGRADE:-0}" = "1" ]; then
    echo "UPDATE_SKIP_SYSTEM_UPGRADE is active. Skipping system upgrade."
    echo "setup-update complete"
    return 0
  fi

  require_supported_distro > /dev/null || return 1
  upgrade_system

  echo "setup-update complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
