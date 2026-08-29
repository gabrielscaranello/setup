#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

_install_obsidian() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  pacman)
    echo "Installing Obsidian from distribution repository..."
    install_packages obsidian
    ;;
  apt | dnf)
    echo "Installing Obsidian with flatpak..."
    install_flatpak_app "md.obsidian.Obsidian" "Obsidian"
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
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
