#!/usr/bin/env bats

# Unit tests for setup-gimp.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-gimp.sh
}

@test "_install_gimp fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_gimp
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_gimp delegates to repo on pacman" {
  _get_package_manager() { echo "pacman"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to repo on dnf" {
  _get_package_manager() { echo "dnf"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to flatpak on apt" {
  _get_package_manager() { echo "apt"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.gimp.GIMP GIMP" ]]
}
