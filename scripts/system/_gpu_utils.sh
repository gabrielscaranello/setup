#!/bin/bash

# Shared GPU setup utilities — sourced by setup-nvidia.sh and setup-amd.sh.
# Do NOT execute this file directly.

source "scripts/system/arch/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true

# Configures the third-party repositories required for GPU driver installation
# on the current distribution.
# Usage: configure_gpu_repositories <distro>
configure_gpu_repositories() {
  local distro="$1"

  case "$distro" in
    debian | apt)
      add_debian_nonfree_repo
      add_debian_backports_repo
      ;;
    fedora | dnf)
      add_fedora_rpmfusion_repo
      ;;
    arch | pacman)
      add_arch_multilib_repo
      ;;
  esac
}

_configure_repositories() {
  configure_gpu_repositories "$@"
}
