#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true

NODE_VERSION=24
NVM_VERSION=0.40.3
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh"

# Package managers to install globally via corepack
COREPACK_PACKAGES=("yarn@1")

# Regular packages to install globally via npm
NPM_PACKAGES=("@github/copilot" "@styled/typescript-styled-plugin")

_install_nvm_script() {
  echo "Installing nvm via upstream install script..."
  # NVM_PROFILE=/dev/null prevents the installer from auto-modifying shell profile
  # files — we handle that ourselves idempotently in _setup_shell_profile
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$NVM_INSTALL_URL" | NVM_PROFILE=/dev/null bash
  else
    wget -qO- "$NVM_INSTALL_URL" | NVM_PROFILE=/dev/null bash
  fi
}

_setup_shell_profile() {
  local profile
  profile="$(get_shell_profile)"

  if grep -q 'NVM_DIR' "$profile" 2>/dev/null; then
    echo "nvm already configured in $profile, skipping"
    return 0
  fi

  echo "Adding nvm init to $profile..."
  cat >> "$profile" << 'EOF'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
}

_source_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
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
  # pacman-specific install (avoid using install_packages for cross-distro names)
  install_packages nvm
}

_enable_corepack() {
  echo "Enabling corepack"
  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  elif command -v node >/dev/null 2>&1; then
    node -e "try{require('child_process').execSync('corepack enable',{stdio:'inherit'})}catch(e){}"
  fi
}

_install_corepack_packages() {
  if [ ${#COREPACK_PACKAGES[@]} -eq 0 ]; then
    echo "No corepack packages to install"
    return 0
  fi

  echo "Installing corepack packages: ${COREPACK_PACKAGES[*]}"
  for pkg in "${COREPACK_PACKAGES[@]}"; do
    corepack install -g "$pkg"
  done
}

_install_npm_packages() {
  if [ ${#NPM_PACKAGES[@]} -eq 0 ]; then
    echo "No global npm packages to install"
    return 0
  fi

  echo "Installing global npm packages: ${NPM_PACKAGES[*]}"
  nvm exec "${NODE_VERSION}" npm install -g "${NPM_PACKAGES[@]}"
}

_install_node() {
  echo "Installing Node ${NODE_VERSION} via nvm"
  nvm install "${NODE_VERSION}"
  nvm alias default "${NODE_VERSION}"
}

_install_nvm() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
  arch)
    _install_arch_nvm
    ;;
  debian | fedora)
    _install_nvm_script
    ;;
  *)
    echo "Unsupported distribution: $distro" >&2
    return 1
    ;;
  esac
}

main() {
  echo "Setting up NVM/Node (node ${NODE_VERSION}, nvm ${NVM_VERSION})..."

  install_packages curl wget git || true
  _install_nvm
  _setup_shell_profile
  _source_nvm
  _install_node
  _enable_corepack
  _install_corepack_packages
  _install_npm_packages

  echo "setup-nvm complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
