#!/usr/bin/env bats

@test "setup-cinnamon-applets.sh completes gracefully when DE is not Cinnamon" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-cinnamon-applets.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping Cinnamon Spices setup." ]]
}

@test "setup-cinnamon-applets.sh installs spices when DE is Cinnamon and is idempotent" {
  export XDG_CURRENT_DESKTOP="X-Cinnamon"

  run bash /setup/scripts/desktop/setup-cinnamon-applets.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Cinnamon Spices (applets and extensions)..." ]]
  [[ "$output" =~ "Cinnamon Spices setup completed successfully." ]]

  [ -d "$HOME/.local/share/cinnamon/applets/color-picker@fmete" ]
  [ -d "$HOME/.local/share/cinnamon/extensions/transparent-panels-reloaded@marcelovbcfilho" ]

  # Idempotency: second run should detect already installed
  run bash /setup/scripts/desktop/setup-cinnamon-applets.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "is already installed" ]]
  [[ "$output" =~ "Cinnamon Spices setup completed successfully." ]]
}
