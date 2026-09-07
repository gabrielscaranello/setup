#!/usr/bin/env bats

# Integration tests for setup-default-apps.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/apps/setup-default-apps.sh
}

@test "default-apps configures xdg-terminals.list" {
  [ -f "$HOME/.config/xdg-terminals.list" ]
  grep -q "kitty.desktop" "$HOME/.config/xdg-terminals.list"
}

@test "default-apps configures vlc.desktop in mimeapps.list" {
  [ -f "$HOME/.config/mimeapps.list" ]
  grep -q "^video/mp4=vlc.desktop;" "$HOME/.config/mimeapps.list"
  grep -q "^video/mkv=vlc.desktop;" "$HOME/.config/mimeapps.list"
}

@test "setup-default-apps.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-default-apps.sh
  [ "$status" -eq 0 ]
}
