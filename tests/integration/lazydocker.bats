#!/usr/bin/env bats

# Integration tests for setup-lazydocker.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-lazydocker.sh
}

@test "lazydocker binary is available and executable" {
  run lazydocker --version
  [ "$status" -eq 0 ]
}

@test "setup-lazydocker.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-lazydocker.sh
  [ "$status" -eq 0 ]
}
