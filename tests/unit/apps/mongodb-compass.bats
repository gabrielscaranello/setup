#!/usr/bin/env bats

# Unit tests for setup-mongodb-compass.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-mongodb-compass.sh
}

@test "_install_mongodb_compass fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_mongodb_compass
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_mongodb_compass delegates to flatpak on arch" {
  get_distro_id() { echo "arch"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_mongodb_compass
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: mongodb.Compass MongoDB Compass" ]]
}

@test "_install_mongodb_compass delegates to flatpak on fedora" {
  get_distro_id() { echo "fedora"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_mongodb_compass
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: mongodb.Compass MongoDB Compass" ]]
}

@test "_install_mongodb_compass delegates to flatpak on debian" {
  get_distro_id() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_mongodb_compass
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: mongodb.Compass MongoDB Compass" ]]
}
