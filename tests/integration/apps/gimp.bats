#!/usr/bin/env bats

# Integration tests for setup-gimp.sh (runs across all distros)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"
  if [ "$pm" = "apt" ]; then
    # In headless containers without full systemd/D-Bus, mock successful flatpak installation
    sudo mkdir -p /usr/local/bin
    sudo bash -c "cat << 'MOCK' > /usr/local/bin/flatpak
#!/bin/bash
if [ \"\$1\" = \"remotes\" ]; then echo \"flathub\"; exit 0; fi
if [ \"\$1\" = \"list\" ]; then
  if [ -f /tmp/mock_gimp_installed ]; then
    echo \"org.gimp.GIMP\"
  fi
  exit 0
fi
if [ \"\$1\" = \"remote-add\" ]; then exit 0; fi
if [ \"\$1\" = \"install\" ]; then
  touch /tmp/mock_gimp_installed
  exit 0
fi
exit 0
MOCK"
    sudo chmod +x /usr/local/bin/flatpak
  fi

  bash /setup/scripts/apps/setup-gimp.sh
}

teardown_file() {
  sudo rm -f /usr/local/bin/flatpak /tmp/mock_gimp_installed
}

@test "gimp is installed either via repo or flatpak" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"
  if [ "$pm" = "apt" ]; then
    flatpak list --app --columns=application | grep -qx "org.gimp.GIMP"
  else
    command -v gimp >/dev/null 2>&1
  fi
}

@test "setup-gimp.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-gimp.sh
  [ "$status" -eq 0 ]
}
