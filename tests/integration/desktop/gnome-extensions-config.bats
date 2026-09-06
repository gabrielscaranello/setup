#!/usr/bin/env bats

setup() {
  # Ensure valid machine-id exists for dbus-run-session in test containers
  if [ ! -s /etc/machine-id ] && [ ! -s /var/lib/dbus/machine-id ]; then
    if command -v systemd-machine-id-setup > /dev/null 2>&1; then
      sudo systemd-machine-id-setup 2> /dev/null || true
    elif command -v dbus-uuidgen > /dev/null 2>&1; then
      sudo dbus-uuidgen | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    else
      echo "0123456789abcdef0123456789abcdef" | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    fi
  fi
}

teardown() {
  :
}

@test "setup-gnome-extensions-config.sh completes gracefully when DE is not GNOME" {
  export XDG_CURRENT_DESKTOP="KDE"
  run bash /setup/scripts/desktop/setup-gnome-extensions-config.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping GNOME extensions configuration." ]]
}

@test "setup-gnome-extensions-config.sh applies extension settings and is idempotent" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-gnome-extensions-config.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME extensions configuration..." ]]
  [[ "$output" =~ "Applying common GNOME extensions configuration..." ]]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]

  # Idempotent second execution
  run bash /setup/scripts/desktop/setup-gnome-extensions-config.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "GNOME extensions configuration completed successfully." ]]
}
