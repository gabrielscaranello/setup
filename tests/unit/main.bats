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
}

@test "run_all dispatches to debian runner when package manager is apt" {
  _get_package_manager() { echo "apt"; }
  bash() { echo "executed: $*"; return 0; }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Delegating complete setup to Debian runner..." ]]
  [[ "$output" =~ "debian.sh" ]]
}

@test "run_all dispatches to fedora runner when package manager is dnf" {
  _get_package_manager() { echo "dnf"; }
  bash() { echo "executed: $*"; return 0; }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Delegating complete setup to Fedora runner..." ]]
  [[ "$output" =~ "fedora.sh" ]]
}

@test "run_all dispatches to arch runner when package manager is pacman" {
  _get_package_manager() { echo "pacman"; }
  bash() { echo "executed: $*"; return 0; }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Delegating complete setup to Arch Linux runner..." ]]
  [[ "$output" =~ "arch.sh" ]]
}

@test "run_all fails when distribution detection fails" {
  _get_package_manager() { return 1; }

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
