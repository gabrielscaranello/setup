#!/usr/bin/env bats

# Integration tests for setup-update.sh (runs across all distros in Docker)

setup_file() {
  UPDATE_SKIP_SYSTEM_UPGRADE=1 bash /setup/scripts/system/setup-update.sh
}

@test "setup-update.sh runs successfully across distributions" {
  run env UPDATE_SKIP_SYSTEM_UPGRADE=1 bash /setup/scripts/system/setup-update.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "setup-update.sh is idempotent (second run succeeds)" {
  run env UPDATE_SKIP_SYSTEM_UPGRADE=1 bash /setup/scripts/system/setup-update.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "setup-update complete" ]]
}
