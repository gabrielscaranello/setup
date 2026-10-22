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

@test "runners/opensuse.sh run_all calls run_pipeline with openSUSE pipeline and includes kernel on Leap" {
  source /setup/runners/opensuse.sh 2>/dev/null || source runners/opensuse.sh
  get_distro_id() { echo "opensuse-leap"; }

  run_pipeline() {
    echo "pipeline: $1"
    shift
    printf "step: %s\n" "$@"
    return 0
  }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pipeline: openSUSE Desktop Setup" ]]
  [[ "$output" =~ "system/opensuse/setup-kernel.sh:openSUSE Leap latest kernel and headers setup" ]]
}

@test "runners/opensuse.sh run_all skips kernel step on openSUSE Tumbleweed" {
  source /setup/runners/opensuse.sh 2>/dev/null || source runners/opensuse.sh
  get_distro_id() { echo "opensuse-tumbleweed"; }

  run_pipeline() {
    echo "pipeline: $1"
    shift
    printf "step: %s\n" "$@"
    return 0
  }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pipeline: openSUSE Desktop Setup" ]]
  [[ ! "$output" =~ "system/opensuse/setup-kernel.sh" ]]
}

@test "runners/_utils.sh COMMON_POST_STEPS orders desktop-apps before default-apps" {
  source /setup/runners/_utils.sh 2>/dev/null || source runners/_utils.sh 2>/dev/null

  local desktop_apps_idx=-1
  local default_apps_idx=-1
  local i=0

  for step in "${COMMON_POST_STEPS[@]}"; do
    if [[ "$step" =~ ^desktop/setup-desktop-apps\.sh ]]; then
      desktop_apps_idx=$i
    elif [[ "$step" =~ ^apps/setup-default-apps\.sh ]]; then
      default_apps_idx=$i
    fi
    i=$((i + 1))
  done

  [ "$desktop_apps_idx" -ge 0 ]
  [ "$default_apps_idx" -ge 0 ]
  [ "$desktop_apps_idx" -lt "$default_apps_idx" ]
}

@test "runners/wsl.sh run_all calls run_pipeline with WSL pipeline on supported distributions" {
  source /setup/runners/wsl.sh 2>/dev/null || source runners/wsl.sh
  require_supported_distro() { echo "arch"; }

  run_pipeline() {
    echo "pipeline: $1"
    shift
    printf "step: %s\n" "$@"
    return 0
  }

  run run_all
  [ "$status" -eq 0 ]
  [[ "$output" =~ "pipeline: WSL Development Setup" ]]
  [[ "$output" =~ "terminal/setup-cli.sh" ]]
  [[ "$output" =~ "toolchain/setup-docker.sh" ]]
  [[ "$output" =~ "toolchain/setup-gh.sh" ]]
  [[ "$output" =~ "toolchain/setup-python.sh" ]]
  [[ "$output" =~ "toolchain/setup-neovim.sh" ]]
  [[ ! "$output" =~ "system/setup-packages.sh" ]]
  [[ ! "$output" =~ "desktop/" ]]
}

@test "runners/wsl.sh run_all fails on unsupported distribution" {
  source /setup/runners/wsl.sh 2>/dev/null || source runners/wsl.sh
  get_distro_id() {
    echo "unknown-distro"
    return 1
  }

  run run_all
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

