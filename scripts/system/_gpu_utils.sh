#!/bin/bash

# Shared GPU setup utilities — sourced by setup-nvidia.sh and setup-amd.sh.
# Do NOT execute this file directly.

source "scripts/system/arch/_repositories.sh" 2> /dev/null || true
source "scripts/system/fedora/_repositories.sh" 2> /dev/null || true
source "scripts/system/debian/_repositories.sh" 2> /dev/null || true
source "scripts/system/opensuse/_repositories.sh" 2> /dev/null || true

_list_pci_display_devices() {
  command -v lspci > /dev/null 2>&1 || return 1
  lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true
}

has_nvidia_gpu() {
  if [ "${NVIDIA_FORCE_DETECT:-0}" = "1" ] || [ "${GPU_VENDOR:-}" = "nvidia" ]; then
    return 0
  fi

  local pci_display
  pci_display="$(_list_pci_display_devices)" || return 1
  [ -n "$pci_display" ] && echo "$pci_display" | grep -iqE '10de|nvidia'
}

has_amd_gpu() {
  if [ "${AMD_FORCE_DETECT:-0}" = "1" ] || [ "${GPU_VENDOR:-}" = "amd" ]; then
    return 0
  fi

  local pci_display
  pci_display="$(_list_pci_display_devices)" || return 1
  [ -n "$pci_display" ] && echo "$pci_display" | grep -iqE '1002|amd|advanced micro devices|radeon'
}

has_intel_gpu() {
  if [ "${GPU_VENDOR:-}" = "intel" ]; then
    return 0
  fi

  local pci_display
  pci_display="$(_list_pci_display_devices)" || return 1
  [ -n "$pci_display" ] && echo "$pci_display" | grep -iqE '8086|intel'
}

has_hybrid_gpu() {
  if [ "${NVIDIA_FORCE_HYBRID:-0}" = "1" ]; then
    return 0
  fi

  local pci_display other_gpus
  pci_display="$(_list_pci_display_devices)" || return 1
  other_gpus="$(echo "$pci_display" | grep -iv "10de" | grep -iE 'intel|amd|advanced micro devices' || true)"
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
    opensuse* | zypper)
      add_opensuse_nonfree_repo
      add_opensuse_packman_repo
      add_opensuse_nvidia_repo
      ;;
  esac
}
