#!/usr/bin/env bats

# Integration tests for runners dispatch and execution

@test "main.sh is executable and responds to help" {
  run /setup/main.sh help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Available Commands:" ]]
}

@test "runners/main.sh is executable and responds to help" {
  run /setup/runners/main.sh help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Available Commands:" ]]
}

@test "current distro runner file exists and is executable" {
  if command -v pacman >/dev/null 2>&1; then
    [ -x "/setup/runners/arch.sh" ]
  elif command -v apt >/dev/null 2>&1; then
    [ -x "/setup/runners/debian.sh" ]
  elif command -v dnf >/dev/null 2>&1; then
    [ -x "/setup/runners/fedora.sh" ]
  fi
}
