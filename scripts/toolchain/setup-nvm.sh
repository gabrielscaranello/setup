#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

NODE_VERSION=24
NVM_VERSION=0.40.3
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh"

# Package managers to install globally via corepack
COREPACK_PACKAGES=("yarn@1")

# Regular packages to install globally via npm
NPM_PACKAGES=("@github/copilot" "@styled/typescript-styled-plugin")

_resolve_nvm_dir() {
  if [ -n "${NVM_DIR:-}" ] && [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "$NVM_DIR"
    return 0
  fi

  local xdg_nvm="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
  if [ -s "$xdg_nvm/nvm.sh" ]; then
    echo "$xdg_nvm"
    return 0
  fi

  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "$HOME/.nvm"
    return 0
  fi

  # Distribution package (Arch) ships nvm.sh under /usr/share/nvm and uses ~/.nvm as data dir
  if [ -s /usr/share/nvm/nvm.sh ]; then
    echo "${NVM_DIR:-$HOME/.nvm}"
    return 0
  fi

  if [ -n "${NVM_DIR:-}" ]; then
    echo "$NVM_DIR"
    return 0
  fi

  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    echo "${XDG_CONFIG_HOME}/nvm"
  elif [ -d "$HOME/.config" ]; then
    echo "$HOME/.config/nvm"
  else
    echo "$HOME/.nvm"
  fi
}

_install_nvm_script() {
  echo "Installing nvm via upstream install script..."
  local nvm_dir
  nvm_dir="$(_resolve_nvm_dir)"
  mkdir -p "$nvm_dir"
  export NVM_DIR="$nvm_dir"

  # PROFILE=/dev/null (and NVM_PROFILE=/dev/null) prevents the installer from auto-modifying shell profile
  # files — we handle that ourselves idempotently in _setup_shell_profile
  fetch_url "$NVM_INSTALL_URL" | PROFILE=/dev/null NVM_PROFILE=/dev/null bash
}

_setup_shell_profile() {
  local profile
  profile="$(get_shell_profile)"

  if grep -q 'NVM_DIR' "$profile" 2> /dev/null; then
    echo "nvm already configured in $profile, skipping"
    return 0
  fi

  local nvm_dir
  nvm_dir="$(_resolve_nvm_dir)"

  echo "Adding nvm init to $profile..."
  cat >> "$profile" << EOF

# nvm
export NVM_DIR="$nvm_dir"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"
EOF

  # Distribution package (Arch) provides its own init hook instead of $NVM_DIR/nvm.sh
  if [ -s /usr/share/nvm/init-nvm.sh ]; then
    echo '[ -s /usr/share/nvm/init-nvm.sh ] && \. /usr/share/nvm/init-nvm.sh' >> "$profile"
  fi
}

_source_nvm() {
  local nvm_dir
  nvm_dir="$(_resolve_nvm_dir)"
  export NVM_DIR="$nvm_dir"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    return 0
  fi

  local xdg_nvm="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
  if [ -s "$xdg_nvm/nvm.sh" ]; then
    export NVM_DIR="$xdg_nvm"
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    return 0
  fi

  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
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

_install_nvm() {
  local distro
  distro="$(require_supported_distro)" || return 1

  case "$distro" in
    arch)
      echo "Detected pacman; installing nvm package from repo..."
      install_packages nvm
      ;;
    debian | fedora | opensuse*)
      _install_nvm_script
      ;;
  esac
}

_enable_corepack() {
  echo "Enabling corepack"
  if command -v corepack > /dev/null 2>&1; then
    corepack enable
  elif command -v node > /dev/null 2>&1; then
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

  local missing_pkgs=()
  local installed_list
  installed_list="$(nvm exec "${NODE_VERSION}" npm list -g --depth=0 2> /dev/null || true)"
  for pkg in "${NPM_PACKAGES[@]}"; do
    if echo "$installed_list" | grep -qF " ${pkg}@"; then
      echo "$pkg already installed, skipping"
    else
      missing_pkgs+=("$pkg")
    fi
  done

  if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo "Installing global npm packages: ${missing_pkgs[*]}"
    nvm exec "${NODE_VERSION}" npm install -g "${missing_pkgs[@]}"
  fi
}

_install_node() {
  if nvm ls "${NODE_VERSION}" 2> /dev/null | grep -q "v${NODE_VERSION}\."; then
    echo "Node ${NODE_VERSION} is already installed via nvm, ensuring default alias"
    nvm alias default "${NODE_VERSION}"
    return 0
  fi
  echo "Installing Node ${NODE_VERSION} via nvm"
  nvm install "${NODE_VERSION}"
  nvm alias default "${NODE_VERSION}"
}

main() {
  echo "Setting up NVM/Node (node ${NODE_VERSION}, nvm ${NVM_VERSION})..."

  install_packages curl wget git findutils || true
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
