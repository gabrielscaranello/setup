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

_configure_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh 2> /dev/null || true)"
  if [ -z "$zsh_path" ]; then
    return 0
  fi

  local target_user="${USER:-$(id -un 2> /dev/null || echo "")}"
  if [ -n "$target_user" ]; then
    local current_shell=""
    if [ -f "${PASSWD_PATH:-/etc/passwd}" ]; then
      current_shell="$(awk -F: -v u="$target_user" '$1 == u {print $7}' "${PASSWD_PATH:-/etc/passwd}" 2> /dev/null || true)"
    fi
    if [ "$current_shell" != "$zsh_path" ]; then
      echo "Configuring Zsh ($zsh_path) as default login shell for $target_user..."
      if command -v usermod > /dev/null 2>&1; then
        sudo usermod -s "$zsh_path" "$target_user" 2> /dev/null || true
      elif command -v chsh > /dev/null 2>&1; then
        sudo chsh -s "$zsh_path" "$target_user" 2> /dev/null || true
      fi
    fi
  fi

  export SHELL="$zsh_path"
}

main() {
  require_supported_distro > /dev/null || return 1

  echo "Setting up CLI utilities and shell environment..."
  _install_cli_tools
  _install_cli_session_tools
  _configure_default_shell
  echo "setup-cli complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
