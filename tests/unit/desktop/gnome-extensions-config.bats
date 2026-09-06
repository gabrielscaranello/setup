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

# ── Configuration Array Definition Tests ──────────────────────────────────────

@test "COMMON_DCONF_FILES contains all 8 expected common configuration files" {
  [ "${#COMMON_DCONF_FILES[@]}" -eq 8 ]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " alphabetical-app-grid.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " blur-my-shell.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " caffeine.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " coverflow-alt-tab.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " logo-menu.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " status-tray.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " top-bar-organizer.dconf " ]]
  [[ " ${COMMON_DCONF_FILES[*]} " =~ " vitals.dconf " ]]
}

# ── Logo Menu Distro Icon Tests ───────────────────────────────────────────────

@test "_configure_logo_menu_icon sets icon 2 on debian" {
  get_distro_id() { echo "debian"; }
  dconf_exec() {
    echo "dconf_exec called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Logo Menu icon for debian (index: 2)..." ]]
  [[ "$output" =~ "dconf_exec called: write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 2" ]]
}

@test "_configure_logo_menu_icon sets icon 1 on fedora" {
  get_distro_id() { echo "fedora"; }
  dconf_exec() {
    echo "dconf_exec called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Logo Menu icon for fedora (index: 1)..." ]]
  [[ "$output" =~ "dconf_exec called: write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 1" ]]
}

@test "_configure_logo_menu_icon sets icon 6 on arch" {
  get_distro_id() { echo "arch"; }
  dconf_exec() {
    echo "dconf_exec called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting Logo Menu icon for arch (index: 6)..." ]]
  [[ "$output" =~ "dconf_exec called: write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 6" ]]
}

@test "_configure_logo_menu_icon keeps default on unknown distro" {
  get_distro_id() { echo "unknown"; }
  dconf_exec() {
    echo "dconf_exec called: $*"
  }

  run _configure_logo_menu_icon
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unknown distribution 'unknown' for Logo Menu icon. Keeping default." ]]
  [[ "$output" != *"dconf_exec called: write"* ]]
}

# ── Arch Linux Updates Indicator Tests ────────────────────────────────────────

@test "_configure_arch_update loads arch-update.dconf on arch" {
  is_distro() {
    if [ "$1" = "arch" ]; then return 0; fi
    return 1
  }
  load_dconf_file() {
    echo "loading: $(basename "$1")"
  }

  run _configure_arch_update
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Arch Linux Updates Indicator extension..." ]]
  [[ "$output" =~ "loading: arch-update.dconf" ]]
}

@test "_configure_arch_update skips on non-arch distros" {
  is_distro() { return 1; }
  load_dconf_file() {
    echo "loading: $(basename "$1")"
  }

  run _configure_arch_update
  [ "$status" -eq 0 ]
  [[ "$output" != *"arch-update.dconf"* ]]
}

# ── End-to-End Main Pipeline Tests ────────────────────────────────────────────

@test "main fails if ensure_dconf fails on GNOME" {
  get_desktop_environment() { echo "gnome"; }
  ensure_dconf() { return 1; }

  run main
  [ "$status" -ne 0 ]
}

@test "main fails if load_dconf_files fails on GNOME" {
  get_desktop_environment() { echo "gnome"; }
  ensure_dconf() { return 0; }
  load_dconf_files() { return 1; }

  run main
  [ "$status" -ne 0 ]
}

@test "main executes successfully on Debian GNOME" {
  get_desktop_environment() { echo "gnome"; }
  get_distro_id() { echo "debian"; }
  is_distro() {
    if [ "$1" = "debian" ]; then return 0; fi
    return 1
  }
  ensure_dconf() { return 0; }
  load_dconf_files() { return 0; }
  dconf_exec() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME extensions configuration..." ]]
  [[ "$output" =~ "Applying common GNOME extensions configuration..." ]]
  [[ "$output" =~ "Setting Logo Menu icon for debian (index: 2)..." ]]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]
}

@test "main executes successfully on Fedora GNOME" {
  get_desktop_environment() { echo "gnome"; }
  get_distro_id() { echo "fedora"; }
  is_distro() {
    if [ "$1" = "fedora" ]; then return 0; fi
    return 1
  }
  ensure_dconf() { return 0; }
  load_dconf_files() { return 0; }
  dconf_exec() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME extensions configuration..." ]]
  [[ "$output" =~ "Setting Logo Menu icon for fedora (index: 1)..." ]]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]
}

@test "main executes successfully on Arch GNOME with arch-update" {
  get_desktop_environment() { echo "gnome"; }
  get_distro_id() { echo "arch"; }
  is_distro() {
    if [ "$1" = "arch" ]; then return 0; fi
    return 1
  }
  ensure_dconf() { return 0; }
  load_dconf_files() { return 0; }
  load_dconf_file() { return 0; }
  dconf_exec() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME extensions configuration..." ]]
  [[ "$output" =~ "Setting Logo Menu icon for arch (index: 6)..." ]]
  [[ "$output" =~ "Configuring Arch Linux Updates Indicator extension..." ]]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]
}
