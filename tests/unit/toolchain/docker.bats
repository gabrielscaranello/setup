#!/usr/bin/env bats

# Unit tests for setup-docker.sh logic and branches

setup() {
  source /setup/scripts/toolchain/setup-docker.sh
}

@test "_install_docker_packages calls install_packages with unified docker package list" {
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_docker_packages "apt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: docker docker-compose docker-buildx containerd" ]]
}

@test "_install_docker_packages calls add_fedora_docker_repo on Fedora" {
  add_fedora_docker_repo() {
    echo "called add_fedora_docker_repo"
    return 0
  }
  install_packages() {
    return 0
  }
  run _install_docker_packages "dnf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_fedora_docker_repo" ]]
}

@test "_install_docker fails when package manager is unsupported" {
  _get_package_manager() {
    echo "unsupported_pm"
  }
  run _install_docker
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager: unsupported_pm" ]]
}

@test "_enable_docker_service handles presence or absence of systemctl" {
  command() {
    if [ "$2" = "systemctl" ]; then
      return 1
    fi
    builtin command "$@"
  }
  run _enable_docker_service
  [ "$status" -eq 0 ]
  [[ "$output" =~ "systemctl not found, skipping service enablement." ]]
}

@test "_configure_docker_user_group adds user to docker group" {
  export USER="testuser"
  getent() { return 1; }
  sudo() {
    echo "sudo $*"
    return 0
  }
  run _configure_docker_user_group
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Adding user 'testuser' to the docker group..." ]]
  [[ "$output" =~ "User 'testuser' added to docker group." ]]
}
