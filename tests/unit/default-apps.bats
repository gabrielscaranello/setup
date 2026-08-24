#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-default-apps.sh logic and functions

@test "_set_default_terminal_xdg creates xdg-terminals.list and calls xdg-mime" {
  source /setup/scripts/setup-default-apps.sh
  local test_home="/tmp/test-default-apps-xdg-home"
  mkdir -p "$test_home"

  local xdg_mime_called=0
  xdg-mime() {
    xdg_mime_called=$((xdg_mime_called + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "xdg-mime" ]; then return 0; fi
    builtin command "$@"
  }

  HOME="$test_home" _set_default_terminal_xdg

  [ -f "$test_home/.config/xdg-terminals.list" ]
  grep -q "kitty.desktop" "$test_home/.config/xdg-terminals.list"
  [ "$xdg_mime_called" -ge 1 ]

  rm -rf "$test_home"
}

@test "_set_default_terminal_gnome sets gsettings if schema is present" {
  source /setup/scripts/setup-default-apps.sh
  local gsettings_called=0
  gsettings() {
    if [ "${1:-}" = "list-schemas" ]; then
      echo "org.gnome.desktop.default-applications.terminal"
      return 0
    fi
    if [ "${1:-}" = "set" ]; then
      gsettings_called=$((gsettings_called + 1))
      return 0
    fi
    return 0
  }

  command() {
    if [ "${2:-}" = "gsettings" ]; then return 0; fi
    builtin command "$@"
  }

  _set_default_terminal_gnome
  [ "$gsettings_called" -eq 2 ]
}

@test "_set_default_terminal_plasma uses kwriteconfig6 when available" {
  source /setup/scripts/setup-default-apps.sh
  local kwrite_called=0
  kwriteconfig6() {
    kwrite_called=$((kwrite_called + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "kwriteconfig6" ]; then return 0; fi
    builtin command "$@"
  }

  local test_home="/tmp/test-default-apps-plasma6-home"
  mkdir -p "$test_home"
  HOME="$test_home" _set_default_terminal_plasma

  [ "$kwrite_called" -eq 2 ]
  rm -rf "$test_home"
}

@test "_set_default_terminal_plasma uses kwriteconfig5 when kwriteconfig6 is absent" {
  source /setup/scripts/setup-default-apps.sh
  local kwrite_called=0
  kwriteconfig5() {
    kwrite_called=$((kwrite_called + 1))
    return 0
  }

  command() {
    if [ "${2:-}" = "kwriteconfig6" ]; then return 1; fi
    if [ "${2:-}" = "kwriteconfig5" ]; then return 0; fi
    builtin command "$@"
  }

  local test_home="/tmp/test-default-apps-plasma5-home"
  mkdir -p "$test_home"
  HOME="$test_home" _set_default_terminal_plasma

  [ "$kwrite_called" -eq 2 ]
  rm -rf "$test_home"
}

@test "_set_default_terminal_plasma falls back to direct file creation when tools are missing" {
  source /setup/scripts/setup-default-apps.sh
  command() {
    if [ "${2:-}" = "kwriteconfig6" ] || [ "${2:-}" = "kwriteconfig5" ]; then return 1; fi
    builtin command "$@"
  }

  local test_home="/tmp/test-default-apps-plasma-fallback-home"
  mkdir -p "$test_home"
  HOME="$test_home" _set_default_terminal_plasma

  [ -f "$test_home/.config/kdeglobals" ]
  grep -q "TerminalApplication=kitty" "$test_home/.config/kdeglobals"
  grep -q "TerminalService=kitty.desktop" "$test_home/.config/kdeglobals"

  rm -rf "$test_home"
}

@test "_set_default_terminal routes only to gnome when de is gnome" {
  source /setup/scripts/setup-default-apps.sh
  local gnome_called=0
  local plasma_called=0
  _set_default_terminal_xdg() { return 0; }
  _set_default_terminal_gnome() { gnome_called=1; }
  _set_default_terminal_plasma() { plasma_called=1; }
  get_desktop_environment() { echo "gnome"; }

  _set_default_terminal

  [ "$gnome_called" -eq 1 ]
  [ "$plasma_called" -eq 0 ]
}

@test "_set_default_terminal routes only to plasma when de is plasma" {
  source /setup/scripts/setup-default-apps.sh
  local gnome_called=0
  local plasma_called=0
  _set_default_terminal_xdg() { return 0; }
  _set_default_terminal_gnome() { gnome_called=1; }
  _set_default_terminal_plasma() { plasma_called=1; }
  get_desktop_environment() { echo "plasma"; }

  _set_default_terminal

  [ "$gnome_called" -eq 0 ]
  [ "$plasma_called" -eq 1 ]
}

@test "_set_default_terminal does not configure gnome or plasma when de is unknown" {
  source /setup/scripts/setup-default-apps.sh
  local gnome_called=0
  local plasma_called=0
  _set_default_terminal_xdg() { return 0; }
  _set_default_terminal_gnome() { gnome_called=1; }
  _set_default_terminal_plasma() { plasma_called=1; }
  get_desktop_environment() { echo "unknown"; }

  _set_default_terminal

  [ "$gnome_called" -eq 0 ]
  [ "$plasma_called" -eq 0 ]
}

@test "setup-default-apps runs _set_default_apps successfully" {
  source /setup/scripts/setup-default-apps.sh
  _set_default_terminal() { return 0; }
  run _set_default_apps
  [ "$status" -eq 0 ]
}
