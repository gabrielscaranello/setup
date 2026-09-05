#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/security/setup-firewall.sh 2>/dev/null || source scripts/security/setup-firewall.sh
}

@test "_configure_ufw installs and enables ufw with default rules" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  sudo() {
    echo "sudo: $*"
    return 0
  }
  command() {
    return 0
  }

  run _configure_ufw
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ ufw ]]
  [[ "$output" =~ "sudo: systemctl enable ufw.service" ]]
  [[ "$output" =~ "sudo: systemctl start ufw.service" ]]
  [[ "$output" =~ "sudo: ufw default deny incoming" ]]
  [[ "$output" =~ "sudo: ufw default allow outgoing" ]]
  [[ "$output" =~ "sudo: ufw --force enable" ]]
}

@test "_configure_firewalld installs and enables firewalld service" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  sudo() {
    echo "sudo: $*"
    return 0
  }
  command() {
    return 0
  }

  run _configure_firewalld
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ firewalld ]]
  [[ "$output" =~ "sudo: systemctl enable --now firewalld.service" ]]
}

@test "_configure_gui_frontend handles GNOME on debian/arch with gufw" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _configure_gui_frontend "debian" "gnome"
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ gufw ]]

  run _configure_gui_frontend "arch" "gnome"
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ gufw ]]
}

@test "_configure_gui_frontend handles GNOME on fedora with firewall-config" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _configure_gui_frontend "fedora" "gnome"
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ firewall-config ]]
}

@test "_configure_gui_frontend handles KDE Plasma with plasma-firewall across distros" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _configure_gui_frontend "apt" "plasma"
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ plasma-firewall ]]

  run _configure_gui_frontend "dnf" "plasma"
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ plasma-firewall ]]

  run _configure_gui_frontend "pacman" "plasma"
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ plasma-firewall ]]
}

@test "_configure_gui_frontend does nothing for unknown desktop environment" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _configure_gui_frontend "apt" "unknown"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No GUI frontend required for desktop environment: unknown" ]]
  [[ ! "$output" =~ "installed:" ]]
}

@test "main fails on unsupported distribution" {
  get_distro_id() {
    return 1
  }

  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "main configures ufw and gnome GUI on debian" {
  get_distro_id() { echo "debian"; }
  get_desktop_environment() { echo "gnome"; }
  install_packages() { echo "installed: $*"; }
  sudo() { echo "sudo: $*"; }
  command() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ ufw ]]
  [[ "$output" =~ installed:\ gufw ]]
  [[ "$output" =~ "Firewall setup completed successfully." ]]
}

@test "main configures firewalld and plasma GUI on fedora" {
  get_distro_id() { echo "fedora"; }
  get_desktop_environment() { echo "plasma"; }
  install_packages() { echo "installed: $*"; }
  sudo() { echo "sudo: $*"; }
  command() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ firewalld ]]
  [[ "$output" =~ installed:\ plasma-firewall ]]
  [[ "$output" =~ "Firewall setup completed successfully." ]]
}

@test "main configures ufw and plasma GUI on arch" {
  get_distro_id() { echo "arch"; }
  get_desktop_environment() { echo "plasma"; }
  install_packages() { echo "installed: $*"; }
  sudo() { echo "sudo: $*"; }
  command() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ ufw ]]
  [[ "$output" =~ installed:\ plasma-firewall ]]
  [[ "$output" =~ "Firewall setup completed successfully." ]]
}

@test "main configures ufw without GUI on headless arch" {
  get_distro_id() { echo "arch"; }
  get_desktop_environment() { echo "unknown"; }
  install_packages() { echo "installed: $*"; }
  sudo() { echo "sudo: $*"; }
  command() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ ufw ]]
  [[ ! "$output" =~ installed:\ plasma-firewall ]]
  [[ ! "$output" =~ installed:\ gufw ]]
  [[ "$output" =~ "Firewall setup completed successfully." ]]
}
