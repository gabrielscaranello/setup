#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true

_install_backports_kernel_apt() {
  local codename
  codename="$(get_debian_codename)"

  add_debian_backports_repo

  echo "Installing latest Linux kernel and headers from ${codename}-backports..."
  sudo apt install -y -t "${codename}-backports" linux-image-amd64 linux-headers-amd64
}

_setup_debian_kernel() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  if [ "$distro" != "debian" ]; then
    echo "Debian backports kernel is only applicable to Debian. Skipping on '$distro'."
    return 0
  fi

  _install_backports_kernel_apt
}

main() {
  echo "Setting up Debian backports kernel and headers..."
  _setup_debian_kernel
  echo "setup-kernel complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
