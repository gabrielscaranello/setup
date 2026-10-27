#!/bin/bash

# Package Resolution and Installation Utilities
# Resolves package names across Debian, Fedora, Arch Linux, and openSUSE using packages.conf
# and dispatches idempotent operations through per-package-manager adapters.

# Maps a distribution ID or package manager name to "<package_manager>|<packages.conf_column>".
_resolve_pm_metadata() {
  case "${1:-}" in
    debian | apt | linuxmint) echo "apt|2" ;;
    fedora | dnf) echo "dnf|3" ;;
    arch | pacman) echo "pacman|4" ;;
    opensuse | opensuse-leap | opensuse-tumbleweed | zypper) echo "zypper|5" ;;
    *) return 1 ;;
  esac
}

# ── Per-Package-Manager Adapters (OCP / LSP) ─────────────────────────────────

_pm_apt_install() {
  # Refresh the APT index only once per process to keep repeated installs fast
  if [ "${_APT_INDEX_REFRESHED:-0}" != "1" ]; then
    sudo apt update -qq
    _APT_INDEX_REFRESHED=1
  fi
  sudo apt install -y "$@"
}

_pm_dnf_install() {
  sudo dnf install -y --allowerasing "$@"
}

_pm_pacman_install() {
  # Sync and upgrade in the same transaction: syncing alone (-Sy) causes unsupported
  # partial upgrades on Arch, while skipping the sync (-S) fails on stale databases (404s).
  sudo pacman -Syu --needed --noconfirm "$@"
}

_pm_zypper_install() {
  sudo zypper --non-interactive --gpg-auto-import-keys install -y --allow-vendor-change --force-resolution --no-recommends "$@"
}

_pm_apt_remove() {
  local autoremove="$1"
  shift
  sudo apt purge -y "$@"
  [ "$autoremove" -eq 0 ] || sudo apt autoremove --purge -y
}

_pm_dnf_remove() {
  local autoremove="$1"
  shift
  sudo dnf remove -y "$@"
  [ "$autoremove" -eq 0 ] || sudo dnf autoremove -y
}

_pm_pacman_remove() {
  local autoremove="$1"
  shift
  sudo pacman -Rns --noconfirm "$@"
  [ "$autoremove" -eq 0 ] || true
}

_pm_zypper_remove() {
  local autoremove="$1"
  shift
  sudo zypper --non-interactive remove -u "$@"
  [ "$autoremove" -eq 0 ] || true
}

_pm_apt_swap() {
  local allowerasing="$1"
  local old_pkg="$2"
  local new_pkg="$3"
  sudo apt install -y "$new_pkg"
  [ "$allowerasing" -eq 0 ] || true
  : "$old_pkg"
}

_pm_dnf_swap() {
  local allowerasing="$1"
  local old_pkg="$2"
  local new_pkg="$3"
  local extra_flags=()
  [ "$allowerasing" -eq 1 ] && extra_flags+=("--allowerasing")

  sudo dnf swap -y "$old_pkg" "$new_pkg" "${extra_flags[@]}" 2> /dev/null \
    || sudo dnf install -y --allowerasing "$new_pkg" 2> /dev/null || true
}

_pm_pacman_swap() {
  local allowerasing="$1"
  local old_pkg="$2"
  local new_pkg="$3"
  sudo pacman -S --needed --noconfirm "$new_pkg"
  [ "$allowerasing" -eq 0 ] || true
  : "$old_pkg"
}

_pm_zypper_swap() {
  local allowerasing="$1"
  local old_pkg="$2"
  local new_pkg="$3"
  sudo zypper --non-interactive install -y --allow-vendor-change "$new_pkg"
  [ "$allowerasing" -eq 0 ] || true
  : "$old_pkg"
}

_pm_apt_lock() {
  : "$@"
}

_pm_dnf_lock() {
  : "$@"
}

_pm_pacman_lock() {
  : "$@"
}

_pm_zypper_lock() {
  sudo zypper --non-interactive addlock "$@"
}

_pm_apt_install_from_repo() {
  local repo="$1"
  shift
  sudo apt install -y -t "$repo" "$@"
}

_pm_zypper_install_from_repo() {
  local repo="$1"
  shift
  sudo zypper --non-interactive install -y --from "$repo" "$@"
}

_pm_apt_upgrade() {
  sudo apt update
  sudo apt upgrade -y
}

_pm_dnf_upgrade() {
  sudo dnf upgrade -y --refresh
}

_pm_pacman_upgrade() {
  sudo pacman -Syu --noconfirm
}

_pm_zypper_upgrade() {
  local distro="${1:-}"
  sudo zypper --non-interactive refresh
  if [ "$distro" = "opensuse-tumbleweed" ]; then
    sudo zypper --non-interactive dup --no-recommends
  else
    sudo zypper --non-interactive up --no-recommends
  fi
}

_pm_apt_is_installed() {
  dpkg -s "$1" > /dev/null 2>&1
}

_pm_dnf_is_installed() {
  rpm -q "$1" > /dev/null 2>&1
}

_pm_pacman_is_installed() {
  pacman -Q "$1" > /dev/null 2>&1
}

_pm_zypper_is_installed() {
  rpm -q "$1" > /dev/null 2>&1
}

# ── Package Manager & Name Resolution (SRP) ──────────────────────────────────

