#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-gnome-extensions-config.sh
}

teardown() {
  :
}

# ── Desktop Environment Skip Policy Tests ─────────────────────────────────────

@test "main skips when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'unknown' (not GNOME). Skipping GNOME extensions configuration." ]]
}

@test "main skips when desktop environment is plasma" {
  get_desktop_environment() { echo "plasma"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop Environment is 'plasma' (not GNOME). Skipping GNOME extensions configuration." ]]
}

# ── Tool Availability & Ensure dconf Tests (SRP) ──────────────────────────────

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

# ── File Loading Mechanics Tests (SRP / LSP) ──────────────────────────────────

@test "_load_dconf_file warns and returns 0 when file does not exist" {
  run _load_dconf_file "/non/existent/path/test.dconf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Warning: Configuration file '/non/existent/path/test.dconf' not found. Skipping." ]]
}

@test "_load_dconf_file executes _dconf load with valid file" {
  local mock_file
  mock_file="$(mktemp /tmp/test_dconf_XXXXXX.dconf)"
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

# ── Common Extensions Configuration Tests ─────────────────────────────────────

@test "_configure_common_extensions loads all common dconf files" {
  _load_dconf_file() {
    echo "loading: $(basename "$1")"
  }

  run _configure_common_extensions
  [ "$status" -eq 0 ]
  [[ "$output" =~ "loading: alphabetical-app-grid.dconf" ]]
  [[ "$output" =~ "loading: blur-my-shell.dconf" ]]
  [[ "$output" =~ "loading: caffeine.dconf" ]]
  [[ "$output" =~ "loading: coverflow-alt-tab.dconf" ]]
  [[ "$output" =~ "loading: logo-menu.dconf" ]]
  [[ "$output" =~ "loading: status-tray.dconf" ]]
  [[ "$output" =~ "loading: top-bar-organizer.dconf" ]]
  [[ "$output" =~ "loading: vitals.dconf" ]]
}

# ── Logo Menu Distro Icon Tests ───────────────────────────────────────────────

@test "_configure_logo_menu_icon sets icon 2 on debian" {
  get_distro_id() { echo "debian"; }
  _dconf() {
    echo "dconf called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Logo Menu icon for debian (index: 2)..." ]]
  [[ "$output" =~ "dconf called: write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 2" ]]
}

@test "_configure_logo_menu_icon sets icon 1 on fedora" {
  get_distro_id() { echo "fedora"; }
  _dconf() {
    echo "dconf called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Logo Menu icon for fedora (index: 1)..." ]]
  [[ "$output" =~ "dconf called: write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 1" ]]
}

@test "_configure_logo_menu_icon sets icon 6 on arch" {
  get_distro_id() { echo "arch"; }
  _dconf() {
    echo "dconf called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Logo Menu icon for arch (index: 6)..." ]]
  [[ "$output" =~ "dconf called: write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 6" ]]
}

@test "_configure_logo_menu_icon keeps default on unknown distro" {
  get_distro_id() { echo "unknown"; }
  _dconf() {
    echo "dconf called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unknown distribution 'unknown' for Logo Menu icon. Keeping default." ]]
  [[ "$output" != *"dconf called: write"* ]]
}

# ── Arch Linux Updates Indicator Tests ────────────────────────────────────────

@test "_configure_arch_update loads arch-update.dconf on arch" {
  is_distro() {
    if [ "$1" = "arch" ]; then return 0; fi
    return 1
  }
  _load_dconf_file() {
    echo "loading: $(basename "$1")"
  }

  run _configure_arch_update
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Arch Linux Updates Indicator extension..." ]]
  [[ "$output" =~ "loading: arch-update.dconf" ]]
}

@test "_configure_arch_update skips on non-arch distros" {
  is_distro() { return 1; }
  _load_dconf_file() {
    echo "loading: $(basename "$1")"
  }

  run _configure_arch_update
  [ "$status" -eq 0 ]
  [[ "$output" != *"arch-update.dconf"* ]]
}

# ── End-to-End Main Pipeline Tests ────────────────────────────────────────────

@test "main executes successfully on Debian GNOME" {
  get_desktop_environment() { echo "gnome"; }
  get_distro_id() { echo "debian"; }
  is_distro() {
    if [ "$1" = "debian" ]; then return 0; fi
    return 1
  }
  _ensure_dconf() { return 0; }
  _dconf() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME extensions configuration..." ]]
  [[ "$output" =~ "Setting Logo Menu icon for debian (index: 2)..." ]]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]
}

@test "main executes successfully on Arch GNOME with arch-update" {
  get_desktop_environment() { echo "gnome"; }
  get_distro_id() { echo "arch"; }
  is_distro() {
    if [ "$1" = "arch" ]; then return 0; fi
    return 1
  }
  _ensure_dconf() { return 0; }
  _dconf() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME extensions configuration..." ]]
  [[ "$output" =~ "Setting Logo Menu icon for arch (index: 6)..." ]]
  [[ "$output" =~ "Configuring Arch Linux Updates Indicator extension..." ]]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]
}
