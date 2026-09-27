#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-cinnamon-preferences.sh 2> /dev/null || source scripts/desktop/setup-cinnamon-preferences.sh
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not Cinnamon). Skipping Cinnamon preferences configuration." ]]
}

@test "main skips when desktop environment is gnome" {
  get_desktop_environment() { echo "gnome"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'gnome' (not Cinnamon). Skipping Cinnamon preferences configuration." ]]
}

@test "main skips when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'plasma' (not Cinnamon). Skipping Cinnamon preferences configuration." ]]
}

@test "main proceeds when desktop environment is cinnamon" {
  get_desktop_environment() { echo "cinnamon"; }
  _apply_dconf_profiles() { echo "mock apply dconf profiles"; }
  _apply_direct_settings() { echo "mock apply direct settings"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting Cinnamon desktop preferences configuration..." ]]
  [[ "$output" =~ "mock apply dconf profiles" ]]
  [[ "$output" =~ "mock apply direct settings" ]]
  [[ "$output" =~ "Cinnamon desktop preferences configuration completed successfully." ]]
}

@test "_apply_dconf_profiles ensures dconf and loads dconf files" {
  ensure_dconf() { return 0; }
  load_dconf_files() {
    echo "load_dconf_files called for dir: $1 with ${*:2}"
    return 0
  }

  run _apply_dconf_profiles
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying Cinnamon dconf configuration profiles..." ]]
  [[ "$output" =~ "load_dconf_files called for dir:" ]]
  [[ "$output" =~ "window-manager.dconf" ]]
  [[ "$output" =~ "night-light.dconf" ]]
  [[ "$output" =~ "nemo.dconf" ]]
  [[ "$output" =~ "sounds.dconf" ]]
  [[ "$output" =~ "hotcorners.dconf" ]]
  [[ "$output" =~ "keybindings.dconf" ]]
}

@test "_apply_direct_settings calls dconf_exec and gsettings_exec for preferences" {
  dconf_exec() { echo "dconf_exec: $*"; }
  gsettings_exec() { echo "gsettings_exec: $*"; }
  command() { return 0; }

  run _apply_direct_settings
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Cinnamon window manager and ergonomic preferences..." ]]
  [[ "$output" =~ "dconf_exec: write /org/cinnamon/desktop/wm/preferences/button-layout ':close'" ]]
  [[ "$output" =~ "dconf_exec: write /org/cinnamon/muffin/placement-mode 'center'" ]]
  [[ "$output" =~ "dconf_exec: write /org/nemo/desktop/desktop-layout 'false::false'" ]]
  [[ "$output" =~ "gsettings_exec: set org.cinnamon.desktop.wm.preferences button-layout ':close'" ]]
  [[ "$output" =~ "gsettings_exec: set org.cinnamon.muffin placement-mode 'center'" ]]
  [[ "$output" =~ "gsettings_exec: set org.nemo.desktop desktop-layout 'false::false'" ]]
}
