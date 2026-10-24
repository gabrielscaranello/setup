#!/bin/bash

# System Packages Debloat & Cleanup Script
# Removes unused default packages and bloatware on Debian, Fedora, and openSUSE,
# tailored specifically to the active Desktop Environment (GNOME or KDE Plasma).
# Arch Linux is minimal by default and is gracefully bypassed.

set -euo pipefail

# Follow project conventions: source utility helpers and package catalogs
source "scripts/_utils.sh" 2> /dev/null || true
# shellcheck source=scripts/system/_debloat_packages.sh
source "$(dirname "${BASH_SOURCE[0]}")/_debloat_packages.sh" 2> /dev/null || source "scripts/system/_debloat_packages.sh"

_filter_installed_debian() {
  local installed=()
  for pkg in "$@"; do
    if [[ "$pkg" == *"*"* ]]; then
      local matching
      matching="$(dpkg-query -W -f='${Package} ${Status}\n' "$pkg" 2> /dev/null | grep ' install ok installed$' | awk '{print $1}' || true)"
      if [ -n "$matching" ]; then
        while IFS= read -r p; do
          local pat=" ${p} "
          if [ -n "$p" ] && [[ ! " ${installed[*]:-} " =~ $pat ]]; then
            installed+=("$p")
          fi
        done <<< "$matching"
      fi
    elif dpkg -s "$pkg" 2> /dev/null | grep -q "Status: install ok installed"; then
      local pkg_pat=" ${pkg} "
      if [[ ! " ${installed[*]:-} " =~ $pkg_pat ]]; then
        installed+=("$pkg")
      fi
    fi
  done
  echo "${installed[@]:-}"
}

_filter_installed_rpm() {
  local installed=()
  for pkg in "$@"; do
    if is_package_installed "$pkg"; then
      installed+=("$pkg")
    fi
  done
  echo "${installed[@]:-}"
}

_filter_installed_fedora() {
  _filter_installed_rpm "$@"
}

_filter_installed_opensuse() {
  _filter_installed_rpm "$@"
}

_debloat_debian() {
  local de
  de="$(get_desktop_environment)"

  local targets=(
    "${COMMON_DEBLOAT_PACKAGES[@]}"
    libreoffice-common
    gimp
  )

  case "$de" in
    gnome)
      targets+=("${COMMON_GNOME_DEBLOAT_PACKAGES[@]}" gnome-snapshot)
      ;;
    plasma)
      targets+=(dragonplayer "${COMMON_PLASMA_DEBLOAT_PACKAGES[@]}")
      ;;
    *)
      echo "Desktop environment '$de' is unknown or generic; applying only common debloat."
      ;;
  esac

  if [ "${DEBLOAT_SKIP_PACKAGE_REMOVAL:-0}" = "1" ]; then
    echo "DEBLOAT_SKIP_PACKAGE_REMOVAL is active. Skipping Debian package purge."
    return 0
  fi

  local to_remove
  to_remove="$(_filter_installed_debian "${targets[@]}")"

  if [ -n "$to_remove" ]; then
    echo "Purging unused Debian packages: $to_remove"
    # shellcheck disable=SC2086
    remove_packages --autoremove $to_remove
  else
    echo "No unused Debian packages found to remove."
  fi
}

_debloat_fedora() {
  local de
  de="$(get_desktop_environment)"

  local targets=("${COMMON_DEBLOAT_PACKAGES[@]}")

  case "$de" in
    gnome)
      targets+=(
        "${COMMON_GNOME_DEBLOAT_PACKAGES[@]}"
        decibels
        mediawriter
        gnome-shell-extension-background-logo
      )
      ;;
    plasma)
      targets+=(dragon "${COMMON_PLASMA_DEBLOAT_PACKAGES[@]}")
      ;;
    *)
      echo "Desktop environment '$de' is unknown or generic; applying only common debloat."
      ;;
  esac

  if [ "${DEBLOAT_SKIP_PACKAGE_REMOVAL:-0}" = "1" ]; then
    echo "DEBLOAT_SKIP_PACKAGE_REMOVAL is active. Skipping Fedora package removal."
    return 0
  fi

  local to_remove
  to_remove="$(_filter_installed_fedora "${targets[@]}")"

  if [ -n "$to_remove" ]; then
    echo "Removing unused Fedora packages: $to_remove"
    # shellcheck disable=SC2086
    remove_packages --autoremove $to_remove
  else
    echo "No unused Fedora packages found to remove."
  fi
}

_debloat_opensuse() {
  local de distro
  de="$(get_desktop_environment)"
  distro="$(get_distro_id 2> /dev/null || echo "opensuse-leap")"

  local targets=(
    "${COMMON_DEBLOAT_PACKAGES[@]}"
    "${OPEN_SUSE_COMMON_DEBLOAT_PACKAGES[@]}"
  )

  if [ "$distro" != "opensuse-tumbleweed" ]; then
    targets+=(gimp)
  fi

  case "$de" in
    gnome)
      targets+=("${COMMON_GNOME_DEBLOAT_PACKAGES[@]}" "${OPEN_SUSE_GNOME_DEBLOAT_PACKAGES[@]}")
      ;;
    plasma)
      targets+=(dragonplayer "${COMMON_PLASMA_DEBLOAT_PACKAGES[@]}" "${OPEN_SUSE_PLASMA_DEBLOAT_PACKAGES[@]}")
      ;;
    *)
      echo "Desktop environment '$de' is unknown or generic; applying only common debloat."
      ;;
  esac

  if [ "${DEBLOAT_SKIP_PACKAGE_REMOVAL:-0}" = "1" ]; then
    echo "DEBLOAT_SKIP_PACKAGE_REMOVAL is active. Skipping openSUSE package removal."
    return 0
  fi

  local to_remove
  to_remove="$(_filter_installed_opensuse "${targets[@]}")"

  if [ -n "$to_remove" ]; then
    echo "Removing unused openSUSE packages: $to_remove"
    # shellcheck disable=SC2086
    remove_packages $to_remove
    echo "Locking removed openSUSE packages to prevent reinstallation: $to_remove"
    # shellcheck disable=SC2086
    lock_packages $to_remove
  else
    echo "No unused openSUSE packages found to remove."
  fi
}

main() {
  echo "Starting system packages debloat..."

  local distro
  distro="$(get_distro_id)"

  case "$distro" in
    debian | linuxmint)
      _debloat_debian
      ;;
    fedora)
      _debloat_fedora
      ;;
    opensuse*)
      _debloat_opensuse
      ;;
    arch)
      echo "Arch Linux is minimal by default; debloat is not needed."
      ;;
    *)
      echo "Unsupported distribution for debloat: $distro" >&2
      return 1
      ;;
  esac

  echo "setup-debloat complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
