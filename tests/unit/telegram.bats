#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-telegram.sh logic and branches

setup() {
  source /setup/scripts/setup-telegram.sh
}

@test "_fetch_remote_version returns trimmed version string using curl" {
  curl() {
    echo '{"tag_name": "v5.9.0"}'
    return 0
  }
  command() {
    if [ "${2:-}" = "curl" ]; then return 0; fi
    builtin command "$@"
  }
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "5.9.0" ]
}

@test "_fetch_remote_version uses wget when curl is unavailable" {
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    if [ "${2:-}" = "wget" ]; then return 0; fi
    builtin command "$@"
  }
  wget() {
    echo '{"tag_name": "v5.9.0"}'
    return 0
  }
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "5.9.0" ]
}

@test "_get_local_version parses version correctly from telegram-desktop" {
  telegram-desktop() {
    echo "Telegram Desktop 5.9.0"
    return 0
  }
  command() {
    if [ "${2:-}" = "telegram-desktop" ]; then return 0; fi
    builtin command "$@"
  }
  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "5.9.0" ]
}

@test "_is_telegram_up_to_date returns true when local matches remote" {
  _get_local_version() { echo "5.9.0"; }
  _fetch_remote_version() { echo "5.9.0"; }
  run _is_telegram_up_to_date
  [ "$status" -eq 0 ]
}

@test "_is_telegram_up_to_date returns false when local does not match remote" {
  _get_local_version() { echo "5.0.0"; }
  _fetch_remote_version() { echo "5.9.0"; }
  run _is_telegram_up_to_date
  [ "$status" -eq 1 ]
}

@test "_is_telegram_up_to_date returns false when not installed" {
  _get_local_version() { echo ""; }
  _fetch_remote_version() { echo "5.9.0"; }
  run _is_telegram_up_to_date
  [ "$status" -eq 1 ]
}

@test "_setup_desktop_integration creates symlinks and desktop entry" {
  local test_home="/tmp/test-telegram-home"
  rm -rf "$test_home"
  mkdir -p "$test_home/.local/opt/telegram-desktop"
  touch "$test_home/.local/opt/telegram-desktop/Telegram"
  chmod +x "$test_home/.local/opt/telegram-desktop/Telegram"

  (
    HOME="$test_home"
    _setup_desktop_integration
  )

  [ -L "$test_home/.local/bin/telegram-desktop" ]
  [ -f "$test_home/.local/share/applications/telegramdesktop.desktop" ]
  grep -q "Exec=$test_home/.local/opt/telegram-desktop/Telegram" "$test_home/.local/share/applications/telegramdesktop.desktop"
  rm -rf "$test_home"
}

@test "_install_telegram_binary skips download when up to date" {
  _is_telegram_up_to_date() { return 0; }
  _fetch_remote_version() { echo "5.9.0"; }
  _setup_desktop_integration() { return 0; }
  run _install_telegram_binary
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ up\ to\ date ]]
}

@test "_add_rpmfusion_free_repo skips when already configured" {
  dnf() {
    if [ "$1" = "repolist" ]; then
      echo "rpmfusion-free-updates  RPM Fusion for Fedora 41 - Free"
      return 0
    fi
    return 1
  }
  run _add_rpmfusion_free_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ configured,\ skipping ]]
}

@test "_install_telegram fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_telegram
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ package\ manager ]]
}

@test "_install_telegram delegates to repo on pacman and dnf" {
  _get_package_manager() { echo "pacman"; }
  _install_telegram_repo() {
    echo "installed from repo $1"
    return 0
  }
  run _install_telegram
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ repo\ pacman ]]

  _get_package_manager() { echo "dnf"; }
  _install_telegram_repo() {
    echo "installed from repo $1"
    return 0
  }
  run _install_telegram
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ repo\ dnf ]]
}

@test "_install_telegram delegates to binary on apt" {
  _get_package_manager() { echo "apt"; }
  _install_telegram_binary() {
    echo "installed from binary"
    return 0
  }
  run _install_telegram
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary ]]
}
