#!/usr/bin/env bats

# Integration tests for setup-steam.sh (runs across Debian 13, Fedora 44, and Arch Linux)

setup_file() {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"

  # In headless container environments, mock flatpak if real flatpak is not configured or in container
  if ! command -v flatpak >/dev/null 2>&1 || [ "$pm" = "apt" ]; then
    sudo mkdir -p /usr/local/bin
    sudo bash -c "cat << 'MOCK' > /usr/local/bin/flatpak
#!/bin/bash
if [ \"\$1\" = \"remotes\" ]; then echo \"flathub\"; exit 0; fi
if [ \"\$1\" = \"list\" ]; then
  if [ -f /tmp/mock_steam_installed ]; then
    echo \"com.valvesoftware.Steam\"
    echo \"org.freedesktop.Platform.VulkanLayer.MangoHud\"
    echo \"org.freedesktop.Platform.VulkanLayer.gamescope\"
    echo \"net.davidotek.pupgui2\"
    echo \"io.github.radiolamp.mangojuice\"
  fi
  exit 0
fi
if [ \"\$1\" = \"remote-add\" ]; then exit 0; fi
if [ \"\$1\" = \"install\" ]; then
  touch /tmp/mock_steam_installed
  exit 0
fi
exit 0
MOCK"
    sudo chmod +x /usr/local/bin/flatpak
  fi

  bash /setup/scripts/apps/setup-steam.sh
}

teardown_file() {
  sudo rm -f /usr/local/bin/flatpak /tmp/mock_steam_installed
}

@test "steam is installed via native package or flatpak" {
  source /setup/scripts/_utils.sh 2>/dev/null
  local pm
  pm="$(_get_package_manager)"

  case "$pm" in
    apt)
      flatpak list | grep -q "com.valvesoftware.Steam"
      ;;
    dnf)
      rpm -q steam || flatpak list | grep -q "com.valvesoftware.Steam"
      ;;
    pacman)
      pacman -Q steam || flatpak list | grep -q "com.valvesoftware.Steam"
      ;;
  esac
}

@test "setup-steam.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-steam.sh
  [ "$status" -eq 0 ]
}
