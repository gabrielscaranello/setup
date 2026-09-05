#!/bin/bash

set -euo pipefail

# Follow repository conventions: source helpers and expose private functions
source "scripts/_utils.sh" 2>/dev/null || true

_clone_neovim_source() {
  local git_url="https://github.com/neovim/neovim"
  local branch="stable"
  local work_dir="$1"

  echo "Removing old build directory if it exists..."
  rm -rf "$work_dir"

  echo "Cloning Neovim..."
  git clone --depth 1 -b "$branch" "$git_url" "$work_dir" || {
    echo "Failed to clone Neovim repository" >&2
    return 1
  }
}

_build_neovim_source() {
  local work_dir="$1"
  echo "Building Neovim..."
  (
    cd "$work_dir" || return 1
    make -j"$(nproc)" CMAKE_BUILD_TYPE=RelWithDebInfo
  ) || {
    echo "Failed to build Neovim" >&2
    return 1
  }
}

_package_and_install_neovim_deb() {
  local work_dir="$1"
  echo "Packaging and installing Neovim DEB package..."
  (
    cd "$work_dir/build" || return 1
    cpack -G DEB || {
      echo "Failed to create DEB package" >&2
      return 1
    }
    sudo dpkg -i nvim-linux*.deb || {
      echo "Failed to install DEB package" >&2
      return 1
    }
  )
}

_install_neovim_from_source() {
  local work_dir="/tmp/neovim"

  echo "Installing Neovim from source (DEB package)..."
  _clone_neovim_source "$work_dir" || return 1
  _build_neovim_source "$work_dir" || return 1
  _package_and_install_neovim_deb "$work_dir" || return 1

  echo "Neovim installed successfully at $(command -v nvim)"
}

_install_neovim_from_repo() {
  echo "Installing Neovim from distribution repository..."
  install_packages neovim
}

_ensure_nvm() {
  echo "Ensuring nvm is installed (required by neovim toolchain)..."
  bash "${BASH_SOURCE[0]%/*}/setup-nvm.sh"
}

_ensure_go() {
  echo "Ensuring go is installed (required by neovim toolchain)..."
  bash "${BASH_SOURCE[0]%/*}/setup-go.sh"
}

_ensure_rust() {
  echo "Ensuring rust/cargo is installed (required for tree-sitter-cli on debian)..."
  bash "${BASH_SOURCE[0]%/*}/setup-rust.sh"
}

_install_build_deps() {
  echo "Installing build dependencies..."
  install_packages build-tools ninja-build gcc-cxx cmake gettext-tools curl git file
}

_install_neovim() {
  local pm="$1"

  case "$pm" in
  dnf | pacman)
    _install_neovim_from_repo
    ;;
  apt)
    _ensure_rust
    _install_build_deps
    _install_neovim_from_source
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

_install_runtime_deps() {
  local pm="$1"
  echo "Installing Neovim runtime dependencies and tools..."

  # Common dependencies across all distributions (resolved via packages.conf or identical package names)
  install_packages jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip

  # Distro-specific independent dependencies
  case "$pm" in
  apt)
    install_packages luarocks python3 python-venv
    ;;
  dnf)
    install_packages luarocks cargo lua-5.1
    ;;
  pacman)
    install_packages build-tools rust tree-sitter-cli luarocks
    ;;
  esac
}

main() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  _ensure_nvm
  _ensure_go
  _install_runtime_deps "$pm"
  _install_neovim "$pm"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
