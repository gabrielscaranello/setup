#!/usr/bin/env bats

@test "setup-gtk-theme.sh completes gracefully when DE is unsupported" {
  export XDG_CURRENT_DESKTOP="KDE"
  run bash /setup/scripts/desktop/setup-gtk-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping GTK theme setup." ]]
}

@test "setup-gtk-theme.sh installs GTK theme when DE is GNOME and is idempotent" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-gtk-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up adw-gtk3-dark GTK theme for GNOME..." ]]
  [[ "$output" =~ "GTK theme setup completed successfully." ]]

  # Idempotency / Up to date: second run should detect already installed or up to date
  run bash /setup/scripts/desktop/setup-gtk-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "is managed by system package manager" || "$output" =~ "is up to date" ]]
}

@test "setup-gtk-theme.sh installs GTK theme when DE is Cinnamon and is idempotent" {
  export XDG_CURRENT_DESKTOP="X-Cinnamon"

  run bash /setup/scripts/desktop/setup-gtk-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Colloid-Dark-Catppuccin GTK theme for Cinnamon..." ]]
  [[ "$output" =~ "GTK theme setup completed successfully." ]]

  # Idempotency: second run should detect already installed
  run bash /setup/scripts/desktop/setup-gtk-theme.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed" || "$output" =~ "is up to date" ]]
}
