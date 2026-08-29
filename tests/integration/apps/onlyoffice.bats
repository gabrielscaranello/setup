#!/usr/bin/env bats

# Integration tests for setup-onlyoffice.sh (runs across all distros)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
  # In headless containers without full systemd/D-Bus, mock successful flatpak installation
  sudo mkdir -p /usr/local/bin
  sudo bash -c "cat << 'MOCK' > /usr/local/bin/flatpak
#!/bin/bash
if [ \"\$1\" = \"remotes\" ]; then echo \"flathub\"; exit 0; fi
if [ \"\$1\" = \"list\" ]; then
  if [ -f /tmp/mock_onlyoffice_installed ]; then
    echo \"org.onlyoffice.desktopeditors\"
  fi
  exit 0
fi
if [ \"\$1\" = \"remote-add\" ]; then exit 0; fi
if [ \"\$1\" = \"install\" ]; then
  touch /tmp/mock_onlyoffice_installed
  exit 0
fi
exit 0
MOCK"
  sudo chmod +x /usr/local/bin/flatpak

  bash /setup/scripts/apps/setup-onlyoffice.sh
}

teardown_file() {
  sudo rm -f /usr/local/bin/flatpak /tmp/mock_onlyoffice_installed
}

@test "onlyoffice is installed via flatpak" {
  flatpak list --app --columns=application | grep -qx "org.onlyoffice.desktopeditors"
}

@test "setup-onlyoffice.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-onlyoffice.sh
  [ "$status" -eq 0 ]
}
