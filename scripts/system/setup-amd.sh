#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
# NOTE: Hardware Testing Status — This script has been verified via automated unit and
# container integration tests. Bare-metal validation on physical AMD GPUs/APUs
# is pending and will be performed to verify real-world hardware edge cases.
source "scripts/_utils.sh" 2> /dev/null || true
source "scripts/system/_gpu_utils.sh" 2> /dev/null || true

_install_arch_32bit_packages() {
  echo "Installing 32-bit Mesa and Vulkan packages on Arch Linux..."
  install_packages lib32-mesa lib32-vulkan-radeon
}

_install_arch_amd_packages() {
  echo "Installing Mesa, Vulkan RADV, and VA-API tools on Arch Linux..."
  install_packages mesa vulkan-radeon libva-utils vulkan-tools
  _install_arch_32bit_packages
}

_swap_fedora_freeworld_drivers() {
  echo "Swapping restricted Mesa VA-API/VDPAU drivers with RPM Fusion freeworld codecs..."
  if ! rpm -q mesa-va-drivers-freeworld > /dev/null 2>&1; then
    swap_packages mesa-va-drivers mesa-va-drivers-freeworld
  fi

  if ! rpm -q mesa-vdpau-drivers-freeworld > /dev/null 2>&1; then
    swap_packages mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
  fi
}

_install_fedora_32bit_packages() {
  if rpm -q glibc.i686 > /dev/null 2>&1 || [ "${FEDORA_ENABLE_MULTILIB:-0}" = "1" ]; then
    echo "Ensuring 32-bit freeworld drivers for gaming on Fedora..."
    swap_packages mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
    swap_packages mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
    install_packages mesa-vulkan-drivers.i686 2> /dev/null || true
  fi
}

_install_fedora_amd_packages() {
  echo "Installing Mesa Vulkan and acceleration tools on Fedora..."
  install_packages mesa-vulkan-drivers vulkan-loader libva-utils vulkan-tools
  _swap_fedora_freeworld_drivers
  _install_fedora_32bit_packages
}

_install_debian_backports_stack() {
  local codename
  codename="$(get_debian_codename)"

  if is_debian_testing "$codename"; then
    echo "Installing AMD GPU firmware and Mesa graphics stack on Debian testing ($codename)..."
    install_packages \
      firmware-amd-graphics \
      libegl-mesa0 \
      libgbm1 \
      libgl1-mesa-dri \
      libglx-mesa0 \
      mesa-va-drivers \
      mesa-vdpau-drivers \
      mesa-vulkan-drivers
    return 0
  fi

  echo "Installing AMD GPU firmware and Mesa graphics stack from Debian backports (${codename}-backports)..."
  install_packages_from_repo "${codename}-backports" \
    firmware-amd-graphics \
    libegl-mesa0 \
    libgbm1 \
    libgl1-mesa-dri \
    libglx-mesa0 \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers 2> /dev/null \
    || install_packages firmware-amd-graphics mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers
}

_install_debian_32bit_packages() {
  local codename
  codename="$(get_debian_codename)"
  if command -v dpkg > /dev/null 2>&1 && dpkg --print-foreign-architectures 2> /dev/null | grep -q "i386"; then
    echo "Configuring 32-bit AMD graphics libraries on Debian..."
    if is_debian_testing "$codename"; then
      install_packages mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 2> /dev/null || true
      return 0
    fi
    install_packages_from_repo "${codename}-backports" mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 2> /dev/null \
      || install_packages mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 2> /dev/null || true
  fi
}

_install_debian_amd_packages() {
  _install_debian_backports_stack
  echo "Installing diagnostic and utility tools on Debian..."
  install_packages libvulkan1 vainfo vulkan-tools
  _install_debian_32bit_packages
}

_install_opensuse_32bit_packages() {
  echo "Installing 32-bit AMD graphics libraries on openSUSE..."
  install_packages libvulkan_radeon-32bit 2> /dev/null || true
}

_install_opensuse_amd_packages() {
  echo "Installing AMD GPU firmware, Mesa, and Vulkan on openSUSE..."
  install_packages kernel-firmware-amdgpu libvulkan_radeon libva-utils vulkan-tools
  _install_opensuse_32bit_packages
}

_install_amd_packages() {
  local distro="$1"

  if [ "${AMD_SKIP_PACKAGE_INSTALL:-0}" = "1" ]; then
    echo "AMD_SKIP_PACKAGE_INSTALL is active. Skipping package installation step."
    return 0
  fi

  case "$distro" in
    debian) _install_debian_amd_packages ;;
    fedora) _install_fedora_amd_packages ;;
    arch) _install_arch_amd_packages ;;
    opensuse*) _install_opensuse_amd_packages ;;
  esac
}

_setup_amd() {
  local distro
  distro="$(require_supported_distro)" || return 1

  if ! has_amd_gpu; then
    echo "No AMD GPU detected. Skipping AMD GPU setup."
    return 0
  fi

  echo "AMD GPU detected. Configuring drivers and codecs for '$distro'..."
  configure_gpu_repositories "$distro"
  _install_amd_packages "$distro"
}

main() {
  echo "Setting up AMD graphics drivers and codecs..."
  _setup_amd
  echo "setup-amd complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
