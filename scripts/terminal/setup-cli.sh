#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

_install_cli_tools() {
  echo "Installing CLI productivity tools..."
  install_packages bat btop eza gdu zsh zsh-completions man-db util-linux-user
}

_install_cli_session_tools() {
  echo "Installing CLI connectivity and clipboard utilities..."
  install_packages openssh dialog keychain clipboard
}

main() {
  require_supported_distro > /dev/null || return 1

  echo "Setting up CLI utilities and shell environment..."
  _install_cli_tools
  _install_cli_session_tools
  echo "setup-cli complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
