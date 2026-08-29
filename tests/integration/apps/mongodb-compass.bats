#!/usr/bin/env bats

# Integration tests for setup-mongodb-compass.sh (runs across all distros)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
  # In headless containers without full systemd/D-Bus, mock successful flatpak installation
  sudo mkdir -p /usr/local/bin
  sudo bash -c "cat << 'MOCK' > /usr/local/bin/flatpak
#!/bin/bash
if [ \"\$1\" = \"remotes\" ]; then echo \"flathub\"; exit 0; fi
if [ \"\$1\" = \"list\" ]; then
  if [ -f /tmp/mock_compass_installed ]; then
    echo \"mongodb.Compass\"
  fi
  exit 0
fi
if [ \"\$1\" = \"remote-add\" ]; then exit 0; fi
if [ \"\$1\" = \"install\" ]; then
  touch /tmp/mock_compass_installed
  exit 0
fi
exit 0
MOCK"
  sudo chmod +x /usr/local/bin/flatpak

  bash /setup/scripts/apps/setup-mongodb-compass.sh
}

teardown_file() {
  sudo rm -f /usr/local/bin/flatpak /tmp/mock_compass_installed
}

@test "mongodb compass is installed via flatpak" {
  flatpak list --app --columns=application | grep -qx "mongodb.Compass"
}

@test "setup-mongodb-compass.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-mongodb-compass.sh
  [ "$status" -eq 0 ]
}
