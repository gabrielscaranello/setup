#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true
source "scripts/system/debian/_repositories.sh" 2>/dev/null || true

_remove_firefox_esr_apt() {
  echo "Removing firefox-esr if installed..."
  sudo apt remove -y firefox-esr firefox-esr-l10n-pt-br 2>/dev/null || true
}

_install_firefox_apt() {
  _remove_firefox_esr_apt
  add_debian_mozilla_repo
  install_packages firefox firefox-i18n-pt-br
}

_install_firefox_repo() {
  echo "Installing Firefox from distribution repository..."
  install_packages firefox firefox-i18n-pt-br
}

_install_firefox() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    _install_firefox_repo
    ;;
  apt)
    install_packages wget || true
    _install_firefox_apt
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

_install_chromium() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    echo "Installing Chromium from distribution repository..."
    install_packages chromium
    ;;
  apt)
    echo "Installing Chromium with flatpak..."
    install_flatpak_app "org.chromium.Chromium" "Chromium"
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

_install_browsers() {
  _install_chromium
  _install_firefox
}

main() {
  echo "Setting up browsers..."
  _install_browsers
  echo "setup-browsers complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
