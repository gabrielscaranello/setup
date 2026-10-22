#!/usr/bin/env bats

# Integration tests for setup-cli.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/terminal/setup-cli.sh
}

@test "setup-cli.sh installs modern CLI utilities and wl-clipboard" {
  run command -v btop
  [ "$status" -eq 0 ]

  run command -v eza
  [ "$status" -eq 0 ]

  run command -v zsh
  [ "$status" -eq 0 ]

  run command -v wl-copy
  [ "$status" -eq 0 ]
}

@test "setup-cli.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/terminal/setup-cli.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-cli complete" ]]
}
