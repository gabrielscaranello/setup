#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_obsidian() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    arch)
      echo "Installing Obsidian from distribution repository..."
      install_packages obsidian
      ;;
    debian | fedora)
      echo "Installing Obsidian with flatpak..."
      install_flatpak_app "md.obsidian.Obsidian" "Obsidian"
      ;;
  esac
}

main() {
  echo "Setting up Obsidian..."
  _install_obsidian
  echo "setup-obsidian complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
