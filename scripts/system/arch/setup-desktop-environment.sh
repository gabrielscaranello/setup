#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2> /dev/null || true

_resolve_target_de() {
  local target="${TARGET_DE:-}"

  # Check CLI argument override (--de=...)
  local arg
  for arg in "$@"; do
    case "$arg" in
      --de=*) target="${arg#*=}" ;;
    esac
  done

  # Normalize target string
  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"
  case "$target" in
    plasma | kde)
      save_desktop_environment "plasma"
      echo "plasma"
      return 0
      ;;
    gnome)
      save_desktop_environment "gnome"
      echo "gnome"
      return 0
      ;;
  esac

  ensure_desktop_environment "Selecione o Desktop Environment para o Arch Linux:"
}

_install_plasma_stack() {
  echo "Installing KDE Plasma desktop environment stack..."
  if [ "${ARCH_DE_SKIP_PACKAGE_INSTALL:-0}" = "1" ]; then
    echo "ARCH_DE_SKIP_PACKAGE_INSTALL is active. Skipping package installation step."
  else
    install_packages \
      plasma-login-manager \
      plasma-desktop plasma-workspace plasma-workspace-wallpapers \
      plasma-nm plasma-pa powerdevil kscreen polkit-kde-agent plasma-integration \
      bluedevil networkmanager \
      pipewire pipewire-pulse wireplumber gst-plugin-pipewire \
      xdg-desktop-portal-kde egl-wayland xorg-xwayland
  fi

  echo "Enabling NetworkManager, Bluetooth, and plasmalogin services..."
  sudo systemctl enable NetworkManager.service 2> /dev/null \
    || sudo systemctl enable NetworkManager 2> /dev/null || true
  sudo systemctl enable bluetooth.service 2> /dev/null \
    || sudo systemctl enable bluetooth 2> /dev/null || true
  sudo systemctl enable fstrim.timer 2> /dev/null || true
  sudo systemctl enable plasmalogin.service 2> /dev/null \
    || sudo systemctl enable plasmalogin 2> /dev/null || true
}

_install_gnome_stack() {
  echo "Installing GNOME desktop environment stack..."
  if [ "${ARCH_DE_SKIP_PACKAGE_INSTALL:-0}" = "1" ]; then
    echo "ARCH_DE_SKIP_PACKAGE_INSTALL is active. Skipping package installation step."
  else
    install_packages \
      gdm \
      gnome-shell mutter gnome-control-center gnome-session gsettings-desktop-schemas \
      networkmanager gnome-bluetooth-3.0 \
      pipewire pipewire-pulse wireplumber \
      xdg-desktop-portal-gnome xorg-xwayland
  fi

  echo "Enabling NetworkManager, Bluetooth, and gdm services..."
  sudo systemctl enable NetworkManager.service 2> /dev/null \
    || sudo systemctl enable NetworkManager 2> /dev/null || true
  sudo systemctl enable bluetooth.service 2> /dev/null \
    || sudo systemctl enable bluetooth 2> /dev/null || true
  sudo systemctl enable fstrim.timer 2> /dev/null || true
  sudo systemctl enable gdm.service 2> /dev/null \
    || sudo systemctl enable gdm 2> /dev/null || true
}

main() {
  if ! is_distro arch; then
    echo "Desktop environment provisioning script is specific to Arch Linux, skipping."
    return 0
  fi

  local de
  de="$(_resolve_target_de "$@")"
  save_desktop_environment "$de"
  echo "Selected Desktop Environment: $de"

  case "$de" in
    plasma)
      _install_plasma_stack
      ;;
    gnome)
      _install_gnome_stack
      ;;
    *)
      echo "Unknown target desktop environment: $de" >&2
      return 1
      ;;
  esac

  echo "setup-desktop-environment complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
