#!/usr/bin/env bats

# Unit tests for setup-gimp.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-gimp.sh
}

@test "_install_gimp fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_gimp
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_gimp delegates to repo on arch" {
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to repo on fedora" {
  get_distro_id() { echo "fedora"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to flatpak on debian" {
  get_distro_id() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.gimp.GIMP GIMP" ]]
}
