#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-dbeaver.sh logic and branches

setup() {
  source /setup/scripts/setup-dbeaver.sh
}

@test "_install_dbeaver_flatpak skips when already installed" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo "io.dbeaver.DBeaverCommunity"
      return 0
    fi
    return 1
  }
  run _install_dbeaver_flatpak
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ installed,\ skipping ]]
}

@test "_install_dbeaver_flatpak installs via flatpak when not present" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo ""
      return 0
    fi
    if [ "$1" = "install" ]; then
      echo "flatpak installed: $*"
      return 0
    fi
    return 1
  }
  sudo() {
    "$@"
  }
  run _install_dbeaver_flatpak
  [ "$status" -eq 0 ]
  [[ "$output" =~ DBeaver\ Flatpak\ installed\ successfully ]]
}

@test "_install_dbeaver_repo calls install_packages dbeaver" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_dbeaver_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ dbeaver ]]
}

@test "_install_dbeaver fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_dbeaver
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ package\ manager ]]
}

@test "_install_dbeaver delegates to repo on pacman" {
  _get_package_manager() { echo "pacman"; }
  _install_dbeaver_repo() {
    echo "installed from pacman"
    return 0
  }
  run _install_dbeaver
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ pacman ]]
}

@test "_install_dbeaver delegates to flatpak on apt and dnf" {
  _get_package_manager() { echo "apt"; }
  _install_dbeaver_flatpak() {
    echo "installed from flatpak apt"
    return 0
  }
  run _install_dbeaver
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ flatpak\ apt ]]

  _get_package_manager() { echo "dnf"; }
  _install_dbeaver_flatpak() {
    echo "installed from flatpak dnf"
    return 0
  }
  run _install_dbeaver
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ flatpak\ dnf ]]
}
