#!/usr/bin/env bats
# shellcheck disable=SC2218,SC2030,SC2031,SC2317

# Unit tests for setup-update.sh logic and distro branching

setup() {
  source /setup/scripts/system/setup-update.sh
}

@test "_update_debian invokes apt update and apt upgrade -y" {
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _update_debian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo apt update" ]]
  [[ "$output" =~ "sudo apt upgrade -y" ]]
}

@test "_update_lmde invokes mintupdate-cli when available" {
  command() {
    if [ "$1" = "-v" ] && [ "$2" = "mintupdate-cli" ]; then
      return 0
    fi
    builtin command "$@"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _update_lmde
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying updates via mintupdate-cli..." ]]
  [[ "$output" =~ "sudo mintupdate-cli upgrade -r -y" ]]
}

@test "_update_lmde falls back to apt when mintupdate-cli is absent" {
  command() {
    if [ "$1" = "-v" ] && [ "$2" = "mintupdate-cli" ]; then
      return 1
    fi
    builtin command "$@"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _update_lmde
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo apt update" ]]
  [[ "$output" =~ "sudo apt upgrade -y" ]]
}

@test "_update_lmde falls back to apt when mintupdate-cli fails" {
  command() {
    if [ "$1" = "-v" ] && [ "$2" = "mintupdate-cli" ]; then
      return 0
    fi
    builtin command "$@"
  }
  sudo() {
    if [ "$1" = "mintupdate-cli" ]; then
      return 1
    fi
    echo "sudo $*"
    return 0
  }

  run _update_lmde
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mintupdate-cli exited with error; falling back to apt upgrade..." ]]
  [[ "$output" =~ "sudo apt update" ]]
  [[ "$output" =~ "sudo apt upgrade -y" ]]
}

@test "_update_fedora invokes dnf upgrade -y --refresh" {
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _update_fedora
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo dnf upgrade -y --refresh" ]]
}

@test "_update_arch invokes pacman -Syu --noconfirm" {
  sudo() {
    echo "sudo $*"
    return 0
  }

  run _update_arch
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo pacman -Syu --noconfirm" ]]
}

@test "main skips when UPDATE_SKIP_SYSTEM_UPGRADE is set" {
  UPDATE_SKIP_SYSTEM_UPGRADE=1 run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "UPDATE_SKIP_SYSTEM_UPGRADE is active. Skipping system upgrade." ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main delegates to _update_debian on debian" {
  require_supported_distro() { echo "debian"; }
  _update_debian() { echo "called _update_debian"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _update_debian" ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main delegates to _update_lmde on lmde" {
  require_supported_distro() { echo "lmde"; }
  _update_lmde() { echo "called _update_lmde"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _update_lmde" ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main delegates to _update_fedora on fedora" {
  require_supported_distro() { echo "fedora"; }
  _update_fedora() { echo "called _update_fedora"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _update_fedora" ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main delegates to _update_arch on arch" {
  require_supported_distro() { echo "arch"; }
  _update_arch() { echo "called _update_arch"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _update_arch" ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main fails on unsupported distribution" {
  require_supported_distro() { return 1; }

  run main
  [ "$status" -eq 1 ]
}
