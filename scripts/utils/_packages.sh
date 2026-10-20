#!/bin/bash

# Package Resolution and Installation Utilities
# Resolves package names across Debian, Fedora, and Arch Linux using packages.conf
# and dispatches idempotent installations via native package managers or Flatpak.

_get_package_manager() {
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"
  case "$distro" in
    debian)
      echo "apt"
      return 0
      ;;
    fedora)
      echo "dnf"
      return 0
      ;;
    arch)
      echo "pacman"
      return 0
      ;;
    opensuse*)
      echo "zypper"
      return 0
      ;;
  esac

  if command -v dnf > /dev/null 2>&1; then
    echo "dnf"
  elif command -v apt > /dev/null 2>&1; then
    echo "apt"
  elif command -v pacman > /dev/null 2>&1; then
    echo "pacman"
  elif command -v zypper > /dev/null 2>&1; then
    echo "zypper"
  else
    return 1
  fi
}

_get_package_name() {
  local package="$1"
  local target="${2:-}"
  if [ -z "$target" ]; then
    target="$(get_distro_id 2> /dev/null || _get_package_manager 2> /dev/null || true)"
  fi
  local config_file=""
  local repo_root
  repo_root="$(get_repo_root)"
  if [ -f "${repo_root}/scripts/packages.conf" ]; then
    config_file="${repo_root}/scripts/packages.conf"
  elif [ -f "scripts/packages.conf" ]; then
    config_file="scripts/packages.conf"
  fi

  if [ -n "$config_file" ] && [ -f "$config_file" ]; then
    local field_idx=0
    case "$target" in
      debian | apt) field_idx=2 ;;
      fedora | dnf) field_idx=3 ;;
      arch | pacman) field_idx=4 ;;
      opensuse* | zypper) field_idx=5 ;;
      *) field_idx=0 ;;
    esac

    if [ "$field_idx" -gt 0 ]; then
      local matched_line
      matched_line="$(awk -F' *\\| *' -v pkg="$package" '$1 == pkg { print $0; exit }' "$config_file" 2> /dev/null || true)"
      if [ -n "$matched_line" ]; then
        local resolved_pkg
        resolved_pkg="$(echo "$matched_line" | awk -F' *\\| *' -v col="$field_idx" '{ print $col }')"
        if [ "$resolved_pkg" = "-" ]; then
          echo ""
          return 0
        elif [ -n "$resolved_pkg" ]; then
          echo "$resolved_pkg"
          return 0
        fi
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
      # Refresh the APT index only once per process to keep repeated installs fast
      if [ "${_APT_INDEX_REFRESHED:-0}" != "1" ]; then
        sudo apt update -qq
        _APT_INDEX_REFRESHED=1
      fi
      sudo apt install -y "$@"
      ;;

    dnf)
      sudo dnf install -y --allowerasing "$@"
      ;;

    pacman)
      # Sync and upgrade in the same transaction: syncing alone (-Sy) causes unsupported
      # partial upgrades on Arch, while skipping the sync (-S) fails on stale databases (404s).
      sudo pacman -Syu --needed --noconfirm "$@"
      ;;

    zypper)
      sudo zypper --non-interactive --gpg-auto-import-keys install -y --allow-vendor-change --force-resolution --no-recommends "$@"
      ;;

    *)
      echo "Unsupported package manager: $package_manager" >&2
      return 1
      ;;
  esac
}

install_packages() {
  local package_manager distro
  distro="$(get_distro_id 2> /dev/null || echo "unknown")"
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  echo "Using package manager: $package_manager (distribution: $distro)"

  local resolved_packages=()
  local package
  local resolved item
  for package in "$@"; do
    resolved="$(_get_package_name "$package" "$distro")"
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

# Removes native packages using the distribution package manager.
# Package names are NOT resolved through packages.conf (callers pass native names).
# Usage: remove_packages [--autoremove] <native_pkg>...
remove_packages() {
  local autoremove=0
  if [ "${1:-}" = "--autoremove" ]; then
    autoremove=1
    shift
  fi

  [ $# -gt 0 ] || return 0

  local package_manager
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$package_manager" in
    apt)
      sudo apt purge -y "$@"
      [ "$autoremove" -eq 0 ] || sudo apt autoremove --purge -y
      ;;
    dnf)
      sudo dnf remove -y "$@"
      [ "$autoremove" -eq 0 ] || sudo dnf autoremove -y
      ;;
    pacman)
      sudo pacman -Rns --noconfirm "$@"
      ;;
    zypper)
      sudo zypper --non-interactive remove -u "$@"
      ;;
    *)
      echo "Unsupported package manager: $package_manager" >&2
      return 1
      ;;
  esac
}

# Prevents removed packages from being reinstalled as dependencies.
# Only zypper supports package locks in this project; it is a no-op elsewhere.
# Usage: lock_packages <native_pkg>...
lock_packages() {
  [ $# -gt 0 ] || return 0
  if [ "$(_get_package_manager 2> /dev/null || true)" = "zypper" ]; then
    sudo zypper --non-interactive addlock "$@"
  fi
}

# Refreshes package repositories and upgrades every installed package.
# Usage: upgrade_system
upgrade_system() {
  local package_manager distro
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }
  distro="$(get_distro_id 2> /dev/null || true)"

  echo "Refreshing ${package_manager} repositories and upgrading packages..."
  case "$package_manager" in
    apt)
      sudo apt update
      sudo apt upgrade -y
      ;;
    dnf)
      sudo dnf upgrade -y --refresh
      ;;
    pacman)
      sudo pacman -Syu --noconfirm
      ;;
    zypper)
      sudo zypper --non-interactive refresh
      if [ "$distro" = "opensuse-tumbleweed" ]; then
        sudo zypper --non-interactive dup --no-recommends
      else
        sudo zypper --non-interactive up --no-recommends
      fi
      ;;
    *)
      echo "Unsupported package manager: $package_manager" >&2
      return 1
      ;;
  esac
}

install_flatpak_app() {
  local app_id="$1"
  local app_name="${2:-$app_id}"
  # Fast-path: check if flatpak is installed and flathub remote is already configured
  if ! command -v flatpak > /dev/null 2>&1 || ! flatpak remotes --columns=name 2> /dev/null | grep -qx "flathub"; then
    local flatpak_script
    flatpak_script="$(get_repo_root)/scripts/system/setup-flatpak.sh"
    if [ -f "$flatpak_script" ]; then
      bash "$flatpak_script"
    fi
  fi

  if flatpak list --columns=application 2> /dev/null | grep -qx "$app_id"; then
    echo "$app_name (Flatpak) is already installed, updating to latest version..."
    sudo flatpak update -y --noninteractive "$app_id" 2> /dev/null || true
    return 0
  fi

  echo "Installing $app_name via Flatpak (Flathub)..."
  sudo flatpak install -y --noninteractive flathub "$app_id"
  echo "$app_name Flatpak installed successfully."
}

is_package_installed() {
  local package="$1"
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"
  local resolved
  resolved="$(_get_package_name "$package" "$distro" 2> /dev/null || echo "$package")"

  if [ -z "$resolved" ]; then
    return 1
  fi

  local item
  for item in $resolved; do
    case "$distro" in
      debian)
        dpkg -s "$item" > /dev/null 2>&1 || return 1
        ;;
      fedora | opensuse*)
        rpm -q "$item" > /dev/null 2>&1 || return 1
        ;;
      arch)
        pacman -Q "$item" > /dev/null 2>&1 || return 1
        ;;
      *)
        return 1
        ;;
    esac
  done

  return 0
}
