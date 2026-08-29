#!/usr/bin/env bats

# Unit tests for setup-screenshot.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-screenshot-tool.sh
}

@test "_install_screenshot_tool fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_screenshot_tool
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_screenshot_tool installs flameshot on GNOME" {
  _get_package_manager() { echo "pacman"; }
  get_desktop_environment() { echo "gnome"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: flameshot" ]]
}

@test "_install_screenshot_tool installs spectacle on KDE Plasma" {
  _get_package_manager() { echo "dnf"; }
  get_desktop_environment() { echo "plasma"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: spectacle" ]]
}

@test "_install_screenshot_tool skips and does nothing on unknown desktop environment" {
  _get_package_manager() { echo "apt"; }
  get_desktop_environment() { echo "unknown"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unrecognized desktop environment: unknown. Skipping screenshot tool setup." ]]
  [[ ! "$output" =~ "installed packages" ]]
}
