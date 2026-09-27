#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-cinnamon-applets-config.sh 2> /dev/null || source scripts/desktop/setup-cinnamon-applets-config.sh
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not Cinnamon). Skipping Cinnamon panel and applets configuration." ]]
}

@test "main skips when desktop environment is gnome" {
  get_desktop_environment() { echo "gnome"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'gnome' (not Cinnamon). Skipping Cinnamon panel and applets configuration." ]]
}

@test "main proceeds when desktop environment is cinnamon" {
  get_desktop_environment() { echo "cinnamon"; }
  _configure_cinnamon_panel() { echo "mock configure panel"; }
  configure_cinnamon_favorite_apps() { echo "mock configure favorites"; }
  _configure_spices_settings() { echo "mock configure spices"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting Cinnamon panel and applets configuration..." ]]
  [[ "$output" =~ "mock configure panel" ]]
  [[ "$output" =~ "mock configure favorites" ]]
  [[ "$output" =~ "mock configure spices" ]]
  [[ "$output" =~ "Cinnamon panel and applets configuration completed successfully." ]]
}

@test "_configure_cinnamon_panel calls dconf_exec and gsettings_exec" {
  ensure_dconf() { return 0; }
  load_dconf_file() { echo "load_dconf_file: $*"; }
  dconf_exec() { echo "dconf_exec: $*"; }
  gsettings_exec() { echo "gsettings_exec: $*"; }
  command() { return 0; }

  run _configure_cinnamon_panel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Cinnamon panel layout..." ]]
  [[ "$output" =~ "dconf_exec: write /org/cinnamon/panels-enabled" ]]
  [[ "$output" =~ "dconf_exec: write /org/cinnamon/enabled-applets" ]]
  [[ "$output" =~ "gsettings_exec: set org.cinnamon panels-enabled" ]]
  [[ "$output" =~ "gsettings_exec: set org.cinnamon enabled-applets" ]]
}

@test "_configure_spices_settings writes applet configuration files" {
  local mock_home
  mock_home="$(mktemp -d)"
  SPICES_CONFIG_DIR="$mock_home/.config/cinnamon/spices"
  get_favorite_apps() {
    printf "%s\n" "nemo.desktop" "kitty.desktop"
  }

  run _configure_spices_settings
  [ "$status" -eq 0 ]
  [ -f "$SPICES_CONFIG_DIR/calendar@cinnamon.org/15.json" ]
  [ -f "$SPICES_CONFIG_DIR/color-picker@fmete/color-picker@fmete.json" ]
  [ -f "$SPICES_CONFIG_DIR/color-picker@fmete/3.json" ]
  [ -f "$SPICES_CONFIG_DIR/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json" ]
  [ -f "$SPICES_CONFIG_DIR/grouped-window-list@cinnamon.org/2.json" ]

  # Check that pinned apps were injected
  if command -v python3 > /dev/null 2>&1; then
    run grep -q "kitty.desktop" "$SPICES_CONFIG_DIR/grouped-window-list@cinnamon.org/2.json"
    [ "$status" -eq 0 ]
  fi

  rm -rf "$mock_home"
}

@test "configure_cinnamon_favorite_apps writes favorite-apps" {
  dconf_exec() { echo "dconf_exec: $*"; }
  gsettings_exec() { echo "gsettings_exec: $*"; }
  command() { return 0; }
  get_favorite_apps() {
    printf "%s\n" "nemo.desktop" "kitty.desktop"
  }

  run configure_cinnamon_favorite_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Cinnamon favorite applications..." ]]
  [[ "$output" =~ "dconf_exec: write /org/cinnamon/favorite-apps ['nemo.desktop', 'kitty.desktop']" ]]
  [[ "$output" =~ "gsettings_exec: set org.cinnamon favorite-apps ['nemo.desktop', 'kitty.desktop']" ]]
}
