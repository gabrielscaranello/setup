#!/bin/bash

# System Packages Debloat & Cleanup Script
# Removes unused default packages and bloatware on Debian and Fedora,
# tailored specifically to the active Desktop Environment (GNOME or KDE Plasma).
# Arch Linux is minimal by default and is gracefully bypassed.

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

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

_filter_installed_fedora() {
  local installed=()
  for pkg in "$@"; do
    if rpm -q "$pkg" > /dev/null 2>&1; then
      installed+=("$pkg")
    fi
  done
  echo "${installed[@]:-}"
}

COMMON_DEBLOAT_PACKAGES=(
  libreoffice-core
  xterm
  kate
  brasero
  deja-dup
  transmission-common
)

COMMON_CINNAMON_DEBLOAT_PACKAGES=(
  celluloid
  gnome-terminal
  "hypnotix*"
  "libreoffice*"
  mintchat
  rhythmbox
  simple-scan
  sticky
  thingy
  "thunderbird*"
  "transmission*"
  "xterm*"
)

COMMON_GNOME_DEBLOAT_PACKAGES=(
  totem
  gnome-music
  rhythmbox
  cheese
  snapshot
  gnome-photos
  shotwell
  gnome-terminal
  ptyxis
  evolution
  gnome-boxes
  gnome-characters
  gnome-connections
  gnome-maps
  gnome-sound-recorder
  gnome-tour
  simple-scan
  gedit
  remmina
  polari
)

COMMON_PLASMA_DEBLOAT_PACKAGES=(
  juk
  konsole
  konqueror
  akregator
  kdepim
  kdepim-runtime
  kmail
  kontact
  korganizer
  konversation
  kamera
  kcalc
  kfind
  kmag
  kmousetool
  kmouth
  kontrast
  kuiviewer
  kwalletmanager
  sweeper
  skanlite
)

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
      targets+=(
        "${COMMON_GNOME_DEBLOAT_PACKAGES[@]}"
        gnome-snapshot
      )
      ;;
    plasma)
      targets+=(
        dragonplayer
        "${COMMON_PLASMA_DEBLOAT_PACKAGES[@]}"
      )
      ;;
    cinnamon)
      targets+=(
        "${COMMON_CINNAMON_DEBLOAT_PACKAGES[@]}"
      )
      ;;
    *)
      local distro
      distro="$(get_distro_id)"
      if [ "$distro" = "lmde" ]; then
        targets+=(
          "${COMMON_CINNAMON_DEBLOAT_PACKAGES[@]}"
        )
      else
        echo "Desktop environment '$de' is unknown or generic; applying only common debloat."
      fi
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
    sudo apt purge -y $to_remove
    sudo apt autoremove --purge -y
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
      targets+=(
        dragon
        "${COMMON_PLASMA_DEBLOAT_PACKAGES[@]}"
      )
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
    sudo dnf remove -y $to_remove
    sudo dnf autoremove -y
  else
    echo "No unused Fedora packages found to remove."
  fi
}

main() {
  echo "Starting system packages debloat..."

  local distro
  distro="$(get_distro_id)"

  case "$distro" in
    debian | lmde)
      _debloat_debian
      ;;
    fedora)
      _debloat_fedora
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
