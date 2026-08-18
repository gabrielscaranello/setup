#!/bin/bash

_get_package_manager() {
  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    return 1
  fi
}

_get_package_name() {
  package="$1"
  package_manager="$2"

  case "$package" in
  build-tools)
    case "$package_manager" in
    apt) echo "build-essential" ;;
    dnf) echo "@development-tools" ;;
    pacman) echo "base-devel" ;;
    esac
    ;;

  ninja-build)
    case "$package_manager" in
    apt) echo "ninja-build" ;;
    dnf) echo "ninja-build" ;;
    pacman) echo "ninja" ;;
    esac
    ;;

  gcc-cxx)
    case "$package_manager" in
    apt) echo "g++" ;;
    dnf) echo "gcc-c++" ;;
    pacman) echo "gcc" ;;
    esac
    ;;

  gettext-tools)
    case "$package_manager" in
    apt) echo "gettext" ;;
    dnf) echo "gettext-devel" ;;
    pacman) echo "gettext" ;;
    esac
    ;;

  *)
    echo "$package"
    ;;
  esac
}

_install_package_from_repository() {
  package="$1"
  package_manager="$2"

  case "$package_manager" in
  apt)
    sudo apt install -y "$package"
    ;;

  dnf)
    sudo dnf install -y "$package"
    ;;

  pacman)
    sudo pacman -S --needed --noconfirm "$package"
    ;;

  *)
    echo "Unsupported package manager: $package_manager" >&2
    return 1
    ;;
  esac
}

_install_package() {
  package="$1"
  package_manager="$2"

  package_name="$(_get_package_name "$package" "$package_manager")"

  _install_package_from_repository \
    "$package_name" \
    "$package_manager"
}

_install_packages() {
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  echo "Using package manager: $package_manager"

  for package in "$@"; do
    echo "Installing: $package"

    _install_package "$package" "$package_manager" || {
      echo "Failed to install: $package" >&2
      return 1
    }
  done
}
