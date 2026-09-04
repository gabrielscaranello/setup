#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || true
source "scripts/system/fedora/_repositories.sh" 2>/dev/null || true

_enable_arch_multilib() {
  local conf="${PACMAN_CONF:-/etc/pacman.conf}"
  if [ ! -f "$conf" ]; then
    return 0
  fi

  if grep -q "^\[multilib\]" "$conf" 2>/dev/null; then
    return 0
  fi

  echo "Enabling multilib repository in $conf..."
  if grep -q "^#[[:space:]]*\[multilib\]" "$conf" 2>/dev/null; then
    sudo sed -i '/^#[[:space:]]*\[multilib\]/{s/^#[[:space:]]*//;n;s/^#[[:space:]]*//}' "$conf"
  else
    cat <<'EOF' | sudo tee -a "$conf" >/dev/null

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  fi

  echo "Updating pacman database..."
  sudo pacman -Sy --noconfirm 2>/dev/null || sudo pacman -Sy
}

_install_proton_manager() {
  local de
  de="$(get_desktop_environment)"

  case "$de" in
  gnome)
    echo "Desktop environment is GNOME: installing ProtonPlus (GTK4/Libadwaita)..."
    install_flatpak_app "com.vysp3r.ProtonPlus" "ProtonPlus"
    ;;
  plasma)
    echo "Desktop environment is KDE Plasma: installing ProtonUp-Qt (Qt)..."
    install_flatpak_app "net.davidotek.pupgui2" "ProtonUp-Qt"
    ;;
  *)
    echo "Unrecognized desktop environment: $de. Skipping Proton manager setup."
    ;;
  esac
}

_install_steam_packages() {
  local pm="$1"

  case "$pm" in
  apt)
    echo "Installing Steam, MangoHud, and Gamescope via Flatpak on Debian..."
    install_flatpak_app "com.valvesoftware.Steam" "Steam"
    install_flatpak_app "org.freedesktop.Platform.VulkanLayer.MangoHud" "MangoHud Vulkan Layer"
    install_flatpak_app "org.freedesktop.Platform.VulkanLayer.gamescope" "Gamescope Vulkan Layer"
    ;;
  dnf)
    echo "Configuring repositories and installing Steam, MangoHud, Gamescope, and GameMode on Fedora..."
    add_fedora_rpmfusion_repo
    install_packages steam mangohud gamescope gamemode
    ;;
  pacman)
    echo "Configuring repositories and installing Steam, MangoHud, Gamescope, GameMode, and fonts on Arch Linux..."
    _enable_arch_multilib
    install_packages steam mangohud gamescope gamemode fonts-liberation
    ;;
  esac
}

_setup_steam() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  apt | dnf | pacman) ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac

  _install_steam_packages "$pm" || return 1
  _install_proton_manager || return 1

  echo "Installing MangoJuice (MangoHud GUI) via Flatpak..."
  install_flatpak_app "io.github.radiolamp.mangojuice" "MangoJuice" || return 1
}

main() {
  echo "Setting up Steam and gaming tools..."
  _setup_steam
  echo "setup-steam complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
