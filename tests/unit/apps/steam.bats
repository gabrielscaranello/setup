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
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_steam_packages "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Steam, MangoHud, and Gamescope via Flatpak on Debian" ]]
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
  run _install_steam_packages "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_arch_multilib_repo" ]]
  [[ "$output" =~ "installed packages: steam mangohud gamescope gamemode fonts-liberation" ]]
}

@test "_install_debian_steam installs Steam flatpaks" {
  install_flatpak_app() {
    echo "flatpak: $1"
    return 0
  }
  run _install_debian_steam
  [ "$status" -eq 0 ]
  [[ "$output" =~ "flatpak: com.valvesoftware.Steam" ]]
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
  run _install_arch_steam
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called multilib" ]]
  [[ "$output" =~ "packages: steam mangohud gamescope gamemode fonts-liberation" ]]
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
