#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-dbeaver.sh logic and branches

setup() {
  source /setup/scripts/setup-dbeaver.sh
}

@test "_install_dbeaver fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_dbeaver
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ package\ manager ]]
}

@test "_install_dbeaver delegates to repo on pacman" {
  _get_package_manager() { echo "pacman"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_dbeaver
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ packages:\ dbeaver ]]
}

@test "_install_dbeaver delegates to flatpak on apt and dnf" {
  _get_package_manager() { echo "apt"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_dbeaver
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ io.dbeaver.DBeaverCommunity\ DBeaver ]]

  _get_package_manager() { echo "dnf"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_dbeaver
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ io.dbeaver.DBeaverCommunity\ DBeaver ]]
}
