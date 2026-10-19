#!/usr/bin/env bats

# Integration tests for scripts/system/opensuse/setup-kernel.sh

setup_file() {
  bash /setup/scripts/system/opensuse/setup-kernel.sh
}

@test "setup-kernel.sh executes successfully" {
  run bash /setup/scripts/system/opensuse/setup-kernel.sh
  [ "$status" -eq 0 ]
}

@test "backports repository is configured on openSUSE Leap" {
  source /setup/scripts/_utils.sh
  local distro
  distro="$(get_distro_id)"
  if [ "$distro" != "opensuse" ] && [ "$distro" != "opensuse-leap" ]; then
    skip "Test only runs on openSUSE Leap"
  fi

  run bash -c "zypper lr Kernel:stable > /dev/null 2>&1 || zypper lr Kernel_stable > /dev/null 2>&1"
  [ "$status" -eq 0 ]
}

@test "installed kernel packages correspond to backports on openSUSE Leap" {
  source /setup/scripts/_utils.sh
  local distro
  distro="$(get_distro_id)"
  if [ "$distro" != "opensuse" ] && [ "$distro" != "opensuse-leap" ]; then
    skip "Test only runs on openSUSE Leap"
  fi

  run rpm -q kernel-default
  [ "$status" -eq 0 ]

  run rpm -q kernel-default-devel
  [ "$status" -eq 0 ]
}
