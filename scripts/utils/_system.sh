#!/bin/bash

# System and Hardware Detection Utilities
# Handles OS distribution identification, hardware discovery (GPU),
# root filesystem detection, and user shell profile resolution.

get_distro_id() {
  local os_release_file="${OS_RELEASE_PATH:-/etc/os-release}"
  if [ ! -f "$os_release_file" ] && [ -f /usr/lib/os-release ]; then
    os_release_file="/usr/lib/os-release"
  fi

  if [ -f "$os_release_file" ]; then
    local distro_id
    distro_id="$(grep '^ID=' "$os_release_file" 2> /dev/null | head -n 1 | cut -d= -f2 | tr -d '"'\'' ' | tr '[:upper:]' '[:lower:]' || true)"
    if [ -n "$distro_id" ]; then
      echo "$distro_id"
      return 0
    fi
  fi

  if command -v lsb_release > /dev/null 2>&1; then
    local lsb_id
    lsb_id="$(lsb_release -si 2> /dev/null | tr '[:upper:]' '[:lower:]' || true)"
    if [ -n "$lsb_id" ]; then
      echo "$lsb_id"
      return 0
    fi
  fi

  echo "unknown"
  return 1
}

is_distro() {
  local target="$1"
  local current
  current="$(get_distro_id 2> /dev/null || echo "unknown")"
  [ "$current" = "$target" ]
}

# Validates and returns the current distro if it is one of: debian, fedora, arch.
# Prints the distro ID to stdout on success; prints error and returns 1 on failure.
# Usage: distro="$(require_supported_distro)" || return 1
require_supported_distro() {
  local distro
  distro="$(get_distro_id)" || {
    echo "Unsupported distribution" >&2
    return 1
  }
  case "$distro" in
    debian | fedora | arch)
      echo "$distro"
      return 0
      ;;
    *)
      echo "Unsupported distribution: $distro" >&2
      return 1
      ;;
  esac
}

get_root_filesystem() {
  findmnt -n -o FSTYPE / 2> /dev/null || df -T / 2> /dev/null | awk 'NR==2 {print $2}' || echo "unknown"
}

get_gpu_vendor() {
  if [ -n "${GPU_VENDOR:-}" ]; then
    echo "$GPU_VENDOR"
    return 0
  fi

  if command -v has_nvidia_gpu > /dev/null 2>&1; then
    if has_nvidia_gpu; then
      echo "nvidia"
      return 0
    elif has_amd_gpu; then
      echo "amd"
      return 0
    elif has_intel_gpu; then
      echo "intel"
      return 0
    fi
  elif command -v lspci > /dev/null 2>&1; then
    local pci_display
    pci_display="$(lspci -nn 2> /dev/null | grep -iE 'vga|3d|display' || true)"
    if [ -n "$pci_display" ]; then
      if echo "$pci_display" | grep -iq "10de" || echo "$pci_display" | grep -iq "nvidia"; then
        echo "nvidia"
        return 0
      elif echo "$pci_display" | grep -iq "1002" || echo "$pci_display" | grep -iqE "amd|advanced micro devices|radeon"; then
        echo "amd"
        return 0
      elif echo "$pci_display" | grep -iq "8086" || echo "$pci_display" | grep -iq "intel"; then
        echo "intel"
        return 0
      fi
    fi
  fi

  echo "unknown"
}

get_shell_profile() {
  case "${SHELL##*/}" in
    zsh) echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

enable_cron_service() {
  if ! command -v systemctl > /dev/null 2>&1; then
    return 0
  fi

  echo "Enabling cron scheduler service..."
  if is_distro debian; then
    sudo systemctl enable --now cron.service 2> /dev/null || sudo systemctl enable cron.service 2> /dev/null || true
  elif is_distro fedora; then
    sudo systemctl enable --now crond.service 2> /dev/null || sudo systemctl enable crond.service 2> /dev/null || true
  else
    sudo systemctl enable --now cronie.service 2> /dev/null || sudo systemctl enable cronie.service 2> /dev/null || true
  fi
}
