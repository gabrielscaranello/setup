#!/bin/bash
set -euo pipefail

source "scripts/_utils.sh" 2> /dev/null || true

_install_cli_tools() {
  echo "Installing CLI productivity tools..."
  install_packages bat btop eza gdu zsh zsh-completions man-db util-linux-user
}

_install_hardware_tools() {
  echo "Installing hardware, energy, and firmware tools..."
  install_packages power-profiles-daemon numlockx fwupd bluez cups cron
}

_install_filesystem_tools() {
  echo "Installing filesystem compatibility tools..."
  install_packages dosfstools mtools ntfs-3g
}

_install_session_tools() {
  echo "Installing XDG standards, connectivity, and session utilities..."
  install_packages xdg-user-dirs xdg-utils openssh dialog keychain
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
  if [ -d /etc/bluetooth ] || [ -f /etc/bluetooth/main.conf ]; then
    echo "Configuring Bluetooth policy (AutoEnable=true)..."
    if [ -f /etc/bluetooth/main.conf ]; then
      if grep -q "^\[Policy\]" /etc/bluetooth/main.conf; then
        if grep -q "^AutoEnable=" /etc/bluetooth/main.conf; then
          sudo sed -i 's/^AutoEnable=.*/AutoEnable=true/' /etc/bluetooth/main.conf 2> /dev/null || true
        elif grep -q "^#AutoEnable=" /etc/bluetooth/main.conf; then
          sudo sed -i 's/^#AutoEnable=.*/AutoEnable=true/' /etc/bluetooth/main.conf 2> /dev/null || true
        else
          sudo sed -i '/^\[Policy\]/a AutoEnable=true' /etc/bluetooth/main.conf 2> /dev/null || true
        fi
      else
        printf "\n[Policy]\nAutoEnable=true\n" | sudo tee -a /etc/bluetooth/main.conf > /dev/null 2>&1 || true
      fi
    else
      sudo mkdir -p /etc/bluetooth 2> /dev/null || true
      printf "[Policy]\nAutoEnable=true\n" | sudo tee /etc/bluetooth/main.conf > /dev/null 2>&1 || true
    fi
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

  echo "Enabling cron scheduler service..."
  if is_distro debian; then
    sudo systemctl enable --now cron.service 2> /dev/null || sudo systemctl enable cron.service 2> /dev/null || true
  elif is_distro fedora; then
    sudo systemctl enable --now crond.service 2> /dev/null || sudo systemctl enable crond.service 2> /dev/null || true
  else
    sudo systemctl enable --now cronie.service 2> /dev/null || sudo systemctl enable cronie.service 2> /dev/null || true
  fi

  echo "Enabling periodic SSD TRIM timer..."
  sudo systemctl enable fstrim.timer 2> /dev/null || true
}

main() {
  echo "Setting up core system packages..."
  _install_cli_tools
  _install_hardware_tools
  _install_filesystem_tools
  _install_session_tools
  _install_spelling_dictionaries
  _initialize_xdg_dirs
  _configure_bluetooth
  _enable_system_services
  echo "setup-packages complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
