#!/usr/bin/env bats

# Unit tests for setup-mongodb-compass.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-mongodb-compass.sh
}

@test "main fails when distribution is unsupported" {
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "main installs MongoDB Compass via flatpak on arch" {
  require_supported_distro() { echo "arch"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: com.mongodb.Compass MongoDB Compass" ]]
}

@test "main installs MongoDB Compass via flatpak on fedora" {
  require_supported_distro() { echo "fedora"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: com.mongodb.Compass MongoDB Compass" ]]
}

@test "main installs MongoDB Compass via flatpak on debian" {
  require_supported_distro() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: com.mongodb.Compass MongoDB Compass" ]]
}
