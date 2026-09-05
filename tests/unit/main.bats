#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/runners/main.sh 2>/dev/null || source runners/main.sh
}

@test "show_help displays usage and available commands" {
  run show_help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Available Commands:" ]]
  [[ "$output" =~ "all" ]]
  [[ "$output" =~ "neovim" ]]
  [[ "$output" =~ "firewall" ]]
}

@test "run_module help / --help displays help" {
  run run_module "help"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Available Commands:" ]]

  run run_module "--help"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Available Commands:" ]]
}

@test "run_module unknown target returns error and prints help" {
  run run_module "invalid_target_xyz"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown command: invalid_target_xyz" ]]
  [[ "$output" =~ "Available Commands:" ]]
}

@test "run_module invokes expected script for a valid module" {
  bash() {
    echo "executed: $*"
    return 0
  }

  run run_module "docker"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-docker.sh" ]]

  run run_module "firewall"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-firewall.sh" ]]

  run run_module "steam"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-steam.sh" ]]

  run run_module "nvidia"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-nvidia.sh" ]]

  run run_module "amd"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-amd.sh" ]]
}

@test "run_all dispatches to debian runner when distribution is debian" {
  get_distro_id() { echo "debian"; }
  bash() { echo "executed: $*"; return 0; }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Delegating complete setup to Debian runner..." ]]
  [[ "$output" =~ "debian.sh" ]]
}

@test "run_all dispatches to fedora runner when distribution is fedora" {
  get_distro_id() { echo "fedora"; }
  bash() { echo "executed: $*"; return 0; }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Delegating complete setup to Fedora runner..." ]]
  [[ "$output" =~ "fedora.sh" ]]
}

@test "run_all dispatches to arch runner when distribution is arch" {
  get_distro_id() { echo "arch"; }
  bash() { echo "executed: $*"; return 0; }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Delegating complete setup to Arch Linux runner..." ]]
  [[ "$output" =~ "arch.sh" ]]
}

@test "run_all fails when distribution is an unsupported derivative like ubuntu" {
  get_distro_id() { echo "ubuntu"; }

  run run_all
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: 'ubuntu'" ]]
}

@test "run_all fails when distribution detection fails" {
  get_distro_id() { return 1; }

  run run_all
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "main without arguments executes show_help by default" {
  show_help() {
    echo "help called default"
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "help called default" ]]
}
