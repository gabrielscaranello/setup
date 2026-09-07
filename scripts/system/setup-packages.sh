#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2> /dev/null || true

_install_cli_tools() {
  echo "Installing CLI productivity tools..."
  install_packages bat btop eza gdu zsh zsh-completions man-db util-linux-user
}

_install_hardware_tools() {
  echo "Installing hardware, energy, and firmware tools..."
  install_packages power-profiles-daemon numlockx fwupd
}

_install_filesystem_tools() {
  echo "Installing filesystem compatibility tools..."
  install_packages dosfstools mtools ntfs-3g
}

_install_session_tools() {
  echo "Installing XDG standards, connectivity, and session utilities..."
  install_packages xdg-user-dirs xdg-utils openssh dialog keychain
}

_install_spelling_dictionaries() {
  echo "Installing spelling dictionaries..."
  install_packages spell-pt-br spell-en
}

_initialize_xdg_dirs() {
  if command -v xdg-user-dirs-update > /dev/null 2>&1; then
    echo "Initializing XDG user directories..."
    xdg-user-dirs-update || true
  fi
}

main() {
  echo "Setting up core system packages..."
  _install_cli_tools
  _install_hardware_tools
  _install_filesystem_tools
  _install_session_tools
  _install_spelling_dictionaries
  _initialize_xdg_dirs
  echo "setup-packages complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
