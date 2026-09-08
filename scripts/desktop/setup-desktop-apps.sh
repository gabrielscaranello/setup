#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2> /dev/null || true

_install_plasma_apps() {
  echo "Installing KDE Plasma desktop applications..."
  if [ "${DESKTOP_APPS_SKIP_PACKAGE_INSTALL:-0}" = "1" ]; then
    echo "DESKTOP_APPS_SKIP_PACKAGE_INSTALL is active. Skipping package installation step."
    return 0
  fi
  install_packages \
    dolphin dolphin-plugins \
    ark gwenview okular \
    kalk plasma-systemmonitor filelight \
    partitionmanager ghostwriter \
    kde-gtk-config kdeconnect kweather \
    vlc
}

_install_gnome_apps() {
  echo "Installing GNOME desktop applications..."
  if [ "${DESKTOP_APPS_SKIP_PACKAGE_INSTALL:-0}" = "1" ]; then
    echo "DESKTOP_APPS_SKIP_PACKAGE_INSTALL is active. Skipping package installation step."
    return 0
  fi
  install_packages \
    nautilus sushi \
    file-roller loupe evince \
    gnome-calculator gnome-system-monitor baobab \
    gnome-disk-utility gnome-text-editor \
    gnome-tweaks gnome-weather \
    vlc
}

main() {
  local de
  if [ -t 0 ]; then
    de="$(ensure_desktop_environment "Selecione o Desktop Environment para instalar os aplicativos:")"
  else
    de="$(get_desktop_environment)"
    if [ "$de" != "unknown" ]; then
      save_desktop_environment "$de"
    fi
  fi

  case "$de" in
    plasma)
      echo "Configuring applications for KDE Plasma..."
      _install_plasma_apps
      ;;
    gnome)
      echo "Configuring applications for GNOME..."
      _install_gnome_apps
      ;;
    *)
      echo "Desktop environment not recognized ($de), skipping desktop applications setup."
      return 0
      ;;
  esac

  echo "setup-desktop-apps complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
