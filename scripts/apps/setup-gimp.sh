#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_gimp() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    fedora | arch | opensuse-tumbleweed)
      echo "Installing GIMP from distribution repository..."
      install_packages gimp
      ;;
    debian | opensuse | opensuse-leap)
      echo "Installing GIMP with flatpak..."
      install_flatpak_app "org.gimp.GIMP" "GIMP"

      if [ "$distro" = "debian" ]; then
        if dpkg -s gimp > /dev/null 2>&1; then
          echo "Removing native GIMP from Debian to prevent duplicate launchers..."
          sudo apt purge -y gimp 2> /dev/null || true
        fi
      elif [ "$distro" != "opensuse-tumbleweed" ]; then
        if rpm -q gimp > /dev/null 2>&1; then
          echo "Removing native GIMP from openSUSE Leap to prevent duplicate launchers..."
          sudo zypper --non-interactive remove -u gimp 2> /dev/null || true
          sudo zypper --non-interactive addlock gimp 2> /dev/null || true
        fi
      fi
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
