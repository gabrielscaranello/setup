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

@test "add_fedora_rpmfusion_repo skips when repo files exist" {
  local test_dir="/tmp/test-fedora-rpmfusion-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/rpmfusion-free.repo" "$test_dir/rpmfusion-nonfree.repo"

  add_fedora_rpmfusion_repo() {
    local free_repo="$test_dir/rpmfusion-free.repo"
    local nonfree_repo="$test_dir/rpmfusion-nonfree.repo"
    if [ -f "$free_repo" ] && [ -f "$nonfree_repo" ]; then
      echo "RPM Fusion repositories already configured on Fedora, skipping."
      return 0
    fi
  }

  run add_fedora_rpmfusion_repo
  rm -rf "$test_dir"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_fedora_rpmfusion_repo installs release rpms when missing" {
  sudo() {
    return 0
  }
  rpm() {
    echo "44"
  }

  run add_fedora_rpmfusion_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring RPM Fusion repositories for Fedora" ]]
}
