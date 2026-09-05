#!/usr/bin/env bats

# Unit tests for setup-vscodium.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-vscodium.sh
}

@test "_install_vscodium fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_vscodium
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_vscodium on arch installs code directly without repos" {
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: code" ]]
}

@test "_install_vscodium on fedora adds repo and installs codium" {
  get_distro_id() { echo "fedora"; }
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

@test "_install_vscodium on debian adds repo and installs codium" {
  get_distro_id() { echo "debian"; }
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
