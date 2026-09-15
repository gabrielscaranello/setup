#!/bin/bash

# Shared GPU setup utilities — sourced by setup-nvidia.sh and setup-amd.sh.
# Do NOT execute this file directly.

source "scripts/system/arch/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true

# Configures the third-party repositories required for GPU driver installation
# on the current distribution.
# Usage: configure_gpu_repositories <distro>
has_nvidia_gpu() {
  if [ "${NVIDIA_FORCE_DETECT:-0}" = "1" ] || [ "${GPU_VENDOR:-}" = "nvidia" ]; then
    return 0
  fi

  if ! command -v lspci > /dev/null 2>&1; then
    return 1
  fi

  local pci_display
  pci_display="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true)"
  [ -n "$pci_display" ] && (echo "$pci_display" | grep -iq "10de" || echo "$pci_display" | grep -iq "nvidia")
}

has_amd_gpu() {
  if [ "${AMD_FORCE_DETECT:-0}" = "1" ] || [ "${GPU_VENDOR:-}" = "amd" ]; then
    return 0
  fi

  if ! command -v lspci > /dev/null 2>&1; then
    return 1
  fi

  local pci_display
  pci_display="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true)"
  [ -n "$pci_display" ] && (echo "$pci_display" | grep -iq "1002" || echo "$pci_display" | grep -iqE "amd|advanced micro devices|radeon")
}

has_intel_gpu() {
  if [ "${GPU_VENDOR:-}" = "intel" ]; then
    return 0
  fi

  if ! command -v lspci > /dev/null 2>&1; then
    return 1
  fi

  local pci_display
  pci_display="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true)"
  [ -n "$pci_display" ] && (echo "$pci_display" | grep -iq "8086" || echo "$pci_display" | grep -iq "intel")
}

has_hybrid_gpu() {
  if [ "${NVIDIA_FORCE_HYBRID:-0}" = "1" ]; then
    return 0
  fi

  if ! command -v lspci > /dev/null 2>&1; then
    return 1
  fi

  local other_gpus
  other_gpus="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' | grep -iv "10de" | grep -iE 'intel|amd|advanced micro devices' || true)"
  [ -n "$other_gpus" ]
}

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
