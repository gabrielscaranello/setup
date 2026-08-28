#!/usr/bin/env bats

# Integration tests for setup-lazygit.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/terminal/setup-lazygit.sh
}

@test "lazygit binary is available and executable" {
  run lazygit --version
  [ "$status" -eq 0 ]
}

@test "setup-lazygit.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/terminal/setup-lazygit.sh
  [ "$status" -eq 0 ]
}
