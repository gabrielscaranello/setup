#!/usr/bin/env bats

@test "setup-cinnamon-preferences.sh completes gracefully when DE is not Cinnamon" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-cinnamon-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping Cinnamon preferences configuration." ]]
}

@test "setup-cinnamon-preferences.sh configures preferences when DE is Cinnamon and is idempotent" {
  export XDG_CURRENT_DESKTOP="X-Cinnamon"

  run bash /setup/scripts/desktop/setup-cinnamon-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting Cinnamon desktop preferences configuration..." ]]
  [[ "$output" =~ "Cinnamon desktop preferences configuration completed successfully." ]]

  # Idempotency: second run executes smoothly
  run bash /setup/scripts/desktop/setup-cinnamon-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cinnamon desktop preferences configuration completed successfully." ]]
}
