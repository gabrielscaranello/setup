#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/system/arch/setup-desktop-environment.sh 2>/dev/null || \
  source "${BATS_TEST_DIRNAME}/../../../../scripts/system/arch/setup-desktop-environment.sh"
}

@test "main skips execution when distro is not arch" {
  is_distro() { return 1; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "specific to Arch Linux, skipping" ]]
}

@test "_resolve_target_de resolves to plasma when TARGET_DE=plasma" {
  TARGET_DE="plasma" run _resolve_target_de
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]
}

@test "_resolve_target_de resolves to gnome when TARGET_DE=gnome" {
  TARGET_DE="gnome" run _resolve_target_de
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]
}

@test "_resolve_target_de resolves to gnome via --de=gnome argument" {
  run _resolve_target_de --de=gnome
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]
}

@test "_resolve_target_de resolves to plasma via --de=plasma argument" {
  run _resolve_target_de --de=plasma
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]
}

@test "_resolve_target_de detects running desktop environment" {
  TARGET_DE=""
  get_desktop_environment() { echo "gnome"; }

  run _resolve_target_de
  [ "$status" -eq 0 ]
  [ "$output" = "gnome" ]
}

@test "_resolve_target_de defaults to plasma when non-interactive" {
  TARGET_DE=""
  get_desktop_environment() { echo "unknown"; }

  run _resolve_target_de
  [ "$status" -eq 0 ]
  [ "$output" = "plasma" ]
}

@test "_install_plasma_stack installs packages and enables plasmalogin" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  systemctl() {
    echo "systemctl: $*"
    return 0
  }

  run _install_plasma_stack
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: plasma-login-manager plasma-desktop" ]]
  [[ "$output" =~ "Enabling plasmalogin.service" ]]
}

@test "_install_gnome_stack installs packages and enables gdm" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  systemctl() {
    echo "systemctl: $*"
    return 0
  }

  run _install_gnome_stack
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: gdm gnome-shell mutter" ]]
  [[ "$output" =~ "Enabling gdm.service" ]]
}

@test "main provisions plasma stack on Arch Linux" {
  is_distro() { return 0; }
  _resolve_target_de() { echo "plasma"; }
  _install_plasma_stack() { echo "mock plasma installed"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Selected Desktop Environment: plasma" ]]
  [[ "$output" =~ "mock plasma installed" ]]
  [[ "$output" =~ "setup-desktop-environment complete" ]]
}

@test "main provisions gnome stack on Arch Linux" {
  is_distro() { return 0; }
  _resolve_target_de() { echo "gnome"; }
  _install_gnome_stack() { echo "mock gnome installed"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Selected Desktop Environment: gnome" ]]
  [[ "$output" =~ "mock gnome installed" ]]
  [[ "$output" =~ "setup-desktop-environment complete" ]]
}
