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

  golang)
    case "$package_manager" in
    pacman) echo "go" ;;
    *) echo "golang" ;;
    esac
    ;;

  fontconfig)
    echo "fontconfig"
    ;;

  fonts-jetbrains-mono-nerd)
    case "$package_manager" in
    pacman) echo "ttf-jetbrains-mono-nerd" ;;
    *) echo "" ;;
    esac
    ;;

  fonts-liberation)
    case "$package_manager" in
    apt) echo "fonts-liberation" ;;
    pacman) echo "ttf-liberation" ;;
    dnf) echo "" ;;
    esac
    ;;

  fonts-roboto)
    case "$package_manager" in
    apt) echo "fonts-roboto" ;;
    dnf) echo "google-roboto-fonts" ;;
    pacman) echo "ttf-roboto" ;;
    esac
    ;;

  fonts-carlito)
    case "$package_manager" in
    pacman) echo "ttf-carlito" ;;
    *) echo "" ;;
    esac
    ;;

  fonts-noto)
    case "$package_manager" in
    pacman) echo "noto-fonts" ;;
    *) echo "" ;;
    esac
    ;;

  fonts-noto-color-emoji)
    case "$package_manager" in
    apt) echo "fonts-noto-color-emoji" ;;
    pacman) echo "noto-fonts-emoji" ;;
    dnf) echo "" ;;
    esac
    ;;

  firefox)
    echo "firefox"
    ;;

  firefox-i18n-pt-br)
    case "$package_manager" in
    apt) echo "firefox-l10n-pt-br" ;;
    pacman) echo "firefox-i18n-pt-br" ;;
    dnf) echo "" ;;
    esac
    ;;

  docker)
    case "$package_manager" in
    apt) echo "docker.io" ;;
    dnf) echo "docker-ce docker-ce-cli" ;;
    pacman) echo "docker" ;;
    esac
    ;;

  docker-compose)
    case "$package_manager" in
    apt) echo "docker-compose" ;;
    dnf) echo "docker-compose-plugin" ;;
    pacman) echo "docker-compose" ;;
    esac
    ;;

  docker-buildx)
    case "$package_manager" in
    dnf) echo "docker-buildx-plugin" ;;
    pacman) echo "docker-buildx" ;;
    apt) echo "" ;;
    esac
    ;;

  containerd)
    case "$package_manager" in
    dnf) echo "containerd.io" ;;
    *) echo "" ;;
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
    sudo pacman -Sy --needed --noconfirm "$@"
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
  local resolved
  for package in "$@"; do
    resolved="$(_get_package_name "$package" "$package_manager")"
    if [ -n "$resolved" ]; then
      for item in $resolved; do
        resolved_packages+=("$item")
      done
    fi
  done

  if [ ${#resolved_packages[@]} -eq 0 ]; then
    echo "No packages to install for $package_manager"
    return 0
  fi

  echo "Installing: ${resolved_packages[*]}"

  _install_package_from_repository "$package_manager" "${resolved_packages[@]}"
}
