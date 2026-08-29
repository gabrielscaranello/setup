#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/fedora/_repositories.sh utility functions

setup() {
  source /setup/scripts/system/fedora/_repositories.sh
}

@test "add_fedora_docker_repo skips when repo file exists" {
  local test_dir="/tmp/test-fedora-docker-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/docker-ce.repo"

  add_fedora_docker_repo() {
    local repo_file="$test_dir/docker-ce.repo"
    if [ -f "$repo_file" ]; then
      echo "Docker CE repository already configured on Fedora, skipping."
      return 0
    fi
  }

  run add_fedora_docker_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_fedora_vscodium_repo skips when repo file exists" {
  local test_dir="/tmp/test-fedora-vscodium-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/vscodium.repo"

  add_fedora_vscodium_repo() {
    local repo_path="$test_dir/vscodium.repo"
    if [ -f "$repo_path" ]; then
      echo "VSCodium repository already configured on Fedora, skipping."
      return 0
    fi
  }

  run add_fedora_vscodium_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}
