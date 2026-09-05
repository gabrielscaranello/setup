#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-cursor-theme.sh
  sudo rm -rf "/usr/share/icons/$CURSOR_NAME" 2> /dev/null || true
}

teardown() {
  sudo rm -rf "/usr/share/icons/$CURSOR_NAME" 2> /dev/null || true
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (unsupported or unrecognized). Skipping cursor theme setup." ]]
}

@test "main skips when desktop environment is unsupported" {
  get_desktop_environment() { echo "xfce"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'xfce' (unsupported or unrecognized). Skipping cursor theme setup." ]]
}

@test "main proceeds when desktop environment is gnome" {
  get_desktop_environment() { echo "gnome"; }
  _is_cursor_installed() { return 0; }
  _configure_gnome_cursor() { echo "configured gnome cursor"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Bibata-Modern-Ice cursor theme for gnome..." ]]
  [[ "$output" =~ "configured gnome cursor" ]]
  [[ "$output" =~ "Cursor theme setup completed successfully." ]]
}

@test "main proceeds when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }
  _is_cursor_installed() { return 0; }
  _configure_plasma_cursor() { echo "configured plasma cursor"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Bibata-Modern-Ice cursor theme for plasma..." ]]
  [[ "$output" =~ "configured plasma cursor" ]]
  [[ "$output" =~ "Cursor theme setup completed successfully." ]]
}

@test "_is_cursor_installed returns 0 when cursors exist in user directory" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"
  mkdir -p "$HOME/.local/share/icons/Bibata-Modern-Ice/cursors"

  run _is_cursor_installed
  [ "$status" -eq 0 ]
  rm -rf "$mock_home"
}

@test "_is_cursor_installed returns 1 when cursors directory does not exist" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _is_cursor_installed
  [ "$status" -eq 1 ]
  rm -rf "$mock_home"
}

@test "_ensure_cursor_theme calls _install_cursor_files when cursor is not installed" {
  _is_cursor_installed() { return 1; }
  _install_cursor_files() { echo "installing cursor files: $*"; }

  run _ensure_cursor_theme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installing cursor files:" ]]
}

@test "_ensure_cursor_theme updates when newer version is available" {
  _is_cursor_installed() { return 0; }
  _get_local_version() { echo "v2.0.6"; }
  _fetch_remote_version() { echo "v2.0.7"; }
  _install_cursor_files() { echo "updated to $1"; }

  run _ensure_cursor_theme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Updating Bibata-Modern-Ice cursor theme from GitHub (v2.0.6 -> v2.0.7)..." ]]
  [[ "$output" =~ "updated to v2.0.7" ]]
}

@test "_ensure_cursor_theme skips download when cursor is up to date" {
  _is_cursor_installed() { return 0; }
  _get_local_version() { echo "v2.0.7"; }
  _fetch_remote_version() { echo "v2.0.7"; }
  _install_cursor_files() {
    echo "SHOULD NOT BE CALLED"
    return 1
  }

  run _ensure_cursor_theme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cursor theme 'Bibata-Modern-Ice' is up to date (v2.0.7)." ]]
}

@test "_install_cursor_files downloads, extracts and writes version file" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  install_packages() { return 0; }
  sudo() { :; }
  download_file() {
    local target="$2"
    touch "$target"
  }

  tar() {
    local tmp_dir="$4"
    mkdir -p "$tmp_dir/Bibata-Modern-Ice/cursors"
  }

  run _install_cursor_files "v2.0.7"
  [ "$status" -eq 0 ]
  [ -d "$mock_home/.local/share/icons/Bibata-Modern-Ice/cursors" ]
  [ -L "$mock_home/.icons/Bibata-Modern-Ice" ]
  [ -f "$mock_home/.local/share/icons/Bibata-Modern-Ice/.version" ]
  [ "$(cat "$mock_home/.local/share/icons/Bibata-Modern-Ice/.version")" = "v2.0.7" ]
  rm -rf "$mock_home"
}

@test "_get_local_version reads version file correctly" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "" ]

  mkdir -p "$mock_home/.local/share/icons/Bibata-Modern-Ice"
  echo "v2.0.7" > "$mock_home/.local/share/icons/Bibata-Modern-Ice/.version"

  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "v2.0.7" ]

  rm -rf "$mock_home"
}

@test "_fetch_remote_version extracts tag_name from GitHub API response" {
  fetch_url() {
    echo '{"tag_name": "v2.0.7", "name": "Release v2.0.7"}'
  }

  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "v2.0.7" ]
}

@test "_configure_gnome_cursor invokes gsettings" {
  gsettings() {
    echo "gsettings called: $*"
  }

  run _configure_gnome_cursor
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings called: set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice" ]]
  [[ "$output" =~ "gsettings called: set org.gnome.desktop.interface cursor-size 20" ]]
}

@test "_configure_plasma_cursor invokes kwriteconfig6 and kapplymousetheme" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  kwriteconfig6() {
    echo "kwriteconfig6 called: $*"
  }
  kapplymousetheme() {
    echo "kapplymousetheme called: $*"
  }

  run _configure_plasma_cursor
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kwriteconfig6 called: --file kcminputrc --group Mouse --key cursorTheme Bibata-Modern-Ice" ]]
  [[ "$output" =~ "kwriteconfig6 called: --file kcminputrc --group Mouse --key cursorSize 20" ]]
  [[ "$output" =~ "kapplymousetheme called: Bibata-Modern-Ice" ]]
  [ -f "$mock_home/.icons/default/index.theme" ]
  rm -rf "$mock_home"
}

@test "_configure_plasma_cursor falls back to kwriteconfig5" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  # kwriteconfig6 does not exist, kwriteconfig5 is mocked
  kwriteconfig5() {
    echo "kwriteconfig5 called: $*"
  }

  run _configure_plasma_cursor
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kwriteconfig5 called: --file kcminputrc --group Mouse --key cursorTheme Bibata-Modern-Ice" ]]
  rm -rf "$mock_home"
}
