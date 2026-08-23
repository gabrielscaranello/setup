#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2>/dev/null || source "$(dirname "$0")/_utils.sh"

_calculate_swap_size_gb() {
  local total_mem_kb mem_gb
  total_mem_kb="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)"
  if [ "$total_mem_kb" -le 0 ]; then
    echo "4"
    return 0
  fi

  # Calculate half of RAM in GB, with a minimum of 4GB
  mem_gb=$(( total_mem_kb / 1024 / 1024 / 2 ))
  if [ "$mem_gb" -lt 4 ]; then
    mem_gb=4
  fi

  echo "$mem_gb"
}

_detect_root_filesystem() {
  local fs_type
  fs_type="$(findmnt -n -o FSTYPE / 2>/dev/null || df -T / 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")"
  echo "$fs_type"
}

_configure_sysctl_vm_tuning() {
  local sysctl_file="/etc/sysctl.d/00-custom.conf"
  echo "Configuring swappiness and vfs_cache_pressure in $sysctl_file..."

  sudo mkdir -p /etc/sysctl.d
  sudo tee "$sysctl_file" >/dev/null <<EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF

  if command -v sysctl >/dev/null 2>&1; then
    sudo sysctl -p "$sysctl_file" 2>/dev/null || sudo sysctl --system 2>/dev/null || true
  fi
}

_install_zram_packages() {
  echo "Installing zram packages..."
  install_packages zram || true
}

_configure_zram_generator() {
  local zram_conf="/etc/systemd/zram-generator.conf"
  echo "Configuring zram-generator in $zram_conf..."

  sudo mkdir -p /etc/systemd
  sudo tee "$zram_conf" >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
    sudo systemctl start /dev/zram0 2>/dev/null || true
  fi
}

_configure_zram_tools() {
  local default_file="/etc/default/zramswap"
  echo "Configuring zram-tools in $default_file..."

  if [ -f "$default_file" ]; then
    sudo sed -i 's/^#\?ALGO=.*/ALGO=zstd/' "$default_file" 2>/dev/null || true
    sudo sed -i 's/^#\?PERCENT=.*/PERCENT=50/' "$default_file" 2>/dev/null || true
    sudo sed -i 's/^#\?PRIORITY=.*/PRIORITY=100/' "$default_file" 2>/dev/null || true
  else
    sudo mkdir -p /etc/default
    sudo tee "$default_file" >/dev/null <<'EOF'
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart zramswap.service 2>/dev/null || true
  fi
}

_configure_zram() {
  local pm
  pm="$(_get_package_manager)" || return 0

  _install_zram_packages

  case "$pm" in
  apt)
    _configure_zram_tools
    ;;
  dnf | pacman)
    _configure_zram_generator
    ;;
  esac
}

_is_swapfile_active() {
  local swap_file="$1"
  swapon --show=NAME 2>/dev/null | grep -qx "$swap_file"
}

_cleanup_old_swapfile() {
  local swap_file="$1"
  sudo swapoff "$swap_file" 2>/dev/null || true
  sudo rm -f "$swap_file"
}

_create_btrfs_swapfile() {
  local swap_file="$1"
  local size_gb="$2"

  echo "Creating Btrfs swapfile with btrfs filesystem mkswapfile..."
  if command -v btrfs >/dev/null 2>&1; then
    sudo btrfs filesystem mkswapfile --size "${size_gb}G" "$swap_file" && return 0
  fi

  # Fallback for Btrfs if mkswapfile is unavailable or failed
  sudo truncate -s 0 "$swap_file"
  sudo chattr +C "$swap_file" 2>/dev/null || true
  sudo btrfs property set "$swap_file" compression none 2>/dev/null || true
  sudo dd if=/dev/zero of="$swap_file" bs=1G count="$size_gb" status=progress 2>/dev/null || sudo fallocate -l "${size_gb}G" "$swap_file"
  sudo chmod 0600 "$swap_file"
  sudo mkswap "$swap_file"
}

_create_standard_swapfile() {
  local swap_file="$1"
  local size_gb="$2"

  echo "Creating standard swapfile using fallocate/dd..."
  if ! sudo fallocate -l "${size_gb}G" "$swap_file" 2>/dev/null; then
    sudo dd if=/dev/zero of="$swap_file" bs=1M count="$(( size_gb * 1024 ))" status=progress 2>/dev/null || sudo dd if=/dev/zero of="$swap_file" bs=1M count="$(( size_gb * 1024 ))"
  fi
  sudo chmod 0600 "$swap_file"
  sudo mkswap "$swap_file"
}

_enable_swapfile() {
  local swap_file="$1"
  sudo swapon "$swap_file" 2>/dev/null || true
}

_persist_swapfile_in_fstab() {
  local swap_file="$1"
  if [ -f /etc/fstab ] && ! grep -q "^$swap_file" /etc/fstab; then
    echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
  fi
}

_configure_swapfile() {
  local swap_file="/swapfile"
  local size_gb fs_type

  if _is_swapfile_active "$swap_file"; then
    echo "Swapfile $swap_file is already active, skipping creation."
    return 0
  fi

  size_gb="$(_calculate_swap_size_gb)"
  fs_type="$(_detect_root_filesystem)"

  echo "Configuring swapfile of ${size_gb}G on filesystem '${fs_type}'..."
  _cleanup_old_swapfile "$swap_file"

  if [ "$fs_type" = "btrfs" ]; then
    _create_btrfs_swapfile "$swap_file" "$size_gb"
  else
    _create_standard_swapfile "$swap_file" "$size_gb"
  fi

  _enable_swapfile "$swap_file"
  _persist_swapfile_in_fstab "$swap_file"

  echo "Swapfile $swap_file configured successfully."
}

_setup_swap() {
  _configure_sysctl_vm_tuning
  _configure_zram
  _configure_swapfile
}

main() {
  echo "Setting up swap, zram and memory tuning..."
  _setup_swap
  echo "setup-swap complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
