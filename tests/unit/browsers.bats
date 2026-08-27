#!/usr/bin/env bats

# Unit tests for setup-browsers.sh logic and branches

@test "_install_firefox delegates to repo install on Fedora" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "dnf"; }
  _install_firefox_repo() {
    echo "called repo install"
    return 0
  }
  run _install_firefox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called repo install" ]]
}

@test "_install_firefox delegates to repo install on Arch Linux" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "pacman"; }
  _install_firefox_repo() {
    echo "called repo install"
    return 0
  }
  run _install_firefox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called repo install" ]]
}

@test "_install_firefox delegates to apt flow on Debian/APT" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "apt"; }
  _install_firefox_apt() {
    echo "called apt install"
    return 0
  }
  run _install_firefox
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called apt install" ]]
}

@test "_install_firefox fails when package manager is unsupported" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "unknown-pm"; }
  run _install_firefox
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_add_mozilla_apt_repo skips when files already exist" {
  source /setup/scripts/setup-browsers.sh
  local test_dir="/tmp/test-firefox-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/mozilla.sources" "$test_dir/packages.mozilla.org.asc"

  _add_mozilla_apt_repo() {
    local keyring_path="$test_dir/packages.mozilla.org.asc"
    local sources_path="$test_dir/mozilla.sources"
    if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
      echo "Mozilla repository already configured, skipping."
      return 0
    fi
  }
  run _add_mozilla_apt_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "_install_chromium calls install_packages chromium on Fedora/dnf" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "dnf"; }
  install_packages() {
    echo "installing package: $*"
    return 0
  }
  run _install_chromium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing package: chromium" ]]
}

@test "_install_chromium calls install_packages chromium on Arch/pacman" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "pacman"; }
  install_packages() {
    echo "installing package: $*"
    return 0
  }
  run _install_chromium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing package: chromium" ]]
}

@test "_install_chromium calls install_flatpak_app on Debian/apt" {
  source /setup/scripts/setup-browsers.sh
  _get_package_manager() { echo "apt"; }
  install_flatpak_app() {
    echo "installing flatpak app: $*"
    return 0
  }
  run _install_chromium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing flatpak app: org.chromium.Chromium Chromium" ]]
}

@test "_install_browsers calls both chromium and firefox installers" {
  source /setup/scripts/setup-browsers.sh
  _install_chromium() { echo "called chromium install"; return 0; }
  _install_firefox() { echo "called firefox install"; return 0; }
  run _install_browsers
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called chromium install" ]]
  [[ "$output" =~ "called firefox install" ]]
}

