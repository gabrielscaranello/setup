#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-cursor-theme.sh
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

@test "_install_cursor_files skips download when cursor is already installed" {
  _is_cursor_installed() { return 0; }
  download_file() {
    echo "SHOULD NOT BE CALLED"
    return 1
  }

  run _install_cursor_files
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cursor theme 'Bibata-Modern-Ice' is already installed. Skipping download." ]]
}

@test "_install_cursor_files downloads and extracts cursor files" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"
  _is_cursor_installed() { return 1; }

  download_file() {
    local target="$2"
    touch "$target"
  }

  tar() {
    # Mock extracting by creating the cursor dir in tmp_dir
    local tmp_dir="$4"
    mkdir -p "$tmp_dir/Bibata-Modern-Ice/cursors"
  }

  run _install_cursor_files
  [ "$status" -eq 0 ]
  [ -d "$mock_home/.local/share/icons/Bibata-Modern-Ice/cursors" ]
  [ -L "$mock_home/.icons/Bibata-Modern-Ice" ]
  rm -rf "$mock_home"
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
