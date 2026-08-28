#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for all runner scripts (arch.sh, debian.sh, fedora.sh, _utils.sh)

@test "runners/_utils.sh run_pipeline executes list of steps and completes" {
  source /setup/runners/_utils.sh 2>/dev/null || source runners/_utils.sh 2>/dev/null
  bash() {
    echo "called: $*"
    return 0
  }

  run run_pipeline "Custom Runner" "setup-a.sh:Step A" "setup-b.sh:Step B"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Custom Runner Pipeline" ]]
  [[ "$output" =~ ">>> Running Step A..." ]]
  [[ "$output" =~ "called: " ]]
  [[ "$output" =~ "setup-a.sh" ]]
  [[ "$output" =~ "✓ Step A completed" ]]
  [[ "$output" =~ ">>> Running Step B..." ]]
  [[ "$output" =~ "setup-b.sh" ]]
  [[ "$output" =~ "✓ Step B completed" ]]
  [[ "$output" =~ "Custom Runner Setup Completed Successfully!" ]]
}

@test "runners/arch.sh run_all calls run_pipeline with Arch Linux pipeline" {
  source /setup/runners/arch.sh 2>/dev/null || source runners/arch.sh

  run_pipeline() {
    echo "pipeline: $1"
    return 0
  }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pipeline: Arch Linux Desktop Setup" ]]
}

@test "runners/debian.sh run_all calls run_pipeline with Debian pipeline" {
  source /setup/runners/debian.sh 2>/dev/null || source runners/debian.sh

  run_pipeline() {
    echo "pipeline: $1"
    return 0
  }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pipeline: Debian Desktop Setup" ]]
}

@test "runners/fedora.sh run_all calls run_pipeline with Fedora pipeline" {
  source /setup/runners/fedora.sh 2>/dev/null || source runners/fedora.sh

  run_pipeline() {
    echo "pipeline: $1"
    return 0
  }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pipeline: Fedora Desktop Setup" ]]
}
