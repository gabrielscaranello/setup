#!/usr/bin/env bats

# Unit tests for setup-onlyoffice.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-onlyoffice.sh
}

@test "_install_onlyoffice fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_onlyoffice
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_onlyoffice delegates to flatpak on arch" {
  get_distro_id() { echo "arch"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_onlyoffice
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}

@test "_install_onlyoffice delegates to flatpak on fedora" {
  get_distro_id() { echo "fedora"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_onlyoffice
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}

@test "_install_onlyoffice delegates to flatpak on debian" {
  get_distro_id() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_onlyoffice
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.onlyoffice.desktopeditors ONLYOFFICE" ]]
}
