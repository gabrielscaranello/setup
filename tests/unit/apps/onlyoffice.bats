#!/usr/bin/env bats

# Unit tests for setup-onlyoffice.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-onlyoffice.sh
}

@test "main fails when distribution is unsupported" {
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "main installs ONLYOFFICE via flatpak on arch" {
  require_supported_distro() { echo "arch"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}

@test "main installs ONLYOFFICE via flatpak on fedora" {
  require_supported_distro() { echo "fedora"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}

@test "main installs ONLYOFFICE via flatpak on debian" {
  require_supported_distro() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}
