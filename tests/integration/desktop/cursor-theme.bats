#!/usr/bin/env bats

@test "setup-cursor-theme.sh completes gracefully when DE is unknown" {
  run bash /setup/scripts/desktop/setup-cursor-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping cursor theme setup." ]]
}

@test "setup-cursor-theme.sh installs cursor theme when DE is GNOME and is idempotent" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-cursor-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Bibata-Modern-Ice cursor theme for gnome..." ]]
  [[ "$output" =~ "Cursor theme setup completed successfully." ]]

  # Idempotency: second run should skip download
  run bash /setup/scripts/desktop/setup-cursor-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "is already installed. Skipping download." ]]
}

@test "setup-cursor-theme.sh configures XDG default cursor when DE is Plasma" {
  export XDG_CURRENT_DESKTOP="KDE"

  run bash /setup/scripts/desktop/setup-cursor-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Bibata-Modern-Ice cursor theme for plasma..." ]]
  [[ "$output" =~ "Cursor theme setup completed successfully." ]]
}
