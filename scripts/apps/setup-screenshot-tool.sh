#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_screenshot_tool() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    debian | fedora | arch) ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac

  local de
  de="$(get_desktop_environment)"

  case "$de" in
    gnome)
      echo "Installing Flameshot for GNOME..."
      install_packages flameshot
      ;;
    plasma)
      echo "Installing Spectacle for KDE Plasma..."
      install_packages spectacle
      ;;
    *)
      echo "Unrecognized desktop environment: $de. Skipping screenshot tool setup."
      return 0
      ;;
  esac
}

main() {
  echo "Setting up screenshot tool..."
  _install_screenshot_tool
  echo "setup-screenshot complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
