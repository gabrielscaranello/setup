#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-desktop-preferences.sh
}

teardown() {
  :
}

# ── Desktop Environment Skip Policy Tests ─────────────────────────────────────

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (unsupported or not GNOME). Skipping desktop preferences configuration." ]]
}

@test "main skips when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "KDE Plasma desktop environment preferences are not yet implemented. Skipping." ]]
}

@test "main skips when desktop environment is unsupported (e.g. xfce)" {
  get_desktop_environment() { echo "xfce"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'xfce' (unsupported or not GNOME). Skipping desktop preferences configuration." ]]
}

# ── Tool Availability & Ensure dconf Tests ────────────────────────────────────

@test "_ensure_dconf succeeds when dconf command is available" {
  command() {
    if [ "$2" = "dconf" ]; then return 0; fi
    builtin command "$@"
  }

  run _ensure_dconf
  [ "$status" -eq 0 ]
}

@test "_ensure_dconf attempts to install dconf when initially missing" {
  local flag_file
  flag_file="$(mktemp /tmp/dconf_installed_XXXXXX)"
  rm -f "$flag_file"

  command() {
    if [ "$2" = "dconf" ]; then
      if [ -f "$flag_file" ]; then return 0; fi
      return 1
    fi
    builtin command "$@"
  }
  install_packages() {
    echo "install_packages called: $*"
    touch "$flag_file"
  }

  run _ensure_dconf
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf not found in PATH, attempting to install..." ]]
  [[ "$output" =~ "install_packages called: dconf" ]]
  rm -f "$flag_file"
}

@test "_ensure_dconf fails when dconf cannot be found or installed" {
  command() {
    if [ "$2" = "dconf" ]; then return 1; fi
    builtin command "$@"
  }
  install_packages() {
    return 1
  }

  run _ensure_dconf
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: dconf CLI is not installed or not found in PATH." ]]
}

# ── _dconf Session Wrapper Tests ──────────────────────────────────────────────

@test "_dconf uses dbus-run-session when session address is empty and tool exists" {
  export DBUS_SESSION_BUS_ADDRESS=""
  command() {
    if [ "$2" = "dbus-run-session" ]; then return 0; fi
    builtin command "$@"
  }
  dbus-run-session() {
    echo "dbus-run-session called with: $*"
  }

  run _dconf read /some/key
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dbus-run-session called with: -- dconf read /some/key" ]]
}

@test "_dconf invokes dconf directly when DBUS_SESSION_BUS_ADDRESS is present" {
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
  dconf() {
    echo "dconf called with: $*"
  }

  run _dconf read /some/key
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dconf called with: read /some/key" ]]
}

# ── File Loading Mechanics Tests ──────────────────────────────────────────────

@test "_load_dconf_file warns and returns 0 when file does not exist" {
  run _load_dconf_file "/non/existent/path/test.dconf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Warning: Configuration file '/non/existent/path/test.dconf' not found. Skipping." ]]
}

@test "_load_dconf_file executes _dconf load with valid file" {
  local mock_file
  mock_file="$(mktemp /tmp/test_pref_dconf_XXXXXX.dconf)"
  echo "[test/section]" > "$mock_file"

  _dconf() {
    echo "dconf called: $*"
  }

  run _load_dconf_file "$mock_file"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Loading dconf configuration: $(basename "$mock_file")..." ]]
  [[ "$output" =~ "dconf called: load /" ]]
  rm -f "$mock_file"
}

# ── GNOME Preferences Configuration Tests ─────────────────────────────────────

@test "_configure_gnome_preferences fails if config directory does not exist" {
  CONFIG_DIR="/non/existent/gnome/config"

  run _configure_gnome_preferences
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: Configuration directory '/non/existent/gnome/config' not found." ]]
}

@test "_configure_gnome_preferences loads all 8 dconf files" {
  local mock_dir
  mock_dir="$(mktemp -d /tmp/gnome_conf_XXXXXX)"
  CONFIG_DIR="$mock_dir"

  _load_dconf_file() {
    echo "loading: $(basename "$1")"
  }

  run _configure_gnome_preferences
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying GNOME desktop environment preferences..." ]]
  [[ "$output" =~ "loading: interface.dconf" ]]
  [[ "$output" =~ "loading: peripherals.dconf" ]]
  [[ "$output" =~ "loading: window-manager.dconf" ]]
  [[ "$output" =~ "loading: night-light.dconf" ]]
  [[ "$output" =~ "loading: privacy.dconf" ]]
  [[ "$output" =~ "loading: nautilus.dconf" ]]
  [[ "$output" =~ "loading: shell.dconf" ]]
  [[ "$output" =~ "loading: apps.dconf" ]]

  rm -rf "$mock_dir"
}

# ── End-to-End Main Pipeline Tests ────────────────────────────────────────────

@test "main executes successfully on GNOME" {
  get_desktop_environment() { echo "gnome"; }
  _ensure_dconf() { return 0; }
  _configure_gnome_preferences() {
    echo "Preferences applied"
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME desktop preferences configuration..." ]]
  [[ "$output" =~ "Preferences applied" ]]
  [[ "$output" =~ "GNOME desktop preferences configuration completed successfully." ]]
}

@test "main fails if _ensure_dconf fails on GNOME" {
  get_desktop_environment() { echo "gnome"; }
  _ensure_dconf() { return 1; }

  run main
  [ "$status" -ne 0 ]
}

@test "main fails if _configure_gnome_preferences fails on GNOME" {
  get_desktop_environment() { echo "gnome"; }
  _ensure_dconf() { return 0; }
  _configure_gnome_preferences() { return 1; }

  run main
  [ "$status" -ne 0 ]
}
