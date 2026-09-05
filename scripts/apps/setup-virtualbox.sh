#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true

_configure_virtualbox_user_group() {
  local target_user="${SUDO_USER:-${USER:-$(id -un)}}"
  echo "Configuring vboxusers group for user '$target_user'..."

  if ! getent group vboxusers > /dev/null 2>&1; then
    sudo groupadd -f vboxusers 2> /dev/null || true
  fi

  if [ -n "$target_user" ]; then
    sudo usermod -aG vboxusers "$target_user" 2> /dev/null || true
    echo "User '$target_user' added to vboxusers group."
  fi
}

_configure_virtualbox_repositories() {
  local distro="$1"
  if [ "$distro" = "debian" ]; then
    add_debian_virtualbox_repo
  elif [ "$distro" = "fedora" ]; then
    add_fedora_rpmfusion_repo
  fi
}

_install_virtualbox_packages() {
  local distro="${1:-}"
  if [ -n "$distro" ]; then
    _configure_virtualbox_repositories "$distro"
  fi

  echo "Installing VirtualBox packages..."
  install_packages virtualbox virtualbox-host-modules
}

_install_virtualbox() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    debian | fedora | arch) ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac

  _install_virtualbox_packages "$distro" || return 1
  _configure_virtualbox_user_group
}

main() {
  echo "Setting up VirtualBox..."
  _install_virtualbox
  echo "setup-virtualbox complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
