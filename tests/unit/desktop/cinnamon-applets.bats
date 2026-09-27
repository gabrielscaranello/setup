#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-cinnamon-applets.sh 2> /dev/null || source scripts/desktop/setup-cinnamon-applets.sh
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not Cinnamon). Skipping Cinnamon Spices setup." ]]
}

@test "main skips when desktop environment is gnome" {
  get_desktop_environment() { echo "gnome"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'gnome' (not Cinnamon). Skipping Cinnamon Spices setup." ]]
}

@test "main proceeds when desktop environment is cinnamon" {
  get_desktop_environment() { echo "cinnamon"; }
  install_packages() { return 0; }
  _install_spice() { echo "installed spice: $*"; }
  _enable_cinnamon_extensions() { echo "enabled extensions: $*"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Cinnamon Spices (applets and extensions)..." ]]
  [[ "$output" =~ "installed spice: applets color-picker@fmete" ]]
  [[ "$output" =~ "installed spice: extensions transparent-panels-reloaded@marcelovbcfilho" ]]
  [[ "$output" =~ "enabled extensions: transparent-panels-reloaded@marcelovbcfilho" ]]
  [[ "$output" =~ "Cinnamon Spices setup completed successfully." ]]
}

@test "_is_spice_installed returns 0 when directory exists" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  mkdir -p "$mock_home/.local/share/cinnamon/applets/color-picker@fmete"
  run _is_spice_installed "applets" "color-picker@fmete"
  [ "$status" -eq 0 ]

  rm -rf "$mock_home"
}

@test "_is_spice_installed returns 1 when directory does not exist" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  run _is_spice_installed "applets" "color-picker@fmete"
  [ "$status" -eq 1 ]

  rm -rf "$mock_home"
}

@test "_install_spice skips when already installed" {
  _is_spice_installed() { return 0; }

  run _install_spice "applets" "color-picker@fmete"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Spice 'color-picker@fmete' (applets) is already installed." ]]
}

@test "_install_spice downloads and unzips when not installed" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"

  _is_spice_installed() { return 1; }
  download_file() { touch "$2"; return 0; }
  unzip() {
    local target_dir="${!#}"
    mkdir -p "$target_dir/color-picker@fmete"
  }

  run _install_spice "applets" "color-picker@fmete"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing 'color-picker@fmete' (applets)..." ]]
  [[ "$output" =~ "Successfully installed 'color-picker@fmete'." ]]
  [ -d "$mock_home/.local/share/cinnamon/applets/color-picker@fmete" ]

  rm -rf "$mock_home"
}

@test "_install_spice fails gracefully on download failure" {
  _is_spice_installed() { return 1; }
  download_file() { return 1; }

  run _install_spice "applets" "bad-spice@example"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to download spice package for 'bad-spice@example'." ]]
}

@test "_merge_cinnamon_extensions merges new UUIDs with existing ones" {
  local current="['existing-one@author', 'existing-two@author']"
  local result
  result="$(_merge_cinnamon_extensions "$current" "new-ext@author" "existing-one@author")"

  [ "$result" = "['existing-one@author', 'existing-two@author', 'new-ext@author']" ]
}

@test "_merge_cinnamon_extensions handles empty current string" {
  local result
  result="$(_merge_cinnamon_extensions "" "new-ext@author")"

  [ "$result" = "['new-ext@author']" ]
}

@test "_enable_cinnamon_extensions invokes dconf and gsettings" {
  dconf() {
    echo "dconf called: $*"
  }
  gsettings() {
    echo "gsettings called: $*"
  }

  run _enable_cinnamon_extensions "test-ext@author"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf called: write /org/cinnamon/enabled-extensions ['test-ext@author']" ]]
  [[ "$output" =~ "gsettings called: set org.cinnamon enabled-extensions ['test-ext@author']" ]]
}
