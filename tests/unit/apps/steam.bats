#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-steam.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-steam.sh
}

@test "_setup_steam fails when distribution is unsupported" {
  get_distro_id() {
    echo "unsupported_distro"
  }
  run _setup_steam
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: unsupported_distro" ]]
}

@test "_install_steam_packages installs Flatpaks on Debian" {
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_steam_packages "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Steam, GameMode, MangoHud, and Gamescope via Flatpak on Debian" ]]
  [[ "$output" =~ "installed packages: gamemode" ]]
  [[ "$output" =~ "installed flatpak: com.valvesoftware.Steam (Steam)" ]]
  [[ "$output" =~ "installed flatpak: org.freedesktop.Platform.VulkanLayer.MangoHud (MangoHud Vulkan Layer)" ]]
  [[ "$output" =~ "installed flatpak: org.freedesktop.Platform.VulkanLayer.gamescope (Gamescope Vulkan Layer)" ]]
}

@test "_install_steam_packages calls add_fedora_rpmfusion_repo on Fedora" {
  add_fedora_rpmfusion_repo() {
    echo "called add_fedora_rpmfusion_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_steam_packages "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_fedora_rpmfusion_repo" ]]
  [[ "$output" =~ "installed packages: steam mangohud gamescope gamemode" ]]
}

@test "_install_steam_packages calls add_arch_multilib_repo and installs packages on Arch Linux" {
  add_arch_multilib_repo() {
    echo "called add_arch_multilib_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  _get_arch_steam_gpu_packages() {
    echo "vulkan-radeon lib32-vulkan-radeon lib32-mesa"
  }
  run _install_steam_packages "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_arch_multilib_repo" ]]
  [[ "$output" =~ "installed packages: vulkan-radeon lib32-vulkan-radeon lib32-mesa steam mangohud gamescope gamemode fonts-liberation" ]]
}
@test "_install_steam_packages installs packages on openSUSE Tumbleweed" {
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_steam_packages "opensuse-tumbleweed"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Steam, MangoHud, Gamescope, and GameMode from official repositories on openSUSE Tumbleweed" ]]
  [[ "$output" =~ "installed packages: steam mangohud gamescope gamemode" ]]
}

@test "_install_steam_packages installs Flatpaks and enables 32-bit on openSUSE Leap" {
  _enable_leap_32bit() {
    echo "called _enable_leap_32bit"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_steam_packages "opensuse-leap"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _enable_leap_32bit" ]]
  [[ "$output" =~ "Installing Steam, GameMode, MangoHud, and Gamescope via Flatpak on openSUSE Leap" ]]
  [[ "$output" =~ "installed packages: gamemode" ]]
  [[ "$output" =~ "installed flatpak: com.valvesoftware.Steam (Steam)" ]]
  [[ "$output" =~ "installed flatpak: org.freedesktop.Platform.VulkanLayer.MangoHud (MangoHud Vulkan Layer)" ]]
  [[ "$output" =~ "installed flatpak: org.freedesktop.Platform.VulkanLayer.gamescope (Gamescope Vulkan Layer)" ]]

  run _install_steam_packages "opensuse"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _enable_leap_32bit" ]]
  [[ "$output" =~ "installed flatpak: com.valvesoftware.Steam (Steam)" ]]
}

@test "_enable_leap_32bit installs compatibility packages and configures update-bootloader" {
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  update-bootloader() {
    echo "called update-bootloader: $*"
    return 1
  }
  sudo() { "$@"; }
  run _enable_leap_32bit
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling 32-bit (IA32) kernel emulation" ]]
  [[ "$output" =~ "installed packages: grub2-compat-ia32 selinux-policy-targeted-gaming steam-devices" ]]
  [[ "$output" =~ "called update-bootloader: --add-option ia32_emulation=1" ]]
}

@test "_install_debian_steam installs Steam flatpaks and gamemode" {
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  install_flatpak_app() {
    echo "flatpak: $1"
    return 0
  }
  run _install_debian_steam
  [ "$status" -eq 0 ]
  [[ "$output" =~ "flatpak: com.valvesoftware.Steam" ]]
  [[ "$output" =~ "installed packages: gamemode" ]]
}

@test "_install_flatpak_gaming_layer installs matching runtime branch and updates layer" {
  install_flatpak_app() {
    echo "called install_flatpak_app: $1 ($2)"
    return 0
  }
  flatpak() {
    if [ "$1" = "info" ]; then
      echo "Runtime: org.freedesktop.Platform/x86_64/24.08"
      return 0
    fi
    if [ "$1" = "install" ]; then
      echo "called flatpak install: $*"
      return 0
    fi
    if [ "$1" = "update" ]; then
      echo "called flatpak update: $*"
      return 0
    fi
    return 0
  }
  sudo() { "$@"; }

  run _install_flatpak_gaming_layer "org.freedesktop.Platform.VulkanLayer.MangoHud" "MangoHud Vulkan Layer"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called install_flatpak_app: org.freedesktop.Platform.VulkanLayer.MangoHud (MangoHud Vulkan Layer)" ]]
  [[ "$output" =~ "Ensuring MangoHud Vulkan Layer on Steam runtime branch '24.08'" ]]
  [[ "$output" =~ "called flatpak install: install -y --noninteractive flathub org.freedesktop.Platform.VulkanLayer.MangoHud//24.08" ]]
  [[ "$output" =~ "called flatpak update: update -y --noninteractive org.freedesktop.Platform.VulkanLayer.MangoHud" ]]
}

@test "_install_fedora_steam calls add_fedora_rpmfusion_repo and installs packages" {
  add_fedora_rpmfusion_repo() { echo "called rpmfusion"; }
  install_packages() { echo "packages: $*"; }
  run _install_fedora_steam
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called rpmfusion" ]]
  [[ "$output" =~ "packages: steam mangohud gamescope gamemode" ]]
}

@test "_install_arch_steam calls add_arch_multilib_repo and installs packages" {
  add_arch_multilib_repo() { echo "called multilib"; }
  install_packages() { echo "packages: $*"; }
  _get_arch_steam_gpu_packages() {
    echo "vulkan-radeon lib32-vulkan-radeon lib32-mesa"
  }
  run _install_arch_steam
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called multilib" ]]
  [[ "$output" =~ "packages: vulkan-radeon lib32-vulkan-radeon lib32-mesa steam mangohud gamescope gamemode fonts-liberation" ]]
}

@test "_get_arch_steam_gpu_packages detects AMD GPU" {
  lspci() {
    echo "03:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [1002:747e]"
  }
  run _get_arch_steam_gpu_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "vulkan-radeon" ]]
  [[ "$output" =~ "lib32-vulkan-radeon" ]]
  [[ "$output" =~ "lib32-mesa" ]]
  [[ ! "$output" =~ "nvidia-utils" ]]
}

