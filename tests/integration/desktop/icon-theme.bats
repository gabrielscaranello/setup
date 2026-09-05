#!/usr/bin/env bats

@test "setup-icon-theme.sh completes gracefully when DE is not GNOME" {
  run bash /setup/scripts/desktop/setup-icon-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping icon theme setup." ]]
}

@test "setup-icon-theme.sh installs icon theme when DE is GNOME and is idempotent" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-icon-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Papirus-Dark icon theme for GNOME..." ]]
  [[ "$output" =~ "Icon theme setup completed successfully." ]]

  # Idempotency / Up to date: second run should detect already installed or managed
  run bash /setup/scripts/desktop/setup-icon-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "is managed by system package manager" || "$output" =~ "is already installed" || "$output" =~ "is up to date" ]]
}
