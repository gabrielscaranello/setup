#!/usr/bin/env bats

# Integration tests for setup-browsers.sh (runs across all distros)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"
  if [ "$pm" = "apt" ]; then
    # In headless containers without full systemd/D-Bus, mock successful flatpak installation for Chromium
    sudo mkdir -p /usr/local/bin
    sudo bash -c "cat << 'MOCK' > /usr/local/bin/flatpak
#!/bin/bash
if [ \"\$1\" = \"remotes\" ]; then echo \"flathub\"; exit 0; fi
if [ \"\$1\" = \"list\" ]; then
  if [ -f /tmp/mock_chromium_installed ]; then
    echo \"org.chromium.Chromium\"
  fi
  exit 0
fi
if [ \"\$1\" = \"remote-add\" ]; then exit 0; fi
if [ \"\$1\" = \"install\" ]; then
  touch /tmp/mock_chromium_installed
  exit 0
fi
exit 0
MOCK"
    sudo chmod +x /usr/local/bin/flatpak
  fi

  bash /setup/scripts/apps/setup-browsers.sh
}

@test "firefox is installed or available" {
  run firefox --version
  [ "$status" -eq 0 ] || command -v firefox
}

@test "chromium is installed or available" {
  if command -v chromium >/dev/null 2>&1; then
    run chromium --version
    [ "$status" -eq 0 ]
  elif [ -f /tmp/mock_chromium_installed ]; then
    [ -f /tmp/mock_chromium_installed ]
  else
    run chromium-browser --version
    [ "$status" -eq 0 ]
  fi
}

@test "setup-browsers.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-browsers.sh
  [ "$status" -eq 0 ]
}

