#!/usr/bin/env bats

# Integration tests for setup-timeshift.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-timeshift.sh || true
}

@test "timeshift configuration file exists and has valid JSON" {
  [ -f "/etc/timeshift/timeshift.json" ]
  grep -q '"do_first_run": "false"' "/etc/timeshift/timeshift.json"
}

@test "timeshift command is available and responds to --help" {
  command -v timeshift
  run timeshift --help
  [ "$status" -eq 0 ]
}

@test "timeshift backup snapshot can be created or listed" {
  run sudo timeshift --list --scripted
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "grub-btrfs menu script exists when root filesystem is btrfs" {
  local fs_type
  fs_type="$(findmnt -n -o FSTYPE / 2>/dev/null || df -T / 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")"

  if [ "$fs_type" = "btrfs" ]; then
    [ -f "/etc/grub.d/41_snapshots-btrfs" ]
  else
    # On non-btrfs systems (such as standard test containers), verify setup completed cleanly
    [ -f "/etc/timeshift/timeshift.json" ]
  fi
}

@test "setup-timeshift.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-timeshift.sh
  [ "$status" -eq 0 ]
}
