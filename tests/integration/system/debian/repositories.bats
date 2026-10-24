#!/usr/bin/env bats

# Integration tests for scripts/system/debian/_repositories.sh

@test "add_debian_nonfree_repo configures non-free components on Debian" {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id 2> /dev/null || true)" != "debian" ]; then
    skip "Test only runs on Debian"
  fi

  source /setup/scripts/system/debian/_repositories.sh
  run add_debian_nonfree_repo
  [ "$status" -eq 0 ]
}

@test "add_debian_backports_repo configures backports on Debian" {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id 2> /dev/null || true)" != "debian" ]; then
    skip "Test only runs on Debian"
  fi

  source /setup/scripts/system/debian/_repositories.sh
  if is_debian_testing; then
    skip "Debian testing does not use backports"
  fi

  run add_debian_backports_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/apt/sources.list.d/backports.list" ]
}

@test "add_debian_vscodium_repo configures vscodium repository on Debian" {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id 2> /dev/null || true)" != "debian" ]; then
    skip "Test only runs on Debian"
  fi

  source /setup/scripts/system/debian/_repositories.sh
  run add_debian_vscodium_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/apt/sources.list.d/vscodium.sources" ]
}

@test "add_debian_mozilla_repo configures mozilla repository on Debian" {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id 2> /dev/null || true)" != "debian" ]; then
    skip "Test only runs on Debian"
  fi

  source /setup/scripts/system/debian/_repositories.sh
  run add_debian_mozilla_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/apt/sources.list.d/mozilla.sources" ]
}
