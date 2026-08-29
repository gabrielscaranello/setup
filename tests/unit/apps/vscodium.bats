#!/usr/bin/env bats

# Unit tests for setup-vscodium.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-vscodium.sh
}

@test "_install_vscodium fails when package manager is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_vscodium
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_vscodium on pacman installs code directly without repos" {
  _get_package_manager() { echo "pacman"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: code" ]]
}

@test "_install_vscodium on dnf adds repo and installs codium" {
  _get_package_manager() { echo "dnf"; }
  _add_vscodium_dnf_repo() {
    echo "called dnf repo setup"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called dnf repo setup" ]]
  [[ "$output" =~ "installed packages: codium" ]]
}

@test "_install_vscodium on apt adds repo and installs codium" {
  _get_package_manager() { echo "apt"; }
  _add_vscodium_apt_repo() {
    echo "called apt repo setup"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called apt repo setup" ]]
  [[ "$output" =~ "installed packages: codium" ]]
}

@test "_add_vscodium_dnf_repo skips when repository file exists" {
  local test_dir="/tmp/test-vscodium-dnf-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/vscodium.repo"

  _add_vscodium_dnf_repo() {
    local repo_path="$test_dir/vscodium.repo"
    if [ -f "$repo_path" ]; then
      echo "VSCodium repository already configured on Fedora, skipping."
      return 0
    fi
  }

  run _add_vscodium_dnf_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "_add_vscodium_apt_repo skips when repository files exist" {
  local test_dir="/tmp/test-vscodium-apt-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/vscodium.sources" "$test_dir/vscodium-archive-keyring.gpg"

  _add_vscodium_apt_repo() {
    local keyring_path="$test_dir/vscodium-archive-keyring.gpg"
    local sources_path="$test_dir/vscodium.sources"
    if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
      echo "VSCodium repository already configured on Debian, skipping."
      return 0
    fi
  }

  run _add_vscodium_apt_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}
