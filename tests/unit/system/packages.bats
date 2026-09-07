#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/system/setup-packages.sh 2>/dev/null || \
  source "${BATS_TEST_DIRNAME}/../../../scripts/system/setup-packages.sh"
}

@test "_install_cli_tools installs modern CLI utilities" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_cli_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: bat btop eza gdu zsh zsh-completions man-db util-linux-user" ]]
}

@test "_install_hardware_tools installs hardware and power management packages" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_hardware_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: power-profiles-daemon numlockx fwupd" ]]
}

@test "_install_filesystem_tools installs filesystem compatibility tools" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_filesystem_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: dosfstools mtools ntfs-3g" ]]
}

@test "_install_session_tools installs XDG, connectivity, and session utilities" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_session_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: xdg-user-dirs xdg-utils openssh dialog keychain" ]]
}

@test "_install_spelling_dictionaries installs Portuguese and English dictionaries" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_spelling_dictionaries
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: spell-pt-br spell-en" ]]
}

@test "_initialize_xdg_dirs updates user directories when command is available" {
  xdg-user-dirs-update() {
    echo "xdg dirs updated"
    return 0
  }
  run _initialize_xdg_dirs
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Initializing XDG user directories" ]]
}

@test "main runs all setup steps in order" {
  install_packages() {
    echo "mock installed: $*"
    return 0
  }
  xdg-user-dirs-update() {
    echo "mock xdg updated"
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up core system packages" ]]
  [[ "$output" =~ "mock installed: bat btop eza gdu zsh zsh-completions man-db util-linux-user" ]]
  [[ "$output" =~ "mock installed: power-profiles-daemon numlockx fwupd" ]]
  [[ "$output" =~ "mock installed: dosfstools mtools ntfs-3g" ]]
  [[ "$output" =~ "mock installed: xdg-user-dirs xdg-utils openssh dialog keychain" ]]
  [[ "$output" =~ "mock installed: spell-pt-br spell-en" ]]
  [[ "$output" =~ "setup-packages complete" ]]
}
