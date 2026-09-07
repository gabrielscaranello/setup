#!/usr/bin/env bats

@test "setup-packages.sh completes successfully across all distros" {
  run bash /setup/scripts/system/setup-packages.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-packages complete" ]]
}

@test "setup-packages.sh installs modern CLI tools" {
  run command -v btop
  [ "$status" -eq 0 ]

  run command -v eza
  [ "$status" -eq 0 ]

  run command -v zsh
  [ "$status" -eq 0 ]
}

@test "setup-packages.sh is idempotent" {
  # First run already done in previous tests or executed here
  run bash /setup/scripts/system/setup-packages.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-packages complete" ]]
}
