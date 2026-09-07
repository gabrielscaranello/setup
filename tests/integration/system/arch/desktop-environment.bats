#!/usr/bin/env bats

@test "setup-desktop-environment.sh exits 0 cleanly on non-Arch systems" {
  if command -v pacman >/dev/null 2>&1; then
    skip "Test runs only on non-Arch systems"
  fi

  run bash /setup/scripts/system/arch/setup-desktop-environment.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "specific to Arch Linux, skipping" ]]
}

@test "Arch Linux has all KDE Plasma stack packages available" {
  if ! command -v pacman >/dev/null 2>&1; then
    skip "Test runs only on Arch Linux"
  fi

  local kde_pkgs=(
    plasma-login-manager
    plasma-desktop
    plasma-workspace
    plasma-workspace-wallpapers
    plasma-nm
    plasma-pa
    powerdevil
    kscreen
    polkit-kde-agent
    plasma-integration
    pipewire
    pipewire-pulse
    wireplumber
    gst-plugin-pipewire
    xdg-desktop-portal-kde
    egl-wayland
    xorg-xwayland
  )

  for pkg in "${kde_pkgs[@]}"; do
    run pacman -Si "$pkg"
    [ "$status" -eq 0 ]
  done
}

@test "Arch Linux has all GNOME stack packages available" {
  if ! command -v pacman >/dev/null 2>&1; then
    skip "Test runs only on Arch Linux"
  fi

  local gnome_pkgs=(
    gdm
    gnome-shell
    mutter
    gnome-control-center
    gnome-session
    gsettings-desktop-schemas
    pipewire
    pipewire-pulse
    wireplumber
    xdg-desktop-portal-gnome
    xorg-xwayland
  )

  for pkg in "${gnome_pkgs[@]}"; do
    run pacman -Si "$pkg"
    [ "$status" -eq 0 ]
  done
}

@test "setup-desktop-environment.sh completes successfully with plasma on Arch" {
  if ! command -v pacman >/dev/null 2>&1; then
    skip "Test runs only on Arch Linux"
  fi

  ARCH_DE_SKIP_PACKAGE_INSTALL=1 run bash /setup/scripts/system/arch/setup-desktop-environment.sh --de=plasma
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Selected Desktop Environment: plasma" ]]
  [[ "$output" =~ "setup-desktop-environment complete" ]]
}

@test "setup-desktop-environment.sh completes successfully with gnome on Arch" {
  if ! command -v pacman >/dev/null 2>&1; then
    skip "Test runs only on Arch Linux"
  fi

  ARCH_DE_SKIP_PACKAGE_INSTALL=1 run bash /setup/scripts/system/arch/setup-desktop-environment.sh --de=gnome
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Selected Desktop Environment: gnome" ]]
  [[ "$output" =~ "setup-desktop-environment complete" ]]
}
