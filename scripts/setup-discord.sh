#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_install_discord_flatpak() {
  echo "Ensuring Flatpak and Flathub are configured..."
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/setup-flatpak.sh" ]; then
    bash "$script_dir/setup-flatpak.sh"
  fi

  if flatpak list --app --columns=application 2>/dev/null | grep -qx "com.discordapp.Discord"; then
    echo "Discord (Flatpak) is already installed, skipping."
    return 0
  fi

  echo "Installing Discord via Flatpak (Flathub)..."
  sudo flatpak install -y --noninteractive flathub com.discordapp.Discord
  echo "Discord Flatpak installed successfully."
}

_install_discord_repo() {
  echo "Installing Discord from distribution repository..."
  install_packages discord
}

_install_discord() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  pacman)
    _install_discord_repo
    ;;
  apt | dnf)
    _install_discord_flatpak
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up Discord..."
  _install_discord
  echo "setup-discord complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
