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
  if [ "$target" = "plasma" ] || [ "$target" = "kde" ]; then
    echo "plasma"
    return 0
  elif [ "$target" = "gnome" ]; then
    echo "gnome"
    return 0
  fi

  # Check current running DE
  local current_de
  current_de="$(get_desktop_environment)"
  if [ "$current_de" = "plasma" ] || [ "$current_de" = "gnome" ]; then
    echo "$current_de"
    return 0
  fi

  # Interactive prompt if stdin is a terminal
  if [ -t 0 ]; then
    echo "" >&2
    echo "Nenhum ambiente gráfico ativo detectado." >&2
    echo "Selecione o Desktop Environment para o Arch Linux:" >&2
    echo "  1) KDE Plasma (Recomendado)" >&2
    echo "  2) GNOME" >&2
    echo "" >&2
    local choice
    read -r -p "Opção [1-2, padrão: 1]: " choice < /dev/tty || true
    case "$choice" in
      2 | [gG]*) echo "gnome" ;;
      *) echo "plasma" ;;
    esac
    return 0
  fi

  # Non-interactive fallback
  echo "plasma"
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
      pipewire pipewire-pulse wireplumber gst-plugin-pipewire \
      xdg-desktop-portal-kde egl-wayland xorg-xwayland
  fi

  echo "Enabling plasmalogin.service..."
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
      pipewire pipewire-pulse wireplumber \
      xdg-desktop-portal-gnome xorg-xwayland
  fi

  echo "Enabling gdm.service..."
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
