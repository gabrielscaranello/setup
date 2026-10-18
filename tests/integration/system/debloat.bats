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

@test "setup-debloat.sh locks removed packages on openSUSE" {
  source /setup/scripts/_utils.sh
  local distro
  distro="$(get_distro_id)"
  if [[ ! "$distro" =~ ^opensuse ]]; then
    skip "Test only runs on openSUSE"
  fi

  # Install a lightweight debloat target if not installed
  if ! rpm -q xterm > /dev/null 2>&1; then
    sudo zypper --non-interactive install -y --no-recommends xterm || skip "Could not install xterm for test"
  fi

  run bash /setup/scripts/system/setup-debloat.sh
  [ "$status" -eq 0 ]

  # Verify xterm was removed
  run rpm -q xterm
  [ "$status" -ne 0 ]

  # Verify xterm is locked in zypper
  run zypper locks
  [ "$status" -eq 0 ]
  [[ "$output" =~ "xterm" ]]
}
