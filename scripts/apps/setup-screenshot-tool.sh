#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_configure_flameshot_portal_permission() {
  if command -v dbus-send > /dev/null 2>&1; then
    dbus-send --session \
      --dest=org.freedesktop.impl.portal.PermissionStore \
      /org/freedesktop/impl/portal/PermissionStore \
      org.freedesktop.impl.portal.PermissionStore.SetPermission \
      string:'screenshot' boolean:true string:'screenshot' \
      string:'org.flameshot.Flameshot' array:string:'yes' 2> /dev/null || true
  fi
}

_install_screenshot_tool() {
  require_supported_distro > /dev/null || return 1

  local de
  de="$(get_desktop_environment)"

  case "$de" in
    gnome)
      echo "Installing Flameshot for GNOME..."
      install_packages flameshot
      echo "Configuring Flameshot portal permissions..."
      _configure_flameshot_portal_permission
      ;;
    cinnamon)
      echo "Installing Flameshot for Cinnamon..."
      install_packages flameshot
      echo "Configuring Flameshot portal permissions..."
      _configure_flameshot_portal_permission
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
