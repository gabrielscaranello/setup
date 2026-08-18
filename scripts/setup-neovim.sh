#!/bin/bash

set -e

# Follow repository conventions: source helpers and expose private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_install_neovim_from_source() {
  local git_url="https://github.com/neovim/neovim"
  local branch="stable"
  local work_dir="/tmp/neovim"
  local arch
  arch="$(uname -m)"

  echo "Installing Neovim from source (DEB package)..."

  echo "Removing old files if exists..."
  rm -rf "$work_dir"

  echo "Cloning Neovim..."
  git clone --depth 1 -b "$branch" "$git_url" "$work_dir" || {
    echo "Failed to clone Neovim repository" >&2
    return 1
  }

  echo "Building Neovim..."
  cd "$work_dir" || return 1
  make CMAKE_BUILD_TYPE=RelWithDebInfo || {
    echo "Failed to build Neovim" >&2
    return 1
  }

  echo "Packaging and installing Neovim DEB package..."
  cd build || return 1
  cpack -G DEB || {
    echo "Failed to create DEB package" >&2
    return 1
  }

  sudo dpkg -i nvim-linux-"$arch".deb || {
    echo "Failed to install DEB package" >&2
    return 1
  }

  echo "Neovim installed successfully at $(which nvim)"
}

_install_neovim_from_repo() {
  echo "Installing Neovim from distribution repository..."
  _install_packages neovim
}

_main_install_nvm() {
  # Ensure nvm is installed as an indirect dependency of Neovim
  local script_dir
  script_dir="$(dirname "$0")"
  if [ -x "$script_dir/setup-nvm.sh" ]; then
    echo "Ensuring nvm is installed (required by neovim toolchain)..."
    "$script_dir/setup-nvm.sh" || {
      echo "setup-nvm failed" >&2
      return 1
    }
  else
    echo "setup-nvm.sh not found or not executable; attempting to run it with bash"
    bash "$script_dir/setup-nvm.sh" || {
      echo "setup-nvm failed" >&2
      return 1
    }
  fi
}

main() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  # nvm is a dependency of the Neovim environment; ensure it is present
  _main_install_nvm

  case "$pm" in
  dnf | pacman)
    echo "Using distro package manager ($pm) to install Neovim"
    _install_neovim_from_repo
    ;;
  apt)
    echo "Installing build dependencies..."
    _install_packages build-tools ninja-build gcc-cxx cmake gettext-tools curl git
    _install_neovim_from_source
    ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac
}

main "$@"
