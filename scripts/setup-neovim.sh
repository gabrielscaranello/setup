#!/bin/bash

set -euo pipefail

# Follow repository conventions: source helpers and expose private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_install_neovim_from_source() {
  local git_url="https://github.com/neovim/neovim"
  local branch="stable"
  local work_dir="/tmp/neovim"

  echo "Installing Neovim from source (DEB package)..."

  echo "Removing old build directory if it exists..."
  rm -rf "$work_dir"

  echo "Cloning Neovim..."
  git clone --depth 1 -b "$branch" "$git_url" "$work_dir" || {
    echo "Failed to clone Neovim repository" >&2
    return 1
  }

  echo "Building Neovim..."
  cd "$work_dir" || return 1
  make -j"$(nproc)" CMAKE_BUILD_TYPE=RelWithDebInfo || {
    echo "Failed to build Neovim" >&2
    return 1
  }

  echo "Packaging and installing Neovim DEB package..."
  cd build || return 1
  cpack -G DEB || {
    echo "Failed to create DEB package" >&2
    return 1
  }

  sudo dpkg -i nvim-linux*.deb || {
    echo "Failed to install DEB package" >&2
    return 1
  }

  echo "Neovim installed successfully at $(command -v nvim)"
}

_install_neovim_from_repo() {
  echo "Installing Neovim from distribution repository..."
  install_packages neovim
}

_ensure_nvm() {
  echo "Ensuring nvm is installed (required by neovim toolchain)..."
  bash "scripts/setup-nvm.sh" 2>/dev/null || bash "$(dirname "$0")/setup-nvm.sh"
}

_install_build_deps() {
  echo "Installing build dependencies..."
  install_packages build-tools ninja-build gcc-cxx cmake gettext-tools curl git file
}

_install_neovim() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  dnf | pacman)
    _install_neovim_from_repo
    ;;
  apt)
    _install_build_deps
    _install_neovim_from_source
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main() {
  _ensure_nvm
  _install_neovim
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
