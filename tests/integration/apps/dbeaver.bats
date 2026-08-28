#!/usr/bin/env bats

# Integration tests for setup-dbeaver.sh (runs across all distros)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"
  if [ "$pm" = "apt" ] || [ "$pm" = "dnf" ]; then
    # In headless containers without full systemd/D-Bus, mock successful flatpak installation
    sudo mkdir -p /usr/local/bin
    sudo bash -c "cat << 'MOCK' > /usr/local/bin/flatpak
#!/bin/bash
if [ \"\$1\" = \"remotes\" ]; then echo \"flathub\"; exit 0; fi
if [ \"\$1\" = \"list\" ]; then
  if [ -f /tmp/mock_dbeaver_installed ]; then
    echo \"io.dbeaver.DBeaverCommunity\"
  fi
  exit 0
fi
if [ \"\$1\" = \"remote-add\" ]; then exit 0; fi
if [ \"\$1\" = \"install\" ]; then
  touch /tmp/mock_dbeaver_installed
  exit 0
fi
exit 0
MOCK"
    sudo chmod +x /usr/local/bin/flatpak
  fi

  bash /setup/scripts/apps/setup-dbeaver.sh
}

teardown_file() {
  sudo rm -f /usr/local/bin/flatpak /tmp/mock_dbeaver_installed
}

@test "dbeaver is installed either via repo or flatpak" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"
  if [ "$pm" = "pacman" ]; then
    command -v dbeaver >/dev/null 2>&1
  else
    flatpak list --app --columns=application | grep -qx "io.dbeaver.DBeaverCommunity"
  fi
}

@test "setup-dbeaver.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-dbeaver.sh
  [ "$status" -eq 0 ]
}
