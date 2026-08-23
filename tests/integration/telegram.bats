#!/usr/bin/env bats

# Integration tests for setup-telegram.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-telegram.sh
}

@test "telegram binary or desktop file is available" {
  source /setup/scripts/_utils.sh 2>/dev/null || source /setup/scripts/_utils.sh
  local pm
  pm="$(_get_package_manager)"
  if [ "$pm" = "apt" ]; then
    [ -x "$HOME/.local/opt/telegram-desktop/Telegram" ] || [ -x "$HOME/.local/bin/telegram-desktop" ]
  else
    command -v telegram-desktop >/dev/null 2>&1 || command -v Telegram >/dev/null 2>&1
  fi
}

@test "setup-telegram.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-telegram.sh
  [ "$status" -eq 0 ]
}
