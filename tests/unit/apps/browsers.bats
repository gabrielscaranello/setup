#!/usr/bin/env bats

# Unit tests for setup-browsers.sh logic and branches

@test "_install_firefox delegates to repo install on Fedora" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "fedora"; }
  _install_firefox_repo() {
    echo "called repo install"
    return 0
  }
  run _install_firefox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called repo install" ]]
}

@test "_install_firefox delegates to repo install on Arch Linux" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "arch"; }
  _install_firefox_repo() {
    echo "called repo install"
    return 0
  }
  run _install_firefox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called repo install" ]]
}

@test "_install_firefox delegates to apt flow on Debian/APT" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "debian"; }
  _install_firefox_apt() {
    echo "called apt install"
    return 0
  }
  run _install_firefox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called apt install" ]]
}

@test "_install_firefox_apt calls add_debian_mozilla_repo and installs firefox" {
  source /setup/scripts/apps/setup-browsers.sh
  _remove_firefox_esr_apt() { return 0; }
  add_debian_mozilla_repo() {
    echo "called add_debian_mozilla_repo"
    return 0
  }
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_firefox_apt
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_debian_mozilla_repo" ]]
  [[ "$output" =~ "installing packages: firefox firefox-i18n-pt-br" ]]
}

@test "_install_firefox fails when distribution is unsupported" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_firefox
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_chromium calls install_packages chromium on Fedora" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "fedora"; }
  install_packages() {
    echo "installing package: $*"
    return 0
  }
  run _install_chromium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing package: chromium" ]]
}

@test "_install_chromium calls install_packages chromium on Arch" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "installing package: $*"
    return 0
  }
  run _install_chromium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing package: chromium" ]]
}

@test "_install_chromium calls install_flatpak_app on Debian" {
  source /setup/scripts/apps/setup-browsers.sh
  get_distro_id() { echo "debian"; }
  install_flatpak_app() {
    echo "installing flatpak app: $*"
    return 0
  }
  run _install_chromium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing flatpak app: org.chromium.Chromium Chromium" ]]
}

@test "_install_browsers calls both chromium and firefox installers" {
  source /setup/scripts/apps/setup-browsers.sh
  _install_chromium() { echo "called chromium install"; return 0; }
  _install_firefox() { echo "called firefox install"; return 0; }
  run _install_browsers
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called chromium install" ]]
  [[ "$output" =~ "called firefox install" ]]
}
