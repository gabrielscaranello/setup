#!/usr/bin/env bats

# Integration tests for setup-gitflow.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/toolchain/setup-gitflow.sh
}

@test "git-flow is installed and responds to version" {
  run git flow version
  [ "$status" -eq 0 ]
  [[ "$output" =~ 2.2.1 ]]
}

@test "setup-gitflow.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/toolchain/setup-gitflow.sh
  [ "$status" -eq 0 ]
}
