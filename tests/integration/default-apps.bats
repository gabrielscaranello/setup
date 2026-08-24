#!/usr/bin/env bats

# Integration tests for setup-default-apps.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-default-apps.sh
}

@test "default-apps configures xdg-terminals.list" {
  [ -f "$HOME/.config/xdg-terminals.list" ]
  grep -q "kitty.desktop" "$HOME/.config/xdg-terminals.list"
}

@test "setup-default-apps.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-default-apps.sh
  [ "$status" -eq 0 ]
}
