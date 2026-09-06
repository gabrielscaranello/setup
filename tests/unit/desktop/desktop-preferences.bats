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

# ── Configuration Array Definition Tests ──────────────────────────────────────

@test "GNOME_DCONF_FILES contains all 8 expected configuration files" {
  [ "${#GNOME_DCONF_FILES[@]}" -eq 8 ]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " interface.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " peripherals.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " window-manager.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " night-light.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " privacy.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " nautilus.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " shell.dconf " ]]
  [[ " ${GNOME_DCONF_FILES[*]} " =~ " apps.dconf " ]]
}

# ── End-to-End Main Pipeline Tests ────────────────────────────────────────────

@test "main executes successfully on GNOME" {
  get_desktop_environment() { echo "gnome"; }
  ensure_dconf() { return 0; }
  load_dconf_files() {
    echo "load_dconf_files called with dir: $1, count: $(($# - 1))"
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME desktop preferences configuration..." ]]
  [[ "$output" =~ "Applying GNOME desktop environment preferences..." ]]
  [[ "$output" =~ "load_dconf_files called with dir: $CONFIG_DIR, count: 8" ]]
  [[ "$output" =~ "GNOME desktop preferences configuration completed successfully." ]]
}

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
