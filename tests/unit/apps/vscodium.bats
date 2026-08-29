#!/usr/bin/env bats

# Unit tests for setup-vscodium.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-vscodium.sh
}

@test "_install_vscodium fails when package manager is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_vscodium
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_vscodium on pacman installs code directly without repos" {
  _get_package_manager() { echo "pacman"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: code" ]]
}

@test "_install_vscodium on dnf adds repo and installs codium" {
  _get_package_manager() { echo "dnf"; }
  add_fedora_vscodium_repo() {
    echo "called add_fedora_vscodium_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_fedora_vscodium_repo" ]]
  [[ "$output" =~ "installed packages: codium" ]]
}

@test "_install_vscodium on apt adds repo and installs codium" {
  _get_package_manager() { echo "apt"; }
  add_debian_vscodium_repo() {
    echo "called add_debian_vscodium_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_debian_vscodium_repo" ]]
  [[ "$output" =~ "installed packages: codium" ]]
}
