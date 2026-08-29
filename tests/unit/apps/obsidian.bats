#!/usr/bin/env bats

# Unit tests for setup-obsidian.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-obsidian.sh
}

@test "_install_obsidian fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_obsidian
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_obsidian delegates to repo on pacman" {
  _get_package_manager() { echo "pacman"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_obsidian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: obsidian" ]]
}

@test "_install_obsidian delegates to flatpak on dnf" {
  _get_package_manager() { echo "dnf"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_obsidian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: md.obsidian.Obsidian Obsidian" ]]
}

@test "_install_obsidian delegates to flatpak on apt" {
  _get_package_manager() { echo "apt"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_obsidian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: md.obsidian.Obsidian Obsidian" ]]
}
