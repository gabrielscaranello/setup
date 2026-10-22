#!/usr/bin/env bats

# Integration tests for setup-python.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/toolchain/setup-python.sh
}

@test "python3 and pip3 binaries are available and respond to version" {
  run bash -c "python3 --version && pip3 --version"
  [ "$status" -eq 0 ]
}

@test "python3 venv module is functional" {
  run bash -c "python3 -m venv --help"
  [ "$status" -eq 0 ]
}

@test "setup-python.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/toolchain/setup-python.sh
  [ "$status" -eq 0 ]
}
