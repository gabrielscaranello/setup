#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_install_prereqs() {
  install_packages wget || true
}

_remove_firefox_esr_apt() {
  echo "Removing firefox-esr if installed..."
  sudo apt-get remove -y firefox-esr firefox-esr-l10n-pt-br 2>/dev/null || true
}

_add_mozilla_apt_repo() {
  local keyring_path="/etc/apt/keyrings/packages.mozilla.org.asc"
  local sources_path="/etc/apt/sources.list.d/mozilla.sources"

  if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
    echo "Mozilla repository already configured, skipping."
    return 0
  fi

  echo "Configuring Mozilla repository for APT..."
  sudo install -d -m 0755 /etc/apt/keyrings

  wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee "$keyring_path" >/dev/null

  cat <<EOF_SOURCES | sudo tee "$sources_path" >/dev/null
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: $keyring_path
EOF_SOURCES

  echo "Setting APT pinning priority for Mozilla repository..."
  cat <<EOF_PIN | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF_PIN

  sudo apt-get update -qq
}

_install_firefox_apt() {
  _remove_firefox_esr_apt
  _add_mozilla_apt_repo
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
    _install_prereqs
    _install_firefox_apt
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

_install_chromium() {
  echo "Installing Chromium from distribution repository..."
  install_packages chromium
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

