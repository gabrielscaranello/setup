#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/opensuse/_repositories.sh" 2> /dev/null || true

_install_backports_kernel_leap() {
  add_opensuse_kernel_backports_repo

  echo "Installing latest Linux kernel and headers from Kernel_stable_Backport..."
  # Justification: Specific repository selection (--from) to install the newer backport kernel
  sudo zypper --non-interactive install --from Kernel_stable_Backport kernel-default kernel-default-devel 2> /dev/null \
    || install_packages kernel-default kernel-default-devel
}

_setup_opensuse_kernel() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$distro" in
    opensuse-tumbleweed)
      echo "openSUSE Tumbleweed is a rolling release and already runs the latest kernel. Skipping kernel backports."
      return 0
      ;;
    opensuse | opensuse-leap)
      _install_backports_kernel_leap
      ;;
    *)
      echo "openSUSE kernel backports is only applicable to openSUSE Leap. Skipping on '$distro'."
      return 0
      ;;
  esac
}

main() {
  echo "Setting up openSUSE latest kernel and headers..."
  _setup_opensuse_kernel
  echo "setup-kernel complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
