#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-steam.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-steam.sh
}

@test "_setup_steam fails when package manager is unsupported" {
  _get_package_manager() {
    echo "unsupported_pm"
  }
  run _setup_steam
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager: unsupported_pm" ]]
}

@test "_install_steam_packages installs Flatpaks on Debian" {
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }
  run _install_steam_packages "apt"
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
  run _install_steam_packages "dnf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_fedora_rpmfusion_repo" ]]
  [[ "$output" =~ "installed packages: steam mangohud gamescope gamemode" ]]
}

@test "_install_steam_packages calls _enable_arch_multilib and installs packages on Arch Linux" {
  _enable_arch_multilib() {
    echo "called _enable_arch_multilib"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_steam_packages "pacman"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _enable_arch_multilib" ]]
  [[ "$output" =~ "installed packages: steam mangohud gamescope gamemode fonts-liberation" ]]
}

@test "_enable_arch_multilib skips when pacman.conf does not exist" {
  export PACMAN_CONF="/tmp/nonexistent-pacman-$$.conf"
  run _enable_arch_multilib
  [ "$status" -eq 0 ]
}

@test "_enable_arch_multilib skips when [multilib] is already enabled" {
  export PACMAN_CONF="/tmp/pacman-multilib-$$.conf"
  cat << 'EOF' > "$PACMAN_CONF"
[core]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
  run _enable_arch_multilib
  rm -f "$PACMAN_CONF"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Enabling multilib repository" ]]
}

@test "_enable_arch_multilib uncomments [multilib] and updates pacman database" {
  export PACMAN_CONF="/tmp/pacman-commented-$$.conf"
  cat << 'EOF' > "$PACMAN_CONF"
[core]
Include = /etc/pacman.d/mirrorlist

#[multilib]
#Include = /etc/pacman.d/mirrorlist
EOF
  sudo() {
    "$@"
  }
  pacman() {
    echo "called pacman with: $*"
    return 0
  }
  run _enable_arch_multilib
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling multilib repository" ]]
  [[ "$output" =~ "called pacman with: -Sy" ]]
  grep -q "^\[multilib\]" "$PACMAN_CONF"
  grep -q "^Include = /etc/pacman.d/mirrorlist" "$PACMAN_CONF"
  rm -f "$PACMAN_CONF"
}

@test "_enable_arch_multilib appends [multilib] when section is missing from pacman.conf" {
  export PACMAN_CONF="/tmp/pacman-missing-$$.conf"
  cat << 'EOF' > "$PACMAN_CONF"
[core]
Include = /etc/pacman.d/mirrorlist
EOF
  sudo() {
    "$@"
  }
  pacman() {
    echo "called pacman with: $*"
    return 0
  }
  run _enable_arch_multilib
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Enabling multilib repository" ]]
  [[ "$output" =~ "called pacman with: -Sy" ]]
  grep -q "^\[multilib\]" "$PACMAN_CONF"
  grep -q "^Include = /etc/pacman.d/mirrorlist" "$PACMAN_CONF"
  rm -f "$PACMAN_CONF"
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
  _get_package_manager() { echo "pacman"; }
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
  _get_package_manager() { echo "dnf"; }
  add_fedora_rpmfusion_repo() { return 0; }
  install_packages() { return 0; }
  get_desktop_environment() { echo "gnome"; }
  install_flatpak_app() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Steam and gaming tools..." ]]
  [[ "$output" =~ "setup-steam complete" ]]
}
