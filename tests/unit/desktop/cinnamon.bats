#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-cinnamon.sh 2> /dev/null || source scripts/desktop/setup-cinnamon.sh
}

teardown() {
  :
}

@test "main skips when desktop environment is not cinnamon (gnome)" {
  get_desktop_environment() { echo "gnome"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'gnome' (not Cinnamon). Skipping Cinnamon setup." ]]
}

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not Cinnamon). Skipping Cinnamon setup." ]]
}

@test "main fails when ensure_dconf fails on cinnamon" {
  get_desktop_environment() { echo "cinnamon"; }
  ensure_dconf() { return 1; }

  run main
  [ "$status" -eq 1 ]
}

@test "_configure_cinnamon_interface sets dark mode and clock preferences" {
  gsettings_exec() {
    echo "gsettings: $*"
    return 0
  }
  command() {
    if [ "${1:-}" = "-v" ] && [ "${2:-}" = "gsettings" ]; then return 0; fi
    builtin command "$@"
  }

  run _configure_cinnamon_interface
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.interface gtk-theme Mint-Y-Dark-Aqua" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.wm.preferences theme Mint-Y-Dark-Aqua" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon.theme name Mint-Y-Dark-Aqua" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.interface color-scheme prefer-dark" ]]
  [[ "$output" =~ "gsettings: set org.x.apps.portal color-scheme prefer-dark" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.interface clock-show-date true" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.interface clock-show-seconds false" ]]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.interface gtk-enable-primary-paste false" ]]
}

@test "_configure_cinnamon_terminal configures kitty when available" {
  gsettings_exec() {
    echo "gsettings: $*"
    return 0
  }
  command() {
    if [ "${1:-}" = "-v" ] && ([ "${2:-}" = "gsettings" ] || [ "${2:-}" = "kitty" ]); then return 0; fi
    builtin command "$@"
  }

  run _configure_cinnamon_terminal
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.default-applications.terminal exec kitty" ]]
}

@test "_configure_cinnamon_terminal falls back to x-terminal-emulator when kitty missing" {
  gsettings_exec() {
    echo "gsettings: $*"
    return 0
  }
  command() {
    if [ "${1:-}" = "-v" ]; then
      if [ "${2:-}" = "gsettings" ]; then return 0; fi
      if [ "${2:-}" = "kitty" ]; then return 1; fi
    fi
    builtin command "$@"
  }

  run _configure_cinnamon_terminal
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings: set org.cinnamon.desktop.default-applications.terminal exec x-terminal-emulator" ]]
}

@test "_configure_cinnamon_keybindings sets flameshot custom shortcuts" {
  gsettings_exec() {
    echo "gsettings: $*"
    return 0
  }
  command() {
    if [ "${1:-}" = "-v" ] && [ "${2:-}" = "gsettings" ]; then return 0; fi
    builtin command "$@"
  }

  run _configure_cinnamon_keybindings
  [ "$status" -eq 0 ]
  [[ "$output" =~ "custom-list ['__dummy__', 'custom0']" ]]
  [[ "$output" =~ "flameshot" ]]
  [[ "$output" =~ "flameshot gui" ]]
}

@test "_configure_nemo sets list-view, iso date and hides desktop volumes" {
  gsettings_exec() {
    echo "gsettings: $*"
    return 0
  }
  command() {
    if [ "${1:-}" = "-v" ] && [ "${2:-}" = "gsettings" ]; then return 0; fi
    builtin command "$@"
  }

  run _configure_nemo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "gsettings: set org.nemo.desktop volumes-visible false" ]]
  [[ "$output" =~ "gsettings: set org.nemo.preferences default-folder-viewer list-view" ]]
  [[ "$output" =~ "gsettings: set org.nemo.preferences date-format iso" ]]
}

@test "_copy_cinnamon_config copies templates and adjusts user path" {
  local test_root
  test_root="$(mktemp -d "/tmp/cinnamon_test_root.XXXXXX")"
  local test_target
  test_target="$(mktemp -d "/tmp/cinnamon_test_target.XXXXXX")"

  mkdir -p "$test_root/config/cinnamon/backgrounds"
  echo "/home/gabriel/Imagens" > "$test_root/config/cinnamon/backgrounds/user-folders.lst"

  get_repo_root() { echo "$test_root"; }
  export CINNAMON_CONFIG_DIR="$test_target"

  run _copy_cinnamon_config
  [ "$status" -eq 0 ]
  [ -f "$test_target/backgrounds/user-folders.lst" ]
  grep -q "$HOME" "$test_target/backgrounds/user-folders.lst"

  rm -rf "$test_root" "$test_target"
}

@test "CINNAMON_DCONF_FILES contains all 9 expected configuration files" {
  [ "${#CINNAMON_DCONF_FILES[@]}" -eq 9 ]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "interface.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "gtk.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "peripherals.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "window-manager.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "night-light.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "privacy.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "nemo.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "shell.dconf" ]]
  [[ "${CINNAMON_DCONF_FILES[*]}" =~ "apps.dconf" ]]
}

@test "_load_cinnamon_dconf calls load_dconf_files with CINNAMON_DCONF_FILES" {
  local test_root
  test_root="$(mktemp -d "/tmp/cinnamon_dconf_test.XXXXXX")"
  mkdir -p "$test_root/config/cinnamon"

  get_repo_root() { echo "$test_root"; }
  load_dconf_files() {
    local dir="$1"
    shift
    echo "loaded from $dir: $*"
    return 0
  }

  run _load_cinnamon_dconf
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Loading Cinnamon desktop dconf preferences..." ]]
  [[ "$output" =~ "loaded from $test_root/config/cinnamon: interface.dconf gtk.dconf peripherals.dconf window-manager.dconf night-light.dconf privacy.dconf nemo.dconf shell.dconf apps.dconf" ]]

  rm -rf "$test_root"
}

@test "main executes all configuration steps when environment is cinnamon" {
  get_desktop_environment() { echo "cinnamon"; }
  ensure_dconf() { return 0; }
  _configure_cinnamon_interface() { echo "configured interface"; }
  _configure_cinnamon_terminal() { echo "configured terminal"; }
  _configure_cinnamon_keybindings() { echo "configured keybindings"; }
  _configure_nemo() { echo "configured nemo"; }
  _copy_cinnamon_config() { echo "copied config"; }
  _load_cinnamon_dconf() { echo "loaded dconf"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting Cinnamon desktop preferences configuration..." ]]
  [[ "$output" =~ "copied config" ]]
  [[ "$output" =~ "loaded dconf" ]]
  [[ "$output" =~ "configured interface" ]]
  [[ "$output" =~ "configured terminal" ]]
  [[ "$output" =~ "configured keybindings" ]]
  [[ "$output" =~ "configured nemo" ]]
  [[ "$output" =~ "setup-cinnamon complete" ]]
}
