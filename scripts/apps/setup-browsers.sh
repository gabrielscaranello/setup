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
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  fedora | arch)
    _install_firefox_repo
    ;;
  debian)
    install_packages wget || true
    _install_firefox_apt
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
    return 1
    ;;
  esac
}

_install_chromium() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  fedora | arch)
    echo "Installing Chromium from distribution repository..."
    install_packages chromium
    ;;
  debian)
    echo "Installing Chromium with flatpak..."
    install_flatpak_app "org.chromium.Chromium" "Chromium"
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
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
