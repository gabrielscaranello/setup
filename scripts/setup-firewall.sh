#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_configure_ufw() {
  echo "Installing and configuring UFW..."
  install_packages ufw

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable ufw.service 2>/dev/null || true
    sudo systemctl start ufw.service 2>/dev/null || true
  fi

  # Apply default policies and enable rules engine (fail-safely if running in unprivileged container)
  sudo ufw default deny incoming 2>/dev/null || true
  sudo ufw default allow outgoing 2>/dev/null || true
  sudo ufw --force enable 2>/dev/null || true
  echo "UFW configured and enabled successfully."
}

_configure_firewalld() {
  echo "Installing and configuring firewalld..."
  install_packages firewalld

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now firewalld.service 2>/dev/null || sudo systemctl enable firewalld.service 2>/dev/null || true
  fi
  echo "firewalld enabled successfully."
}

_configure_gui_frontend() {
  local pm="$1"
  local de="$2"

  case "$de" in
  gnome)
    if [ "$pm" = "apt" ] || [ "$pm" = "pacman" ]; then
      echo "Installing GUFW for GNOME..."
      install_packages gufw
    elif [ "$pm" = "dnf" ]; then
      echo "Installing firewall-config for GNOME..."
      install_packages firewall-config
    fi
    ;;

  plasma)
    echo "Installing plasma-firewall for KDE Plasma..."
    install_packages plasma-firewall
    ;;

  *)
    echo "No GUI frontend required for desktop environment: $de"
    ;;
  esac
}

main() {
  local package_manager
  package_manager="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$package_manager" in
  apt | pacman)
    _configure_ufw
    ;;

  dnf)
    _configure_firewalld
    ;;

  *)
    echo "Unsupported package manager: $package_manager" >&2
    return 1
    ;;
  esac

  local de
  de="$(get_desktop_environment)"
  _configure_gui_frontend "$package_manager" "$de"

  echo "Firewall setup completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