@test "_get_arch_steam_gpu_packages detects Intel GPU" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation [8086:a7a0]"
  }
  run _get_arch_steam_gpu_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "vulkan-intel" ]]
  [[ "$output" =~ "lib32-vulkan-intel" ]]
  [[ "$output" =~ "lib32-mesa" ]]
  [[ ! "$output" =~ "nvidia-utils" ]]
}

@test "_get_arch_steam_gpu_packages detects NVIDIA GPU" {
  lspci() {
    echo "01:00.0 VGA compatible controller [0300]: NVIDIA Corporation [10de:2860]"
  }
  run _get_arch_steam_gpu_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "nvidia-utils" ]]
  [[ "$output" =~ "lib32-nvidia-utils" ]]
  [[ ! "$output" =~ "vulkan-radeon" ]]
}

@test "_get_arch_steam_gpu_packages detects hybrid graphics" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Intel Corporation [8086:a7a0]"
    echo "01:00.0 3D controller [0302]: NVIDIA Corporation [10de:2860]"
  }
  run _get_arch_steam_gpu_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "vulkan-intel" ]]
  [[ "$output" =~ "nvidia-utils" ]]
}

@test "_get_arch_steam_gpu_packages falls back to open-source AMD RADV when no GPU matches" {
  lspci() {
    echo "00:02.0 VGA compatible controller [0300]: Unknown controller [1234:5678]"
  }
  run _get_arch_steam_gpu_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "vulkan-radeon" ]]
  [[ "$output" =~ "lib32-vulkan-radeon" ]]
  [[ "$output" =~ "lib32-mesa" ]]
  [[ ! "$output" =~ "nvidia-utils" ]]
}

@test "_install_proton_manager installs ProtonPlus on GNOME" {
  get_desktop_environment() {
    echo "gnome"
  }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_proton_manager
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop environment is GNOME: installing ProtonPlus" ]]
  [[ "$output" =~ "installed flatpak: com.vysp3r.ProtonPlus (ProtonPlus)" ]]
}

@test "_install_proton_manager installs ProtonUp-Qt on KDE Plasma" {
  get_desktop_environment() {
    echo "plasma"
  }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_proton_manager
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop environment is KDE Plasma: installing ProtonUp-Qt" ]]
  [[ "$output" =~ "installed flatpak: net.davidotek.pupgui2 (ProtonUp-Qt)" ]]
}

@test "_install_proton_manager skips on unrecognized desktop environment" {
  get_desktop_environment() {
    echo "unknown"
  }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_proton_manager
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unrecognized desktop environment: unknown. Skipping Proton manager setup." ]]
  [[ ! "$output" =~ "installed flatpak" ]]
}

@test "_setup_steam installs MangoJuice via Flatpak" {
  get_distro_id() { echo "arch"; }
  _install_steam_packages() { return 0; }
  _install_proton_manager() { return 0; }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }

  run _setup_steam
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing MangoJuice (MangoHud GUI) via Flatpak..." ]]
  [[ "$output" =~ "installed flatpak: io.github.radiolamp.mangojuice (MangoJuice)" ]]
}

@test "setup-steam main executes full installation pipeline" {
  get_distro_id() { echo "fedora"; }
  add_fedora_rpmfusion_repo() { return 0; }
  install_packages() { return 0; }
  get_desktop_environment() { echo "gnome"; }
  install_flatpak_app() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Steam and gaming tools..." ]]
  [[ "$output" =~ "setup-steam complete" ]]
}
