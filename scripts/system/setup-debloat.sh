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
    if dpkg -s "$pkg" 2> /dev/null | grep -q "Status: install ok installed"; then
      installed+=("$pkg")
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

_debloat_debian() {
  local de
  de="$(get_desktop_environment)"

  local targets=(
    libreoffice-core
    libreoffice-common
    xterm
    kate
    brasero
    deja-dup
    transmission-common
    gimp
  )

  case "$de" in
    gnome)
      targets+=(
        totem
        gnome-music
        rhythmbox
        cheese
        gnome-snapshot
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
      ;;
    plasma)
      targets+=(
        dragonplayer
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
        drkonqi
      )
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
    sudo apt purge -y $to_remove
    sudo apt autoremove --purge -y
  else
    echo "No unused Debian packages found to remove."
  fi
}

_debloat_fedora() {
  local de
  de="$(get_desktop_environment)"

  local targets=(
    libreoffice-core
    xterm
    kate
    brasero
    deja-dup
    transmission-common
  )

  case "$de" in
    gnome)
      targets+=(
        totem
        gnome-music
        rhythmbox
        decibels
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
        mediawriter
        gnome-shell-extension-background-logo
      )
      ;;
    plasma)
      targets+=(
        dragon
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
        plasma-drkonqi
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
    debian)
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
