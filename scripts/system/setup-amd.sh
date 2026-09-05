#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
# NOTE: Hardware Testing Status — This script has been verified via automated unit and
# container integration tests. Bare-metal validation on physical AMD GPUs/APUs
# is pending and will be performed to verify real-world hardware edge cases.
source "scripts/_utils.sh" 2>/dev/null || true
source "scripts/system/arch/_repositories.sh" 2>/dev/null || true
source "scripts/system/fedora/_repositories.sh" 2>/dev/null || true
source "scripts/system/debian/_repositories.sh" 2>/dev/null || true

_detect_amd_gpu() {
  if [ "${AMD_FORCE_DETECT:-0}" = "1" ]; then
    return 0
  fi

  if ! command -v lspci >/dev/null 2>&1; then
    return 1
  fi

  lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' | grep -iq "1002" ||
    lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -iqE "amd|advanced micro devices|radeon"
}

_configure_repositories() {
  local pm="$1"

  case "$pm" in
  apt)
    add_debian_nonfree_repo
    add_debian_backports_repo
    ;;
  dnf)
    add_fedora_rpmfusion_repo
    ;;
  pacman)
    add_arch_multilib_repo
    ;;
  esac
}

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
  if ! rpm -q mesa-va-drivers-freeworld >/dev/null 2>&1; then
    sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld 2>/dev/null ||
      sudo dnf install -y --allowerasing mesa-va-drivers-freeworld 2>/dev/null || true
  fi

  if ! rpm -q mesa-vdpau-drivers-freeworld >/dev/null 2>&1; then
    sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 2>/dev/null ||
      sudo dnf install -y --allowerasing mesa-vdpau-drivers-freeworld 2>/dev/null || true
  fi
}

_install_fedora_32bit_packages() {
  if rpm -q glibc.i686 >/dev/null 2>&1 || [ "${FEDORA_ENABLE_MULTILIB:-0}" = "1" ]; then
    echo "Ensuring 32-bit freeworld drivers for gaming on Fedora..."
    sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 2>/dev/null || true
    sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 2>/dev/null || true
    sudo dnf install -y mesa-vulkan-drivers.i686 2>/dev/null || true
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
  codename="$(_get_debian_codename)"
  echo "Installing AMD GPU firmware and Mesa graphics stack from Debian backports (${codename}-backports)..."
  sudo apt install -y -t "${codename}-backports" \
    firmware-amd-graphics \
    libegl-mesa0 \
    libgbm1 \
    libgl1-mesa-dri \
    libglx-mesa0 \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers 2>/dev/null ||
    install_packages firmware-amd-graphics mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers
}

_install_debian_32bit_packages() {
  local codename
  codename="$(_get_debian_codename)"
  if command -v dpkg >/dev/null 2>&1 && dpkg --print-foreign-architectures 2>/dev/null | grep -q "i386"; then
    echo "Configuring 32-bit AMD graphics libraries on Debian..."
    sudo apt install -y -t "${codename}-backports" mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 2>/dev/null ||
      sudo apt install -y mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 2>/dev/null || true
  fi
}

_install_debian_amd_packages() {
  _install_debian_backports_stack
  echo "Installing diagnostic and utility tools on Debian..."
  install_packages libvulkan1 vainfo vulkan-tools
  _install_debian_32bit_packages
}

_install_amd_packages() {
  local pm="$1"

  if [ "${AMD_SKIP_PACKAGE_INSTALL:-0}" = "1" ]; then
    echo "AMD_SKIP_PACKAGE_INSTALL is active. Skipping package installation step."
    return 0
  fi

  case "$pm" in
  apt) _install_debian_amd_packages ;;
  dnf) _install_fedora_amd_packages ;;
  pacman) _install_arch_amd_packages ;;
  esac
}

_setup_amd() {
  local pm
  pm="$(_get_package_manager)" || {
    echo "Unsupported distribution" >&2
    return 1
  }

  case "$pm" in
  apt | dnf | pacman) ;;
  *)
    echo "Unsupported package manager: $pm" >&2
    return 1
    ;;
  esac

  if ! _detect_amd_gpu; then
    echo "No AMD GPU detected. Skipping AMD GPU setup."
    return 0
  fi

  echo "AMD GPU detected. Configuring drivers and codecs for '$pm'..."
  _configure_repositories "$pm"
  _install_amd_packages "$pm"
}

main() {
  echo "Setting up AMD graphics drivers and codecs..."
  _setup_amd
  echo "setup-amd complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
