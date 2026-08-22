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
  local package="$1"
  local package_manager="$2"

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
    pacman) echo "ninja" ;;
    *) echo "ninja-build" ;;
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
    dnf) echo "gettext-devel" ;;
    *) echo "gettext" ;;
    esac
    ;;

  libclang)
    case "$package_manager" in
    apt) echo "libclang-dev" ;;
    dnf) echo "clang-devel" ;;
    pacman) echo "clang" ;;
    esac
    ;;

  *)
    echo "$package"
    ;;
  esac
}

_install_package_from_repository() {
  local package_manager="$1"
  shift

  case "$package_manager" in
  apt)
    sudo apt-get update -qq
    sudo apt-get install -y "$@"
    ;;

  dnf)
    sudo dnf install -y "$@"
    ;;

  pacman)
    sudo pacman -S --needed --noconfirm "$@"
    ;;

  *)
    echo "Unsupported package manager: $package_manager" >&2
    return 1
    ;;
  esac
}

install_packages() {
  local package_manager
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  echo "Using package manager: $package_manager"

  local resolved_packages=()
  local package
  for package in "$@"; do
    resolved_packages+=("$(_get_package_name "$package" "$package_manager")")
  done

  echo "Installing: ${resolved_packages[*]}"

  _install_package_from_repository "$package_manager" "${resolved_packages[@]}"
}
