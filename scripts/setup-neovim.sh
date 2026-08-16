#! /bin/bash

set -e

_install_neovim_from_source() {
  local git_url="https://github.com/neovim/neovim"
  local branch="stable"
  local work_dir="/tmp/neovim"
  local package_manager
  package_manager="$(_get_package_manager)"

  echo "Installing Neovim from source..."

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

  echo "Installing Neovim..."
  if [ "$package_manager" = "apt" ]; then
    local arch
    arch="$(uname -m)"
    
    cd build || return 1
    cpack -G DEB || {
      echo "Failed to create DEB package" >&2
      return 1
    }
    
    sudo dpkg -i nvim-linux-"$arch".deb || {
      echo "Failed to install DEB package" >&2
      return 1
    }
  else
    sudo make install || {
      echo "Failed to install Neovim" >&2
      return 1
    }
  fi

  echo "Neovim installed successfully at $(which nvim)"
}

source "$(dirname "$0")/_utils.sh"

echo "Installing Neovim dependencies..."
_install_packages build-tools ninja-build gcc-cxx cmake gettext-tools curl git

_install_neovim_from_source

