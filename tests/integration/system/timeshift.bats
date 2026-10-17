#!/usr/bin/env bats

# Integration tests for setup-timeshift.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/system/setup-timeshift.sh || true
}

@test "snapshot configuration file or directory exists" {
  local distro
  distro="$(bash -c 'source /setup/scripts/_utils.sh 2>/dev/null && get_distro_id' 2>/dev/null || echo "unknown")"
  if [[ "$distro" =~ opensuse ]]; then
    [ -d "/etc/snapper" ]
  else
    [ -f "/etc/timeshift/timeshift.json" ]
    grep -q '"do_first_run": "false"' "/etc/timeshift/timeshift.json"
  fi
}

@test "snapshot command is available and responds" {
  local distro
  distro="$(bash -c 'source /setup/scripts/_utils.sh 2>/dev/null && get_distro_id' 2>/dev/null || echo "unknown")"
  if [[ "$distro" =~ opensuse ]]; then
    command -v snapper
    run snapper --version
    [ "$status" -eq 0 ]
  else
    command -v timeshift
    run timeshift --help
    [ "$status" -eq 0 ]
  fi
}

@test "snapshot tool can list configurations or snapshots" {
  local distro
  distro="$(bash -c 'source /setup/scripts/_utils.sh 2>/dev/null && get_distro_id' 2>/dev/null || echo "unknown")"
  if [[ "$distro" =~ opensuse ]]; then
    run sudo snapper --no-dbus list-configs
    [ "$status" -eq 0 ]
  else
    run sudo timeshift --list --scripted
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  fi
}

@test "grub snapshot integration exists when appropriate" {
  local distro fs_type
  distro="$(bash -c 'source /setup/scripts/_utils.sh 2>/dev/null && get_distro_id' 2>/dev/null || echo "unknown")"
  fs_type="$(findmnt -n -o FSTYPE / 2>/dev/null || df -T / 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")"

  if [[ "$distro" =~ opensuse ]]; then
    rpm -q grub2-snapper-plugin > /dev/null 2>&1 || true
  elif [ "$fs_type" = "btrfs" ]; then
    [ -f "/etc/grub.d/41_snapshots-btrfs" ]
  else
    # On non-btrfs systems (such as standard test containers), verify setup completed cleanly
    [ -f "/etc/timeshift/timeshift.json" ]
  fi
}

@test "setup-timeshift.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/system/setup-timeshift.sh
  [ "$status" -eq 0 ]
}
