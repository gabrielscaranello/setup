#!/usr/bin/env bats

# Unit tests for setup-kitty.sh logic and branches

@test "_fetch_remote_version returns trimmed version string using curl" {
  curl() {
    echo -e "1.0.0\n"
    return 0
  }
  command() {
    if [ "${2:-}" = "curl" ]; then return 0; fi
    builtin command "$@"
  }
  source /setup/scripts/setup-kitty.sh
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "1.0.0" ]
}

@test "_fetch_remote_version uses wget when curl is unavailable" {
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    if [ "${2:-}" = "wget" ]; then return 0; fi
    builtin command "$@"
  }
  wget() {
    echo -e "1.0.0\n"
    return 0
  }
  source /setup/scripts/setup-kitty.sh
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "1.0.0" ]
}

@test "_get_local_version parses version correctly from binary" {
  source /setup/scripts/setup-kitty.sh
  local test_bin_dir="/tmp/test-kitty-bin"
  mkdir -p "$test_bin_dir"
  cat <<'SCRIPT' >"$test_bin_dir/kitty"
#!/bin/sh
echo "kitty 1.0.0 created by Kovid Goyal"
SCRIPT
  chmod +x "$test_bin_dir/kitty"

  HOME="/tmp/test-kitty-home"
  mkdir -p "$HOME/.local/kitty.app/bin"
  cp "$test_bin_dir/kitty" "$HOME/.local/kitty.app/bin/kitty"

  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "1.0.0" ]

  rm -rf /tmp/test-kitty-home "$test_bin_dir"
}

@test "_is_kitty_up_to_date returns true when local matches remote" {
  source /setup/scripts/setup-kitty.sh
  _get_local_version() { echo "1.0.0"; }
  _fetch_remote_version() { echo "1.0.0"; }
  run _is_kitty_up_to_date
  [ "$status" -eq 0 ]
}

@test "_is_kitty_up_to_date returns false when local does not match remote" {
  source /setup/scripts/setup-kitty.sh
  _get_local_version() { echo "1.0.0"; }
  _fetch_remote_version() { echo "1.1.0"; }
  run _is_kitty_up_to_date
  [ "$status" -eq 1 ]
}

@test "_is_kitty_up_to_date returns false when not installed" {
  source /setup/scripts/setup-kitty.sh
  _get_local_version() { echo ""; }
  _fetch_remote_version() { echo "1.0.0"; }
  run _is_kitty_up_to_date
  [ "$status" -eq 1 ]
}

@test "_setup_desktop_integration creates symlinks and desktop files with correct paths" {
  source /setup/scripts/setup-kitty.sh
  local test_home="/tmp/test-kitty-desktop-home"
  mkdir -p "$test_home/.local/kitty.app/bin" \
    "$test_home/.local/kitty.app/share/applications" \
    "$test_home/.local/kitty.app/share/icons/hicolor/256x256/apps"

  touch "$test_home/.local/kitty.app/bin/kitty"
  touch "$test_home/.local/kitty.app/bin/kitten"
  chmod +x "$test_home/.local/kitty.app/bin/kitty" "$test_home/.local/kitty.app/bin/kitten"
  touch "$test_home/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png"

  cat <<'DESKTOP' >"$test_home/.local/kitty.app/share/applications/kitty.desktop"
[Desktop Entry]
Exec=kitty
Icon=kitty
Name=kitty
DESKTOP

  cat <<'DESKTOP_OPEN' >"$test_home/.local/kitty.app/share/applications/kitty-open.desktop"
[Desktop Entry]
Exec=kitty +open-actions
Icon=kitty
Name=kitty
DESKTOP_OPEN

  HOME="$test_home" _setup_desktop_integration

  [ -L "$test_home/.local/bin/kitty" ]
  [ -L "$test_home/.local/bin/kitten" ]
  [ -f "$test_home/.local/share/applications/kitty.desktop" ]
  [ -f "$test_home/.local/share/applications/kitty-open.desktop" ]
  grep -q "Exec=$test_home/.local/kitty.app/bin/kitty" "$test_home/.local/share/applications/kitty.desktop"
  grep -q "Icon=$test_home/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png" "$test_home/.local/share/applications/kitty.desktop"
  [ -f "$test_home/.config/xdg-terminals.list" ]
  grep -q 'kitty.desktop' "$test_home/.config/xdg-terminals.list"

  rm -rf "$test_home"
}

@test "_install_kitty_binary skips download when up to date" {
  source /setup/scripts/setup-kitty.sh
  _is_kitty_up_to_date() { return 0; }
  _get_local_version() { echo "1.0.0"; }
  _setup_desktop_integration() { return 0; }
  run _install_kitty_binary
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already up to date" ]]
}

@test "_install_kitty fails when distribution is unsupported" {
  source /setup/scripts/setup-kitty.sh
  _get_package_manager() { echo "unknown-pm"; }
  run _install_kitty
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_kitty delegates to repo on dnf and pacman" {
  source /setup/scripts/setup-kitty.sh
  _get_package_manager() { echo "dnf"; }
  _install_kitty_repo() {
    echo "installed from dnf"
    return 0
  }
  run _install_kitty
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed from dnf" ]]

  _get_package_manager() { echo "pacman"; }
  _install_kitty_repo() {
    echo "installed from pacman"
    return 0
  }
  run _install_kitty
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed from pacman" ]]
}

@test "_install_kitty delegates to binary on apt" {
  source /setup/scripts/setup-kitty.sh
  _get_package_manager() { echo "apt"; }
  _install_kitty_binary() {
    echo "installed from binary"
    return 0
  }
  run _install_kitty
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed from binary" ]]
}
