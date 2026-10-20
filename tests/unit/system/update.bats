#!/usr/bin/env bats
# shellcheck disable=SC2218,SC2030,SC2031,SC2317

# Unit tests for setup-update.sh logic and distro branching

setup() {
  source /setup/scripts/system/setup-update.sh
}

@test "main skips when UPDATE_SKIP_SYSTEM_UPGRADE is set" {
  UPDATE_SKIP_SYSTEM_UPGRADE=1 run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "UPDATE_SKIP_SYSTEM_UPGRADE is active. Skipping system upgrade." ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main upgrades the system through upgrade_system on supported distributions" {
  require_supported_distro() { echo "debian"; }
  upgrade_system() { echo "called upgrade_system"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called upgrade_system" ]]
  [[ "$output" =~ "setup-update complete" ]]
}

@test "main fails on unsupported distribution" {
  require_supported_distro() { return 1; }

  run main
  [ "$status" -eq 1 ]
}
