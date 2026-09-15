#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/setup-graphics.sh

setup() {
  source /setup/scripts/system/setup-graphics.sh 2> /dev/null || source scripts/system/setup-graphics.sh
}

@test "_setup_graphics runs setup-nvidia.sh and setup-amd.sh in order" {
  bash() {
    echo "called: $(basename "$1")"
    return 0
  }

  run _setup_graphics
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Applying graphics drivers setup" ]]
  [[ "$output" =~ "called: setup-nvidia.sh" ]]
  [[ "$output" =~ "called: setup-amd.sh" ]]
  [[ "$output" =~ "Graphics drivers setup completed successfully." ]]
}

@test "_setup_graphics propagates failure if nvidia setup fails" {
  bash() {
    if [[ "$1" =~ setup-nvidia\.sh$ ]]; then
      return 1
    fi
    return 0
  }

  run _setup_graphics
  [ "$status" -eq 1 ]
}

@test "_setup_graphics propagates failure if amd setup fails" {
  bash() {
    if [[ "$1" =~ setup-amd\.sh$ ]]; then
      return 1
    fi
    return 0
  }

  run _setup_graphics
  [ "$status" -eq 1 ]
}

@test "main executes _setup_graphics successfully" {
  bash() {
    return 0
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Graphics drivers setup completed successfully." ]]
}
