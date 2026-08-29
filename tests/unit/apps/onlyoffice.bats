#!/usr/bin/env bats

# Unit tests for setup-onlyoffice.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-onlyoffice.sh
}

@test "_install_onlyoffice fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_onlyoffice
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_onlyoffice delegates to flatpak on pacman" {
  _get_package_manager() { echo "pacman"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_onlyoffice
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}

@test "_install_onlyoffice delegates to flatpak on dnf" {
  _get_package_manager() { echo "dnf"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_onlyoffice
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}

@test "_install_onlyoffice delegates to flatpak on apt" {
  _get_package_manager() { echo "apt"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_onlyoffice
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}
