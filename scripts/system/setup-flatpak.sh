#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_install_flatpak_package() {
  echo "Installing flatpak package..."
  install_packages flatpak
}

_add_flathub_remote() {
  echo "Configuring Flathub remote repository..."
  local flathub_url="https://dl.flathub.org/repo/flathub.flatpakrepo"

  if flatpak remotes --columns=name 2>/dev/null | grep -qx "flathub"; then
    echo "Flathub remote is already configured, skipping."
    return 0
  fi

  echo "Adding Flathub remote repository..."
  sudo flatpak remote-add --if-not-exists flathub "$flathub_url"
  echo "Flathub remote repository added successfully."
}

_setup_flatpak() {
  _install_flatpak_package
  _add_flathub_remote
}

main() {
  echo "Setting up Flatpak and Flathub..."
  _setup_flatpak
  echo "setup-flatpak complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
