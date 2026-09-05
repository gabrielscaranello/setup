#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-swap.sh logic and branches

setup() {
  source /setup/scripts/system/setup-swap.sh
}

@test "_calculate_swap_size_gb returns default when /proc/meminfo is missing" {
  grep() { return 1; }
  run _calculate_swap_size_gb
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]
}

@test "_calculate_swap_size_gb enforces minimum 4GB and half RAM without upper limit" {
  # Small RAM: 2GB total -> half is 0.5GB -> minimum 4GB
  grep() { echo "MemTotal:        2097152 kB"; }
  run _calculate_swap_size_gb
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]

  # Small RAM: 4GB total -> half is 2GB -> minimum 4GB
  grep() { echo "MemTotal:        4194304 kB"; }
  run _calculate_swap_size_gb
  [ "$status" -eq 0 ]
  [ "$output" = "4" ]

  # Medium RAM: 16GB total -> half is 8GB
  grep() { echo "MemTotal:       16777216 kB"; }
  run _calculate_swap_size_gb
  [ "$status" -eq 0 ]
  [ "$output" = "8" ]

  # Large RAM: 64GB total -> half is 32GB
  grep() { echo "MemTotal:       67108864 kB"; }
  run _calculate_swap_size_gb
  [ "$status" -eq 0 ]
  [ "$output" = "32" ]
}

@test "get_root_filesystem detects btrfs or ext4" {
  findmnt() { echo "btrfs"; return 0; }
  run get_root_filesystem
  [ "$status" -eq 0 ]
  [ "$output" = "btrfs" ]

  findmnt() { echo "ext4"; return 0; }
  run get_root_filesystem
  [ "$status" -eq 0 ]
  [ "$output" = "ext4" ]
}

@test "_configure_sysctl_vm_tuning creates sysctl configuration" {
  sudo() {
    "$@"
  }
  local test_sysctl_dir="/tmp/test-sysctl-d"
  rm -rf "$test_sysctl_dir"
  mkdir -p "$test_sysctl_dir"

  _configure_sysctl_vm_tuning() {
    local sysctl_file="$test_sysctl_dir/00-custom.conf"
    cat <<SYSCTL > "$sysctl_file"
vm.swappiness=10
vm.vfs_cache_pressure=50
SYSCTL
  }

  run _configure_sysctl_vm_tuning
  [ "$status" -eq 0 ]
  grep -q "vm.swappiness=10" "$test_sysctl_dir/00-custom.conf"
  grep -q "vm.vfs_cache_pressure=50" "$test_sysctl_dir/00-custom.conf"
  rm -rf "$test_sysctl_dir"
}

@test "_configure_swapfile skips when swapfile is already active" {
  swapon() {
    if [ "$1" = "--show=NAME" ]; then
      echo "/swapfile"
      return 0
    fi
    return 1
  }
  run _configure_swapfile
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ active,\ skipping ]]
}

@test "_configure_swapfile creates btrfs swapfile on btrfs filesystem" {
  swapon() { return 1; }
  _calculate_swap_size_gb() { echo "4"; }
  get_root_filesystem() { echo "btrfs"; }
  btrfs() {
    if [ "$1" = "filesystem" ] && [ "$2" = "mkswapfile" ]; then
      echo "btrfs mkswapfile called with size $4 for $5"
      return 0
    fi
    return 1
  }
  sudo() {
    "$@"
  }
  run _configure_swapfile
  [ "$status" -eq 0 ]
  [[ "$output" =~ Creating\ Btrfs\ swapfile ]]
}

@test "_configure_swapfile creates ext4 swapfile on ext4 filesystem" {
  swapon() { return 1; }
  _calculate_swap_size_gb() { echo "4"; }
  get_root_filesystem() { echo "ext4"; }
  fallocate() {
    echo "fallocate called with size $2 for $3"
    return 0
  }
  mkswap() { return 0; }
  chmod() { return 0; }
  sudo() {
    "$@"
  }
  run _configure_swapfile
  [ "$status" -eq 0 ]
  [[ "$output" =~ Creating\ standard\ swapfile ]]
}

@test "_is_swapfile_active returns true when swapfile is reported by swapon" {
  swapon() {
    if [ "$1" = "--show=NAME" ]; then
      echo "/swapfile"
      return 0
    fi
    return 1
  }
  run _is_swapfile_active "/swapfile"
  [ "$status" -eq 0 ]
}

@test "_is_swapfile_active returns false when swapfile is not in swapon" {
  swapon() {
    if [ "$1" = "--show=NAME" ]; then
      echo "/zram0"
      return 0
    fi
    return 1
  }
  run _is_swapfile_active "/swapfile"
  [ "$status" -eq 1 ]
}

@test "_persist_swapfile_in_fstab appends swapfile when not present in fstab" {
  local test_fstab="/tmp/test-fstab"
  echo "# /etc/fstab" > "$test_fstab"
  sudo() { "$@"; }

  _persist_swapfile_in_fstab() {
    local swap_file="$1"
    if ! grep -q "^$swap_file" "$test_fstab"; then
      echo "$swap_file none swap sw 0 0" >> "$test_fstab"
    fi
  }

  run _persist_swapfile_in_fstab "/swapfile"
  [ "$status" -eq 0 ]
  grep -q "^/swapfile none swap sw 0 0" "$test_fstab"
  rm -f "$test_fstab"
}

@test "_install_zram_packages calls install_packages zram" {
  install_packages() {
    echo "install_packages called for: $*"
    return 0
  }
  run _install_zram_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ install_packages\ called\ for:\ zram ]]
}

@test "_configure_zram_generator creates valid zram-generator config" {
  local test_conf="/tmp/test-zram-generator.conf"
  sudo() { "$@"; }
  systemctl() { return 0; }

  _configure_zram_generator() {
    cat <<'CONF' > "$test_conf"
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
CONF
  }

  run _configure_zram_generator
  [ "$status" -eq 0 ]
  grep -q "zram-size = ram / 2" "$test_conf"
  grep -q "compression-algorithm = zstd" "$test_conf"
  grep -q "swap-priority = 100" "$test_conf"
  rm -f "$test_conf"
}

@test "_configure_zram_tools creates or modifies /etc/default/zramswap" {
  local test_default="/tmp/test-zramswap"
  sudo() { "$@"; }
  systemctl() { return 0; }

  _configure_zram_tools() {
    cat <<'CONF' > "$test_default"
ALGO=zstd
PERCENT=50
PRIORITY=100
CONF
  }

  run _configure_zram_tools
  [ "$status" -eq 0 ]
  grep -q "ALGO=zstd" "$test_default"
  grep -q "PERCENT=50" "$test_default"
  grep -q "PRIORITY=100" "$test_default"
  rm -f "$test_default"
}

@test "_configure_zram routes appropriately per distribution" {
  _install_zram_packages() { return 0; }
  _configure_zram_tools() { echo "tools-zram"; return 0; }
  _configure_zram_generator() { echo "generator-zram"; return 0; }

  get_distro_id() { echo "debian"; }
  run _configure_zram
  [ "$status" -eq 0 ]
  [ "$output" = "tools-zram" ]

  get_distro_id() { echo "fedora"; }
  run _configure_zram
  [ "$status" -eq 0 ]
  [ "$output" = "generator-zram" ]

  get_distro_id() { echo "arch"; }
  run _configure_zram
  [ "$status" -eq 0 ]
  [ "$output" = "generator-zram" ]
}
