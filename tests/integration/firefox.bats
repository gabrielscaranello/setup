#!/usr/bin/env bats

# Integration tests for setup-firefox.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-firefox.sh
}

@test "firefox is installed or available" {
  run firefox --version
  [ "$status" -eq 0 ] || command -v firefox
}

@test "setup-firefox.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-firefox.sh
  [ "$status" -eq 0 ]
}
