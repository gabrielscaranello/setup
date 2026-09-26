#!/usr/bin/env bats

# Integration tests for scripts/system/lmde/_repositories.sh

setup() {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id)" != "lmde" ]; then
    skip "Test only runs on LMDE"
  fi
  source /setup/scripts/system/lmde/_repositories.sh
}

@test "get_lmde_codename returns gigi in LMDE container" {
  run get_lmde_codename
  [ "$status" -eq 0 ]
  [ "$output" = "gigi" ]
}

@test "get_lmde_debian_codename returns trixie in LMDE container" {
  run get_lmde_debian_codename
  [ "$status" -eq 0 ]
  [ "$output" = "trixie" ]
}

@test "add_lmde_official_repo is idempotent in LMDE container" {
  run add_lmde_official_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/apt/sources.list.d/mint.list" ] || [ -f "/etc/apt/sources.list" ]
}

@test "add_lmde_backports_repo configures backports repository" {
  run add_lmde_backports_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/apt/sources.list.d/backports.list" ]
  grep -q "trixie-backports" /etc/apt/sources.list.d/backports.list
}
