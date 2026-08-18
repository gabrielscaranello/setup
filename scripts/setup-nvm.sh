#!/bin/bash

set -e

# Follow project conventions: source utility helpers and use private functions
source "$(dirname "$0")/_utils.sh"

NODE_VERSION=24
NVM_VERSION=0.40.3
NPM_PACKAGES=(
  @github/copilot
  @styled/typescript-styled-plugin
  yarn
)

_install_prereqs() {
  # ensure basic tools for fetching/installing nvm are available
  _install_packages curl wget git || true
}

_install_nvm_script() {
  echo "Installing nvm via upstream install script..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
  else
    wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
  fi
}

_source_nvm() {
  export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    return 0
  fi

  # Arch package init hook
  if [ -f /usr/share/nvm/init-nvm.sh ]; then
    # shellcheck disable=SC1091
    . /usr/share/nvm/init-nvm.sh
    return 0
  fi

  echo "nvm not found in expected locations"
  return 1
}

_install_arch_nvm() {
  echo "Detected pacman; installing nvm package from repo..."
  # pacman-specific install (avoid using _install_packages for cross-distro names)
  _install_packages nvm
}

_install_global_packages() {
  if [ ${#NPM_PACKAGES[@]} -eq 0 ]; then
    echo "No global npm packages to install"
    return 0
  fi

  # ensure npm from installed node is in PATH
  export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"
  export PATH="$NVM_DIR/versions/node/v${NODE_VERSION}/bin:$PATH"

  echo "Installing global npm packages: ${NPM_PACKAGES[*]}"
  npm install -g "${NPM_PACKAGES[@]}"
}

main() {
  echo "Setting up NVM/Node (node ${NODE_VERSION})"

  _install_prereqs

  case "$(_get_package_manager)" in
  pacman)
    _install_arch_nvm
    ;;
  apt | dnf)
    _install_nvm_script
    ;;
  *)
    echo "Unsupported package manager" >&2
    return 1
    ;;
  esac

  _source_nvm

  echo "Installing Node ${NODE_VERSION} via nvm"
  nvm install "${NODE_VERSION}"
  nvm alias default "${NODE_VERSION}"

  echo "Enabling corepack"
  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  else
    if command -v node >/dev/null 2>&1; then
      node -e "try{require('child_process').execSync('corepack enable',{stdio:'inherit'})}catch(e){}"
    fi
  fi

  _install_global_packages

  echo "setup-nvm complete"
}

main "$@"
