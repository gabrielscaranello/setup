#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  TEST_TMP_DIR="$(mktemp -d)"
  export HOME="$TEST_TMP_DIR"
  source /setup/scripts/desktop/setup-cinnamon-spices.sh 2> /dev/null || source scripts/desktop/setup-cinnamon-spices.sh

  command() {
    if [ "${1:-}" = "-v" ] && { [ "${2:-}" = "gsettings" ] || [ "${2:-}" = "unzip" ]; }; then return 0; fi
    builtin command "$@"
  }
}

teardown() {
  rm -rf "$TEST_TMP_DIR"
}

@test "main skips when desktop environment is not cinnamon (gnome)" {
  get_desktop_environment() { echo "gnome"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'gnome' (not Cinnamon). Skipping Cinnamon spices setup." ]]
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not Cinnamon). Skipping Cinnamon spices setup." ]]
}

@test "main fails when ensure_dconf fails on cinnamon" {
  get_desktop_environment() { echo "cinnamon"; }
  ensure_dconf() { return 1; }

  run main
  [ "$status" -eq 1 ]
}

@test "_install_cinnamon_spice respects CINNAMON_SPICES_SKIP_INSTALL" {
  export CINNAMON_SPICES_SKIP_INSTALL=1

  run _install_cinnamon_spice "color-picker@fmete" "applets"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "CINNAMON_SPICES_SKIP_INSTALL is active" ]]
}

@test "_install_cinnamon_spice skips if already installed" {
  local applet_dir="$HOME/.local/share/cinnamon/applets/color-picker@fmete"
  mkdir -p "$applet_dir"
  touch "$applet_dir/metadata.json"

  run _install_cinnamon_spice "color-picker@fmete" "applets"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed" ]]
}

@test "_install_cinnamon_spice downloads and extracts archive" {
  download_file() {
    local url="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    touch "$dest"
    return 0
  }
  unzip() {
    local zip="$2"
    local dest="$4"
    mkdir -p "$dest/test-spice@domain"
    touch "$dest/test-spice@domain/metadata.json"
    return 0
  }

  run _install_cinnamon_spice "test-spice@domain" "applets"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successfully installed Cinnamon spice 'test-spice@domain'" ]]
}

@test "_configure_color_picker_settings creates json settings file" {
  run _configure_color_picker_settings
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/cinnamon/spices/color-picker@fmete/color-picker@fmete.json" ]
  grep -q "HEX-Color: #xxxxxx" "$HOME/.config/cinnamon/spices/color-picker@fmete/color-picker@fmete.json"
}

@test "_configure_transparent_panels_settings creates json settings file" {
  run _configure_transparent_panels_settings
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/cinnamon/spices/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json" ]
  grep -q "panel-transparent-with-shadow" "$HOME/.config/cinnamon/spices/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json"
}

@test "_enable_cinnamon_applet skips if already enabled" {
  gsettings_exec() {
    if [ "$1" = "get" ] && [ "$2" = "org.cinnamon" ] && [ "$3" = "enabled-applets" ]; then
      echo "['panel1:left:0:menu@cinnamon.org:0', 'panel1:right:0:color-picker@fmete:21']"
      return 0
    fi
    return 0
  }

  run _enable_cinnamon_applet "color-picker@fmete"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applet 'color-picker@fmete' is already enabled." ]]
}

@test "_enable_cinnamon_applet registers applet with next id" {
  gsettings_exec() {
    if [ "$1" = "set" ]; then
      echo "gsettings: $*"
      return 0
    fi
    if [ "$1" = "get" ] && [ "$2" = "org.cinnamon" ] && [ "$3" = "enabled-applets" ]; then
      echo "['panel1:left:0:menu@cinnamon.org:0']"
      return 0
    elif [ "$1" = "get" ] && [ "$2" = "org.cinnamon" ] && [ "$3" = "next-applet-id" ]; then
      echo "25"
      return 0
    fi
    return 0
  }

  run _enable_cinnamon_applet "color-picker@fmete" "panel1" "right" "0"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling Cinnamon applet: panel1:right:0:color-picker@fmete:25" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon next-applet-id 26" ]]
  [[ "$output" =~ "panel1:right:0:color-picker@fmete:25" ]]
}

@test "_enable_cinnamon_extension skips if already enabled" {
  gsettings_exec() {
    if [ "$1" = "get" ] && [ "$2" = "org.cinnamon" ] && [ "$3" = "enabled-extensions" ]; then
      echo "['transparent-panels-reloaded@marcelovbcfilho']"
      return 0
    fi
    return 0
  }

  run _enable_cinnamon_extension "transparent-panels-reloaded@marcelovbcfilho"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Extension 'transparent-panels-reloaded@marcelovbcfilho' is already enabled." ]]
}

@test "_enable_cinnamon_extension registers extension in enabled-extensions" {
  gsettings_exec() {
    echo "gsettings: $*"
    if [ "$1" = "get" ] && [ "$2" = "org.cinnamon" ] && [ "$3" = "enabled-extensions" ]; then
      echo "@as []"
      return 0
    fi
    return 0
  }

  run _enable_cinnamon_extension "transparent-panels-reloaded@marcelovbcfilho"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling Cinnamon extension: transparent-panels-reloaded@marcelovbcfilho" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon enabled-extensions ['transparent-panels-reloaded@marcelovbcfilho']" ]]
}

@test "_copy_cinnamon_spices_config copies spices templates" {
  local test_root="$TEST_TMP_DIR/repo"
  mkdir -p "$test_root/config/cinnamon/spices/sample@spice"
  echo '{"test": 1}' > "$test_root/config/cinnamon/spices/sample@spice/sample.json"

  get_repo_root() { echo "$test_root"; }

  run _copy_cinnamon_spices_config
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/cinnamon/spices/sample@spice/sample.json" ]
}
