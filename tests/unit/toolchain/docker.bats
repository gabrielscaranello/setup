#!/usr/bin/env bats

# Unit tests for setup-docker.sh logic and branches

@test "_install_docker_packages calls install_packages with unified docker package list" {
  source /setup/scripts/toolchain/setup-docker.sh
  install_packages() {
    echo "packages: $*"
    return 0
  }
  run _install_docker_packages "apt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "docker docker-compose docker-buildx containerd" ]]
}

@test "_install_docker_packages calls _add_docker_repo_fedora on Fedora" {
  source /setup/scripts/toolchain/setup-docker.sh
  _add_docker_repo_fedora() {
    echo "added fedora repo"
    return 0
  }
  install_packages() { return 0; }
  run _install_docker_packages "dnf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "added fedora repo" ]]
}

@test "_install_docker fails when package manager is unsupported" {
  source /setup/scripts/toolchain/setup-docker.sh
  _get_package_manager() { echo "unknown-pm"; }
  run _install_docker
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_add_docker_repo_fedora skips when repo file exists" {
  source /setup/scripts/toolchain/setup-docker.sh
  local test_repo="/tmp/test-docker-ce.repo"
  touch "$test_repo"
  _add_docker_repo_fedora() {
    if [ -f "$test_repo" ]; then
      echo "Docker CE repository already configured on Fedora, skipping."
      return 0
    fi
  }
  run _add_docker_repo_fedora
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "_enable_docker_service handles presence or absence of systemctl" {
  source /setup/scripts/toolchain/setup-docker.sh
  command() {
    if [ "${2:-}" = "systemctl" ]; then return 1; fi
    builtin command "$@"
  }
  run _enable_docker_service
  [ "$status" -eq 0 ]
  [[ "$output" =~ "systemctl not found" ]]
}

@test "_configure_docker_user_group adds user to docker group" {
  source /setup/scripts/toolchain/setup-docker.sh
  getent() { return 0; }
  sudo() { return 0; }
  USER="testuser" run _configure_docker_user_group
  [ "$status" -eq 0 ]
  [[ "$output" =~ User\ \'testuser\'\ added\ to\ docker\ group\. ]]
}
