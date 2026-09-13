#!/usr/bin/env bats

# Integration tests for setup-debloat.sh (runs across all distros in Docker)

setup_file() {
  bash /setup/scripts/system/setup-debloat.sh
}

@test "setup-debloat.sh runs successfully across distributions" {
  run bash /setup/scripts/system/setup-debloat.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-debloat complete" ]]
}

@test "setup-debloat.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/system/setup-debloat.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-debloat complete" ]]
}
