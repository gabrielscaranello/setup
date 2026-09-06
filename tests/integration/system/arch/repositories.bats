#!/usr/bin/env bats

# Integration tests for scripts/system/arch/_repositories.sh

setup_file() {
  source /setup/scripts/system/arch/_repositories.sh
}

@test "add_arch_multilib_repo runs and configures multilib when on Arch Linux" {
  if ! command -v pacman >/dev/null 2>&1; then
    skip "Test only runs on Arch Linux"
  fi

  source /setup/scripts/system/arch/_repositories.sh
  run add_arch_multilib_repo
  [ "$status" -eq 0 ]

  run grep -q "^\[multilib\]" /etc/pacman.conf
  [ "$status" -eq 0 ]
}

@test "add_arch_multilib_repo is idempotent" {
  if ! command -v pacman >/dev/null 2>&1; then
    skip "Test only runs on Arch Linux"
  fi

  source /setup/scripts/system/arch/_repositories.sh
  run add_arch_multilib_repo
  [ "$status" -eq 0 ]
}
