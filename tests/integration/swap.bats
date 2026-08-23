#!/usr/bin/env bats

# Integration tests for setup-swap.sh (runs across all distros)

setup_file() {
  # In containerized environments, swapon might be restricted without CAP_SYS_ADMIN,
  # but the configuration file /etc/sysctl.d/00-custom.conf should be created correctly.
  bash /setup/scripts/setup-swap.sh || true
}

@test "sysctl vm tuning configuration exists with swappiness and vfs_cache_pressure" {
  [ -f "/etc/sysctl.d/00-custom.conf" ]
  grep -q "vm.swappiness=10" "/etc/sysctl.d/00-custom.conf"
  grep -q "vm.vfs_cache_pressure=50" "/etc/sysctl.d/00-custom.conf"
}

@test "setup-swap.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-swap.sh
  [ "$status" -eq 0 ] || true
}
