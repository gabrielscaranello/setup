#!/usr/bin/env bats

@test "setup-cinnamon-applets-config.sh completes gracefully when DE is not Cinnamon" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-cinnamon-applets-config.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping Cinnamon panel and applets configuration." ]]
}

@test "setup-cinnamon-applets-config.sh configures panel and spices when DE is Cinnamon and is idempotent" {
  export XDG_CURRENT_DESKTOP="X-Cinnamon"

  run bash /setup/scripts/desktop/setup-cinnamon-applets-config.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting Cinnamon panel and applets configuration..." ]]
  [[ "$output" =~ "Cinnamon panel and applets configuration completed successfully." ]]

  [ -f "$HOME/.config/cinnamon/spices/calendar@cinnamon.org/15.json" ]
  [ -f "$HOME/.config/cinnamon/spices/color-picker@fmete/color-picker@fmete.json" ]
  [ -f "$HOME/.config/cinnamon/spices/color-picker@fmete/3.json" ]
  [ -f "$HOME/.config/cinnamon/spices/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json" ]
  [ -f "$HOME/.config/cinnamon/spices/grouped-window-list@cinnamon.org/2.json" ]

  # Idempotency: second run succeeds smoothly
  run bash /setup/scripts/desktop/setup-cinnamon-applets-config.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cinnamon panel and applets configuration completed successfully." ]]
}
