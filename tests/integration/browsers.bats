#!/usr/bin/env bats

# Integration tests for setup-browsers.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-browsers.sh
}

@test "firefox is installed or available" {
  run firefox --version
  [ "$status" -eq 0 ] || command -v firefox
}

@test "chromium is installed or available" {
  if command -v chromium >/dev/null 2>&1; then
    run chromium --version
    [ "$status" -eq 0 ]
  else
    run chromium-browser --version
    [ "$status" -eq 0 ]
  fi
}

@test "setup-browsers.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-browsers.sh
  [ "$status" -eq 0 ]
}

