#!/usr/bin/env bats

# Integration tests for setup-graphics.sh (runs across all distros)

@test "setup-graphics.sh executes successfully across GPU driver modules" {
  run bash /setup/scripts/system/setup-graphics.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying graphics drivers setup" ]]
  [[ "$output" =~ "Graphics drivers setup completed successfully." ]]
}

@test "setup-graphics.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/system/setup-graphics.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Graphics drivers setup completed successfully." ]]
}

@test "main.sh graphics invokes graphics orchestrator successfully" {
  run bash /setup/main.sh graphics
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying graphics drivers setup" ]]
  [[ "$output" =~ "Graphics drivers setup completed successfully." ]]
}
