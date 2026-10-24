#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_remove_firefox_esr_apt() {
  echo "Removing firefox-esr if installed..."
  remove_packages firefox-esr firefox-esr-l10n-pt-br 2> /dev/null || true
}

_remove_firefox_esr_opensuse() {
  echo "Removing firefox-esr if installed on openSUSE..."
  remove_packages MozillaFirefox-esr firefox-esr 2> /dev/null || true
}

_install_firefox_apt() {
  _remove_firefox_esr_apt
  declare -F add_debian_mozilla_repo > /dev/null 2>&1 || source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
  add_debian_mozilla_repo
  install_packages firefox firefox-i18n-pt-br
}

_install_firefox_opensuse_leap() {
  _remove_firefox_esr_opensuse
  declare -F add_opensuse_mozilla_repo > /dev/null 2>&1 || source "scripts/system/opensuse/_repositories.sh" 2> /dev/null || true
  add_opensuse_mozilla_repo
  install_packages firefox firefox-i18n-pt-br
}

_install_firefox_repo() {
  echo "Installing Firefox from distribution repository..."
  install_packages firefox firefox-i18n-pt-br 2> /dev/null || install_packages firefox
}

_install_firefox() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    fedora | arch | linuxmint)
      _install_firefox_repo
      ;;
    debian)
      install_packages wget || true
      _install_firefox_apt
      ;;
    opensuse-tumbleweed)
      echo "Firefox is default on openSUSE Tumbleweed, skipping installation."
      ;;
    opensuse | opensuse-leap)
      _install_firefox_opensuse_leap
      ;;
  esac
}

_install_chromium() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    fedora | arch | opensuse*)
      echo "Installing Chromium from distribution repository..."
      install_packages chromium
      ;;
    debian | linuxmint)
      echo "Installing Chromium with flatpak..."
      install_flatpak_app "org.chromium.Chromium" "Chromium"
      ;;
  esac
}

main() {
  echo "Setting up browsers..."
  _install_chromium
  _install_firefox
  echo "setup-browsers complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
