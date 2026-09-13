#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/_theme_utils.sh
  MOCK_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$MOCK_DIR" 2> /dev/null || true
}

@test "is_theme_installed returns 0 when theme exists in user directory" {
  HOME="$MOCK_DIR"
  mkdir -p "$MOCK_DIR/.local/share/icons/MyTheme"

  run is_theme_installed "icons" "MyTheme"
  [ "$status" -eq 0 ]
}

@test "is_theme_installed returns 0 when theme exists in legacy user directory" {
  HOME="$MOCK_DIR"
  mkdir -p "$MOCK_DIR/.themes/MyGtkTheme"

  run is_theme_installed "themes" "MyGtkTheme"
  [ "$status" -eq 0 ]
}

@test "is_theme_installed returns 0 when theme with subpath exists" {
  HOME="$MOCK_DIR"
  mkdir -p "$MOCK_DIR/.local/share/icons/MyCursor/cursors"

  run is_theme_installed "icons" "MyCursor" "cursors"
  [ "$status" -eq 0 ]
}

@test "is_theme_installed returns 1 when theme does not exist" {
  HOME="$MOCK_DIR"

  run is_theme_installed "icons" "NonExistent"
  [ "$status" -eq 1 ]
}

@test "is_theme_installed returns 1 when subpath does not exist" {
  HOME="$MOCK_DIR"
  mkdir -p "$MOCK_DIR/.local/share/icons/MyCursor"

  run is_theme_installed "icons" "MyCursor" "cursors"
  [ "$status" -eq 1 ]
}

@test "get_theme_local_version returns version from user directory" {
  HOME="$MOCK_DIR"
  mkdir -p "$MOCK_DIR/.local/share/icons/MyTheme"
  echo "v1.2.3" > "$MOCK_DIR/.local/share/icons/MyTheme/.version"

  run get_theme_local_version "icons" "MyTheme"
  [ "$status" -eq 0 ]
  [ "$output" = "v1.2.3" ]
}

@test "get_theme_local_version returns empty when no version file exists" {
  HOME="$MOCK_DIR"
  mkdir -p "$MOCK_DIR/.local/share/icons/MyTheme"

  run get_theme_local_version "icons" "MyTheme"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "deploy_theme_directory installs theme to user directory and creates symlink" {
  HOME="$MOCK_DIR"
  local src="$MOCK_DIR/extracted_theme"
  mkdir -p "$src"
  touch "$src/index.theme"

  run deploy_theme_directory "$src" "icons" "CustomTheme"
  [ "$status" -eq 0 ]
  [ -d "$MOCK_DIR/.local/share/icons/CustomTheme" ]
  [ -f "$MOCK_DIR/.local/share/icons/CustomTheme/index.theme" ]
  [ -L "$MOCK_DIR/.icons/CustomTheme" ]
  [ "$(readlink "$MOCK_DIR/.icons/CustomTheme")" = "$MOCK_DIR/.local/share/icons/CustomTheme" ]
}

@test "deploy_theme_directory returns 0 gracefully if source does not exist" {
  run deploy_theme_directory "$MOCK_DIR/nonexistent" "icons" "CustomTheme"
  [ "$status" -eq 0 ]
}

@test "is_package_installed checks package manager on Debian, Fedora, and Arch" {
  get_distro_id() { echo "debian"; }
  dpkg() { return 0; }
  run is_package_installed "papirus-icon-theme"
  [ "$status" -eq 0 ]

  get_distro_id() { echo "fedora"; }
  rpm() { return 0; }
  run is_package_installed "papirus-icon-theme"
  [ "$status" -eq 0 ]

  get_distro_id() { echo "arch"; }
  pacman() { return 0; }
  run is_package_installed "papirus-icon-theme"
  [ "$status" -eq 0 ]
}

@test "is_package_installed returns 1 on unsupported distribution package" {
  get_distro_id() { echo "debian"; }
  run is_package_installed "adw-gtk3-theme"
  [ "$status" -eq 1 ]
}