_get_package_manager() {
  local distro meta
  distro="$(get_distro_id 2> /dev/null || true)"
  if meta="$(_resolve_pm_metadata "$distro")"; then
    echo "${meta%%|*}"
    return 0
  fi

  local pm
  for pm in dnf apt pacman zypper; do
    if command -v "$pm" > /dev/null 2>&1; then
      echo "$pm"
      return 0
    fi
  done
  return 1
}

_find_packages_conf() {
  local repo_root
  repo_root="$(get_repo_root)"
  if [ -f "${repo_root}/scripts/packages.conf" ]; then
    echo "${repo_root}/scripts/packages.conf"
  elif [ -f "scripts/packages.conf" ]; then
    echo "scripts/packages.conf"
  fi
}

_get_package_name() {
  local package="$1"
  local target="${2:-}"
  if [ -z "$target" ]; then
    target="$(get_distro_id 2> /dev/null || _get_package_manager 2> /dev/null || true)"
  fi

  local config_file meta field_idx
  config_file="$(_find_packages_conf)"
  if [ -n "$config_file" ] && [ -f "$config_file" ] && meta="$(_resolve_pm_metadata "$target")"; then
    field_idx="${meta##*|}"
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

  echo "$package"
}

# Resolves a list of generic package names into a newline-separated list of native packages.
_resolve_package_list() {
  local distro="$1"
  shift
  local package resolved item
  for package in "$@"; do
    resolved="$(_get_package_name "$package" "$distro")"
    if [ -n "$resolved" ]; then
      for item in $resolved; do
        echo "$item"
      done
    fi
  done
}

# ── High-Level Package Operations (DIP) ──────────────────────────────────────

_install_package_from_repository() {
  local package_manager="$1"
  shift

  local adapter="_pm_${package_manager}_install"
  if ! command -v "$adapter" > /dev/null 2>&1; then
    echo "Unsupported package manager: $package_manager" >&2
    return 1
  fi

  "$adapter" "$@"
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
  local item
  while IFS= read -r item; do
    [ -n "$item" ] && resolved_packages+=("$item")
  done < <(_resolve_package_list "$distro" "$@")

  if [ ${#resolved_packages[@]} -eq 0 ]; then
    echo "No packages to install for $package_manager"
    return 0
  fi

  echo "Installing: ${resolved_packages[*]}"

  _install_package_from_repository "$package_manager" "${resolved_packages[@]}"
}

# Installs native packages pinned to a specific repository or suite (-t on APT, --from on Zypper).
# Usage: install_packages_from_repo <repo_or_suite> <native_pkg>...
install_packages_from_repo() {
  local repo="$1"
  shift
  [ $# -gt 0 ] || return 0

  local pm=""
  case "$repo" in
    *-backports) pm="apt" ;;
    Kernel:stable | Kernel_stable) pm="zypper" ;;
    *) pm="$(_get_package_manager 2> /dev/null || true)" ;;
  esac

  local adapter="_pm_${pm}_install_from_repo"
  if command -v "$adapter" > /dev/null 2>&1; then
    "$adapter" "$repo" "$@"
  else
    echo "Unsupported package manager for repository pinning: $pm" >&2
    return 1
  fi
}

# Replaces a restricted/stub package with its full implementation.
# Usage: swap_packages [--allowerasing] <old_pkg> <new_pkg>
swap_packages() {
  local allowerasing=0
  if [ "${1:-}" = "--allowerasing" ]; then
    allowerasing=1
    shift
  fi

  [ $# -ge 2 ] || return 0

  local old_pkg="$1"
  local new_pkg="$2"
  local package_manager
  package_manager="$(_get_package_manager 2> /dev/null || true)"
  [ -n "$package_manager" ] || package_manager="dnf"

  local adapter="_pm_${package_manager}_swap"
  if ! command -v "$adapter" > /dev/null 2>&1; then
    echo "Unsupported package manager: $package_manager" >&2
    return 1
  fi

  "$adapter" "$allowerasing" "$old_pkg" "$new_pkg"
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

  local adapter="_pm_${package_manager}_remove"
  if ! command -v "$adapter" > /dev/null 2>&1; then
    echo "Unsupported package manager: $package_manager" >&2
    return 1
  fi

  "$adapter" "$autoremove" "$@"
}

# Prevents removed packages from being reinstalled as dependencies.
# Dispatches to per-package-manager adapters (active on Zypper, extensible elsewhere).
# Usage: lock_packages <native_pkg>...
lock_packages() {
  [ $# -gt 0 ] || return 0

  local package_manager
  package_manager="$(_get_package_manager 2> /dev/null || true)" || return 0
  [ -n "$package_manager" ] || return 0

  local adapter="_pm_${package_manager}_lock"
  if command -v "$adapter" > /dev/null 2>&1; then
    "$adapter" "$@"
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

  local adapter="_pm_${package_manager}_upgrade"
  if ! command -v "$adapter" > /dev/null 2>&1; then
    echo "Unsupported package manager: $package_manager" >&2
    return 1
  fi

  echo "Refreshing ${package_manager} repositories and upgrading packages..."
  "$adapter" "$distro"
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
  local distro meta pm
  distro="$(get_distro_id 2> /dev/null || true)"
  meta="$(_resolve_pm_metadata "$distro")" || return 1
  pm="${meta%%|*}"

  local resolved
  resolved="$(_get_package_name "$package" "$distro" 2> /dev/null || echo "$package")"
  [ -n "$resolved" ] || return 1

  local item
  for item in $resolved; do
    "_pm_${pm}_is_installed" "$item" || return 1
  done

  return 0
}
