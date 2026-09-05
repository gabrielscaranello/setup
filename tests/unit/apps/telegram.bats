#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-telegram.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-telegram.sh
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
  HOME="/tmp/nonexistent-home"
  telegram-desktop() {
    echo "Telegram Desktop 5.9.0"
    return 0
  }
  export -f telegram-desktop 2>/dev/null || true

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

@test "_install_telegram_repo calls add_fedora_rpmfusion_repo on fedora" {
  add_fedora_rpmfusion_repo() {
    echo "called add_fedora_rpmfusion_repo"
    return 0
  }
  install_packages() { return 0; }

  run _install_telegram_repo "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ called\ add_fedora_rpmfusion_repo ]]
}

@test "_install_telegram fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_telegram
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "_install_telegram delegates to repo on arch and fedora" {
  get_distro_id() { echo "arch"; }
  _install_telegram_repo() {
    echo "installed from repo $1"
    return 0
  }
  run _install_telegram
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ repo\ arch ]]

  get_distro_id() { echo "fedora"; }
  _install_telegram_repo() {
    echo "installed from repo $1"
    return 0
  }
  run _install_telegram
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ repo\ fedora ]]
}

@test "_install_telegram delegates to binary on debian" {
  get_distro_id() { echo "debian"; }
  _install_telegram_binary() {
    echo "installed from binary"
    return 0
  }
  run _install_telegram
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary ]]
}
