#!/usr/bin/env bats

# Integration tests for _utils.sh in a live distro environment

setup() {
  source /setup/scripts/_utils.sh
}

@test "_get_package_manager successfully identifies the distribution package manager" {
  run _get_package_manager
  [ "$status" -eq 0 ]
  [ "$output" = "apt" ] || [ "$output" = "dnf" ] || [ "$output" = "pacman" ]
}

@test "get_distro_id identifies supported distro in container environment" {
  run get_distro_id
  [ "$status" -eq 0 ]
  [ "$output" = "debian" ] || [ "$output" = "fedora" ] || [ "$output" = "arch" ]
}

@test "install_packages can successfully install a lightweight utility" {
  # curl is expected to install or already be present
  run install_packages curl
  [ "$status" -eq 0 ]
  command -v curl
}
