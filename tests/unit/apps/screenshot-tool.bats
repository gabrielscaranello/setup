#!/usr/bin/env bats

# Unit tests for setup-screenshot.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-screenshot-tool.sh
}

@test "_install_screenshot_tool fails when distribution is unsupported" {
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run _install_screenshot_tool
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_configure_flameshot_portal_permission executes dbus-send if available" {
  dbus-send() {
    echo "dbus-send called with: $*"
    return 0
  }
  run _configure_flameshot_portal_permission
  [ "$status" -eq 0 ]
  [[ "$output" =~ "org.freedesktop.impl.portal.PermissionStore" ]]
  [[ "$output" =~ "org.flameshot.Flameshot" ]]
}

@test "_install_screenshot_tool installs flameshot and configures portal permissions on GNOME" {
  require_supported_distro() { echo "arch"; }
  get_desktop_environment() { echo "gnome"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  _configure_flameshot_portal_permission() {
    echo "mocked _configure_flameshot_portal_permission"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: flameshot" ]]
  [[ "$output" =~ "mocked _configure_flameshot_portal_permission" ]]
}

@test "_install_screenshot_tool installs flameshot and configures portal permissions on Cinnamon" {
  require_supported_distro() { echo "linuxmint"; }
  get_desktop_environment() { echo "cinnamon"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  _configure_flameshot_portal_permission() {
    echo "mocked _configure_flameshot_portal_permission"
    return 0
  }
  run _install_screenshot_tool
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Flameshot for Cinnamon..." ]]
  [[ "$output" =~ "installed packages: flameshot" ]]
  [[ "$output" =~ "mocked _configure_flameshot_portal_permission" ]]
}

@test "_install_screenshot_tool installs spectacle on KDE Plasma" {
  require_supported_distro() { echo "fedora"; }
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
  require_supported_distro() { echo "debian"; }
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

@test "main executes _install_screenshot_tool" {
  _install_screenshot_tool() {
    echo "mocked _install_screenshot_tool"
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mocked _install_screenshot_tool" ]]
  [[ "$output" =~ "setup-screenshot complete" ]]
}
