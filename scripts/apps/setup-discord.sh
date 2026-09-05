#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_discord() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    arch)
      echo "Installing Discord from distribution repository..."
      install_packages discord
      ;;
    debian | fedora)
      echo "Installing Discord with flatpak..."
      install_flatpak_app "com.discordapp.Discord" "Discord"
      ;;
    *)
      echo "Unsupported distribution: $distro" >&2
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
