#!/usr/bin/env bats

# Integration tests for scripts/system/opensuse/_repositories.sh

@test "add_opensuse_packman_repo configures packman repository on openSUSE" {
  source /setup/scripts/_utils.sh
  if ! is_distro "opensuse"; then
    skip "Test only runs on openSUSE"
  fi

  source /setup/scripts/system/opensuse/_repositories.sh
  run add_opensuse_packman_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/zypp/repos.d/packman-essentials.repo" ]
}

@test "add_opensuse_nonfree_repo ensures non-free repo on openSUSE" {
  source /setup/scripts/_utils.sh
  if ! is_distro "opensuse"; then
    skip "Test only runs on openSUSE"
  fi

  source /setup/scripts/system/opensuse/_repositories.sh
  run add_opensuse_nonfree_repo
  [ "$status" -eq 0 ]
}

@test "add_opensuse_vscodium_repo configures vscodium repository on openSUSE" {
  source /setup/scripts/_utils.sh
  if ! is_distro "opensuse"; then
    skip "Test only runs on openSUSE"
  fi

  source /setup/scripts/system/opensuse/_repositories.sh
  run add_opensuse_vscodium_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/zypp/repos.d/vscodium.repo" ]
}

@test "add_opensuse_mozilla_repo configures mozilla repository on openSUSE" {
  source /setup/scripts/_utils.sh
  if ! is_distro "opensuse"; then
    skip "Test only runs on openSUSE"
  fi

  source /setup/scripts/system/opensuse/_repositories.sh
  run add_opensuse_mozilla_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/zypp/repos.d/mozilla.repo" ]
}
