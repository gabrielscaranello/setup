#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

_install_docker_packages() {
  local distro="${1:-}"
  if [ "$distro" = "fedora" ]; then
    add_fedora_docker_repo
  fi

  echo "Installing Docker packages..."
  install_packages docker docker-compose docker-buildx containerd
}

_enable_docker_service() {
  echo "Enabling and starting Docker service via systemd..."
  if command -v systemctl > /dev/null 2>&1; then
    sudo systemctl enable docker.service 2> /dev/null || true
    sudo systemctl start docker.service 2> /dev/null || true
  else
    echo "systemctl not found, skipping service enablement."
  fi
}

_configure_docker_user_group() {
  local target_user="${SUDO_USER:-${USER:-$(id -un)}}"
  echo "Adding user '$target_user' to the docker group..."

  if ! getent group docker > /dev/null 2>&1; then
    sudo groupadd -f docker 2> /dev/null || true
  fi

  if [ -n "$target_user" ]; then
    sudo usermod -aG docker "$target_user" 2> /dev/null || true
    echo "User '$target_user' added to docker group."
  fi
}

_install_docker() {
  local distro
  distro="$(require_supported_distro)" || return 1

  _install_docker_packages "$distro" || return 1
  _enable_docker_service
  _configure_docker_user_group
}

main() {
  echo "Setting up Docker..."
  _install_docker
  echo "setup-docker complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
