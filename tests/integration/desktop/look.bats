#!/usr/bin/env bats

# Integration tests for setup-look.sh (runs across all distros)

@test "setup-look.sh executes successfully across appearance modules" {
  run bash /setup/scripts/desktop/setup-look.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying desktop appearance setup" ]]
  [[ "$output" =~ "Desktop appearance setup completed successfully." ]]
}

@test "setup-look.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/desktop/setup-look.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Desktop appearance setup completed successfully." ]]
}

@test "main.sh look invokes appearance orchestrator successfully" {
  run bash /setup/main.sh look
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying desktop appearance setup" ]]
  [[ "$output" =~ "Desktop appearance setup completed successfully." ]]
}
