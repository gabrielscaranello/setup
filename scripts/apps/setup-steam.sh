#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/arch/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

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

_install_debian_steam() {
  echo "Installing Steam, MangoHud, and Gamescope via Flatpak on Debian..."
  install_flatpak_app "com.valvesoftware.Steam" "Steam"
  install_flatpak_app "org.freedesktop.Platform.VulkanLayer.MangoHud" "MangoHud Vulkan Layer"
  install_flatpak_app "org.freedesktop.Platform.VulkanLayer.gamescope" "Gamescope Vulkan Layer"
}

_install_fedora_steam() {
  echo "Configuring repositories and installing Steam, MangoHud, Gamescope, and GameMode on Fedora..."
  add_fedora_rpmfusion_repo
  install_packages steam mangohud gamescope gamemode
}

_get_arch_steam_gpu_packages() {
  local -a gpu_pkgs=()
  local has_amd=0
  local has_intel=0
  local has_nvidia=0

  if command -v lspci > /dev/null 2>&1; then
    local pci_display
    pci_display="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true)"
    if echo "$pci_display" | grep -iq "1002" || echo "$pci_display" | grep -iqE "amd|advanced micro devices|radeon"; then
      has_amd=1
    fi
    if echo "$pci_display" | grep -iq "8086" || echo "$pci_display" | grep -iq "intel"; then
      has_intel=1
    fi
    if echo "$pci_display" | grep -iq "10de" || echo "$pci_display" | grep -iq "nvidia"; then
      has_nvidia=1
    fi
  fi

  # Honor GPU_VENDOR override if explicitly set
  case "${GPU_VENDOR:-}" in
    amd) has_amd=1 ;;
    intel) has_intel=1 ;;
    nvidia) has_nvidia=1 ;;
  esac

  if [ "$has_amd" -eq 1 ]; then
    gpu_pkgs+=("vulkan-radeon" "lib32-vulkan-radeon" "lib32-mesa")
  fi
  if [ "$has_intel" -eq 1 ]; then
    gpu_pkgs+=("vulkan-intel" "lib32-vulkan-intel" "lib32-mesa")
  fi
  if [ "$has_nvidia" -eq 1 ]; then
    gpu_pkgs+=("nvidia-utils" "lib32-nvidia-utils")
  fi

  # Default fallback if no physical GPU was detected: install open-source AMD RADV / Mesa
  # to prevent non-interactive pacman from selecting proprietary nvidia-utils
  if [ ${#gpu_pkgs[@]} -eq 0 ]; then
    gpu_pkgs+=("vulkan-radeon" "lib32-vulkan-radeon" "lib32-mesa")
  fi

  echo "${gpu_pkgs[*]}"
}

_install_arch_steam() {
  echo "Configuring repositories and installing Steam, MangoHud, Gamescope, GameMode, fonts, and GPU Vulkan drivers on Arch Linux..."
  add_arch_multilib_repo
  local -a gpu_pkgs
  # shellcheck disable=SC2207
  gpu_pkgs=($(_get_arch_steam_gpu_packages))
  if [ ${#gpu_pkgs[@]} -gt 0 ]; then
    echo "Installing detected GPU Vulkan driver packages: ${gpu_pkgs[*]}..."
  fi
  install_packages "${gpu_pkgs[@]}" steam mangohud gamescope gamemode fonts-liberation
}

_install_steam_packages() {
  local distro="$1"

  case "$distro" in
    debian) _install_debian_steam ;;
    fedora) _install_fedora_steam ;;
    arch) _install_arch_steam ;;
  esac
}

_setup_steam() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    debian | fedora | arch) ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac

  _install_steam_packages "$distro" || return 1
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
