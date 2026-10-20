#!/usr/bin/env bats

# Unit tests for setup-gimp.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-gimp.sh
}

@test "_install_gimp fails when distribution is unsupported" {
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run _install_gimp
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_gimp delegates to repo on arch" {
  require_supported_distro() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to repo on fedora" {
  require_supported_distro() { echo "fedora"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to flatpak on debian" {
  require_supported_distro() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.gimp.GIMP GIMP" ]]
}

@test "_install_gimp delegates to repo on openSUSE Tumbleweed" {
  require_supported_distro() { echo "opensuse-tumbleweed"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: gimp" ]]
}

@test "_install_gimp delegates to flatpak on openSUSE Leap" {
  require_supported_distro() { echo "opensuse-leap"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: org.gimp.GIMP GIMP" ]]
}

@test "_install_gimp purges native gimp on debian when present" {
  require_supported_distro() { echo "debian"; }
  install_flatpak_app() { return 0; }
  dpkg() { return 0; }
  sudo() { echo "sudo $*"; return 0; }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo apt purge -y gimp" ]]
}

@test "_install_gimp removes and locks native gimp on openSUSE Leap when present" {
  _get_package_manager() { echo "zypper"; }
  require_supported_distro() { echo "opensuse-leap"; }
  install_flatpak_app() { return 0; }
  rpm() { return 0; }
  sudo() { echo "sudo $*"; return 0; }
  run _install_gimp
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo zypper --non-interactive remove -u gimp" ]]
  [[ "$output" =~ "sudo zypper --non-interactive addlock gimp" ]]
}

@test "main executes successfully and reports complete" {
  _install_gimp() {
    echo "called _install_gimp"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up GIMP..." ]]
  [[ "$output" =~ "called _install_gimp" ]]
  [[ "$output" =~ "setup-gimp complete" ]]
}
