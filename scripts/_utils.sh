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
  local config_file=""

  if [ -f "scripts/packages.conf" ]; then
    config_file="scripts/packages.conf"
  elif [ -f "$(dirname "${BASH_SOURCE[0]}")/packages.conf" ]; then
    config_file="$(dirname "${BASH_SOURCE[0]}")/packages.conf"
  elif [ -f "/setup/scripts/packages.conf" ]; then
    config_file="/setup/scripts/packages.conf"
  fi

  if [ -n "$config_file" ] && [ -f "$config_file" ]; then
    local field_idx=0
    case "$package_manager" in
    apt) field_idx=2 ;;
    dnf) field_idx=3 ;;
    pacman) field_idx=4 ;;
    *) field_idx=0 ;;
    esac

    if [ "$field_idx" -gt 0 ]; then
      local matched_line
      matched_line="$(awk -F' *\\| *' -v pkg="$package" '$1 == pkg { print $0; exit }' "$config_file" 2>/dev/null || true)"
      if [ -n "$matched_line" ]; then
        local resolved_pkg
        resolved_pkg="$(echo "$matched_line" | awk -F' *\\| *' -v col="$field_idx" '{ print $col }')"
        if [ "$resolved_pkg" = "-" ]; then
          echo ""
        else
          echo "$resolved_pkg"
        fi
        return 0
      fi
    fi
  fi

  echo "$package"
}

_install_package_from_repository() {
  local package_manager="$1"
  shift

  case "$package_manager" in
  apt)
    sudo apt update -qq
    sudo apt install -y "$@"
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

get_root_filesystem() {
  findmnt -n -o FSTYPE / 2>/dev/null || df -T / 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown"
}

get_shell_profile() {
  case "${SHELL##*/}" in
  zsh)  echo "$HOME/.zshrc" ;;
  bash) echo "$HOME/.bashrc" ;;
  *)    echo "$HOME/.profile" ;;
  esac
}

install_flatpak_app() {
  local app_id="$1"
  local app_name="${2:-$app_id}"
  local script_dir

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/setup-flatpak.sh" ]; then
    bash "$script_dir/setup-flatpak.sh"
  elif [ -f "$script_dir/../setup-flatpak.sh" ]; then
    bash "$script_dir/../setup-flatpak.sh"
  fi

  if flatpak list --app --columns=application 2>/dev/null | grep -qx "$app_id"; then
    echo "$app_name (Flatpak) is already installed, skipping."
    return 0
  fi

  echo "Installing $app_name via Flatpak (Flathub)..."
  sudo flatpak install -y --noninteractive flathub "$app_id"
  echo "$app_name Flatpak installed successfully."
}

download_file() {
  local url="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "Error: Neither curl nor wget is available to download $url" >&2
    return 1
  fi
}

fetch_url() {
  local url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" 2>/dev/null || true
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$url" 2>/dev/null || true
  fi
}
