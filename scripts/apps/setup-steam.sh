#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/_gpu_utils.sh" 2> /dev/null || true

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

_install_flatpak_gaming_layer() {
  local layer_id="$1"
  local layer_name="${2:-$layer_id}"

  install_flatpak_app "$layer_id" "$layer_name"

  # Match and install corresponding Freedesktop runtime branch used by Steam if present
  if command -v flatpak > /dev/null 2>&1; then
    local steam_branch
    steam_branch="$(flatpak info com.valvesoftware.Steam 2> /dev/null | grep -E '^Runtime:' | awk '{print $2}' | cut -d/ -f3 || true)"
    if [ -n "$steam_branch" ]; then
      echo "Ensuring $layer_name on Steam runtime branch '$steam_branch'..."
      sudo flatpak install -y --noninteractive flathub "${layer_id}//${steam_branch}" 2> /dev/null || true
    fi

    # Always ensure the layer is updated to the latest available version
    sudo flatpak update -y --noninteractive "$layer_id" 2> /dev/null || true
  fi
}

_configure_steam_flatpak_permissions() {
  if command -v flatpak > /dev/null 2>&1; then
    echo "Configuring GameMode portal and MangoHud access permissions for Flatpak Steam..."
    flatpak override --user --talk-name=org.freedesktop.portal.GameMode com.valvesoftware.Steam 2> /dev/null || true
    flatpak override --user --filesystem=xdg-config/MangoHud:ro com.valvesoftware.Steam 2> /dev/null || true
  fi
}

_install_flatpak_steam_bundle() {
  install_packages gamemode
  install_flatpak_app "com.valvesoftware.Steam" "Steam"
  _install_flatpak_gaming_layer "org.freedesktop.Platform.VulkanLayer.MangoHud" "MangoHud Vulkan Layer"
  _install_flatpak_gaming_layer "org.freedesktop.Platform.VulkanLayer.gamescope" "Gamescope Vulkan Layer"
  _configure_steam_flatpak_permissions
}

_install_debian_steam() {
  echo "Installing Steam, GameMode, MangoHud, and Gamescope via Flatpak on Debian..."
  _install_flatpak_steam_bundle
}

_install_fedora_steam() {
  echo "Configuring repositories and installing Steam, MangoHud, Gamescope, and GameMode on Fedora..."
  declare -F add_fedora_rpmfusion_repo > /dev/null 2>&1 || source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true
  add_fedora_rpmfusion_repo
  install_packages steam mangohud gamescope gamemode
}

_get_arch_steam_gpu_packages() {
  local -a gpu_pkgs=()

  if has_amd_gpu; then
    gpu_pkgs+=("vulkan-radeon" "lib32-vulkan-radeon" "lib32-mesa")
  fi
  if has_intel_gpu; then
    gpu_pkgs+=("vulkan-intel" "lib32-vulkan-intel" "lib32-mesa")
  fi
  if has_nvidia_gpu; then
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
  declare -F add_arch_multilib_repo > /dev/null 2>&1 || source "scripts/system/arch/_repositories.sh" 2> /dev/null || true
  add_arch_multilib_repo
  local -a gpu_pkgs
  # shellcheck disable=SC2207
  gpu_pkgs=($(_get_arch_steam_gpu_packages))
  if [ ${#gpu_pkgs[@]} -gt 0 ]; then
    echo "Installing detected GPU Vulkan driver packages: ${gpu_pkgs[*]}..."
  fi
  install_packages "${gpu_pkgs[@]}" steam mangohud gamescope gamemode fonts-liberation
}

_install_leap_steam() {
  _enable_leap_32bit
  echo "Installing Steam, GameMode, MangoHud, and Gamescope via Flatpak on openSUSE Leap..."
  _install_flatpak_steam_bundle
}

_install_tumbleweed_steam() {
  echo "Installing Steam, MangoHud, Gamescope, and GameMode from official repositories on openSUSE Tumbleweed..."
  install_packages steam mangohud gamescope gamemode
}

_enable_leap_32bit() {
  echo "Enabling 32-bit (IA32) kernel emulation and gaming compatibility on openSUSE Leap..."
  install_packages grub2-compat-ia32 selinux-policy-targeted-gaming steam-devices || true

  if command -v update-bootloader > /dev/null 2>&1; then
    if ! update-bootloader --get-option "ia32_emulation=1" &> /dev/null; then
      sudo update-bootloader --add-option "ia32_emulation=1" 2> /dev/null || true
      sudo update-bootloader --config 2> /dev/null || true
    fi
  elif [ -f /etc/default/grub ]; then
    if ! grep -q "ia32_emulation=1" /etc/default/grub; then
      echo "Configuring ia32_emulation=1 in /etc/default/grub..."
      sudo sed -i 's/\(GRUB_CMDLINE_LINUX="[^"]*\)/\1 ia32_emulation=1/' /etc/default/grub 2> /dev/null || true
      update_grub_config
    fi
  fi
}

_install_steam_packages() {
  local distro="$1"

  case "$distro" in
    debian) _install_debian_steam ;;
    fedora) _install_fedora_steam ;;
    arch) _install_arch_steam ;;
    opensuse-tumbleweed) _install_tumbleweed_steam ;;
    opensuse | opensuse-leap) _install_leap_steam ;;
  esac
}

_setup_steam() {
  local distro
  distro="$(require_supported_distro)" || return 1

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
