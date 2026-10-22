#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_gh() {
  if ! is_wsl; then
    echo "GitHub CLI setup is restricted to WSL environments, skipping."
    return 0
  fi

  require_supported_distro > /dev/null || return 1

  echo "Installing GitHub CLI from distribution repository..."
  install_packages github-cli
}

main() {
  echo "Setting up GitHub CLI..."
  _install_gh
  echo "setup-gh complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
