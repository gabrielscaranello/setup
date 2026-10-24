#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2> /dev/null || true

_install_hardware_tools() {
  echo "Installing hardware, energy, and firmware tools..."
  install_packages power-profiles-daemon numlockx fwupd bluez cups cron libu2f-udev
}

_install_filesystem_tools() {
  echo "Installing filesystem compatibility tools..."
  install_packages dosfstools mtools ntfs-3g
}

_install_xdg_tools() {
  echo "Installing XDG desktop integration utilities..."
  install_packages xdg-user-dirs xdg-utils
}

_install_spelling_dictionaries() {
  echo "Installing spelling dictionaries..."
  install_packages spell-pt-br spell-en
}

_initialize_xdg_dirs() {
  if command -v xdg-user-dirs-update > /dev/null 2>&1; then
    echo "Initializing XDG user directories..."
    xdg-user-dirs-update || true
  fi
}

_configure_bluetooth() {
  local conf_file="${1:-/etc/bluetooth/main.conf}"
  if [ -d "$(dirname "$conf_file")" ] || [ -f "$conf_file" ]; then
    echo "Configuring Bluetooth policy (AutoEnable=true)..."
    write_ini_key "$conf_file" "Policy" "AutoEnable" "true"
  fi
}

_enable_system_services() {
  if ! command -v systemctl > /dev/null 2>&1; then
    echo "systemctl not available, skipping system services enablement."
    return 0
  fi

  echo "Enabling core hardware and power management services..."
  if is_distro fedora; then
    sudo systemctl enable --now tuned.service 2> /dev/null || sudo systemctl enable tuned.service 2> /dev/null || true
  else
    sudo systemctl enable --now power-profiles-daemon.service 2> /dev/null || sudo systemctl enable power-profiles-daemon.service 2> /dev/null || true
  fi

  echo "Enabling Bluetooth service..."
  sudo systemctl enable --now bluetooth.service 2> /dev/null || sudo systemctl enable bluetooth.service 2> /dev/null || true

  echo "Enabling CUPS printing service..."
  sudo systemctl enable --now cups.service 2> /dev/null || sudo systemctl enable cups.service 2> /dev/null || true

  enable_cron_service

  echo "Enabling periodic SSD TRIM timer..."
  sudo systemctl enable fstrim.timer 2> /dev/null || true
}

main() {
  echo "Setting up core system packages..."
  bash "$(get_repo_root)/scripts/terminal/setup-cli.sh"
  if ! is_wsl; then
    _install_hardware_tools
    _install_filesystem_tools
    _install_xdg_tools
  fi
  _install_spelling_dictionaries
  if ! is_wsl; then
    _initialize_xdg_dirs
    _configure_bluetooth
    _enable_system_services
  fi
  echo "setup-packages complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
