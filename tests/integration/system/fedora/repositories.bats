#!/usr/bin/env bats

# Integration tests for scripts/system/fedora/_repositories.sh

@test "add_fedora_docker_repo configures repo file on Fedora" {
  if ! command -v dnf >/dev/null 2>&1; then
    skip "Test only runs on Fedora"
  fi

  source /setup/scripts/system/fedora/_repositories.sh
  run add_fedora_docker_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/yum.repos.d/docker-ce.repo" ]
}

@test "add_fedora_vscodium_repo configures repo file on Fedora" {
  if ! command -v dnf >/dev/null 2>&1; then
    skip "Test only runs on Fedora"
  fi

  source /setup/scripts/system/fedora/_repositories.sh
  run add_fedora_vscodium_repo
  [ "$status" -eq 0 ]
  [ -f "/etc/yum.repos.d/vscodium.repo" ]
}

@test "add_fedora_rpmfusion_repo configures rpmfusion on Fedora" {
  if ! command -v dnf >/dev/null 2>&1; then
    skip "Test only runs on Fedora"
  fi

  source /setup/scripts/system/fedora/_repositories.sh
  run add_fedora_rpmfusion_repo
  [ "$status" -eq 0 ]
}
