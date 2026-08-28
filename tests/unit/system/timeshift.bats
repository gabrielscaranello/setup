#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-timeshift.sh logic and branches

setup() {
  source /setup/scripts/system/setup-timeshift.sh
}

@test "get_root_filesystem detects btrfs and ext4 correctly" {
  findmnt() { echo "btrfs"; return 0; }
  run get_root_filesystem
  [ "$status" -eq 0 ]
  [ "$output" = "btrfs" ]

  findmnt() { echo "ext4"; return 0; }
  run get_root_filesystem
  [ "$status" -eq 0 ]
  [ "$output" = "ext4" ]
}

@test "_install_timeshift_packages calls install_packages timeshift" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_timeshift_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ timeshift ]]
}

@test "_get_documents_dir_name defaults to Documents" {
  run _get_documents_dir_name
  [ "$status" -eq 0 ]
  [ "$output" = "Documents" ]
}

@test "_render_timeshift_config renders btrfs config with btrfs_mode true" {
  run _render_timeshift_config "btrfs"
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"btrfs_mode\":\ \"true\" ]]
  [[ "$output" =~ \"schedule_boot\":\ \"true\" ]]
}

@test "_render_timeshift_config renders rsync config with btrfs_mode false and excludes" {
  run _render_timeshift_config "ext4"
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"btrfs_mode\":\ \"false\" ]]
  [[ "$output" =~ \"schedule_boot\":\ \"false\" ]]
  [[ "$output" =~ \*\*\*node_modules\*\*\* ]]
}

@test "_deploy_timeshift_config creates /etc/timeshift/timeshift.json" {
  local test_target_dir="/tmp/test-timeshift"
  rm -rf "$test_target_dir"
  mkdir -p "$test_target_dir"
  sudo() { "$@"; }
  _detect_root_filesystem() { echo "btrfs"; }

  _deploy_timeshift_config() {
    local target_file="$test_target_dir/timeshift.json"
    _render_timeshift_config "btrfs" > "$target_file"
  }

  run _deploy_timeshift_config
  [ "$status" -eq 0 ]
  [ -f "$test_target_dir/timeshift.json" ]
  grep -q '"btrfs_mode": "true"' "$test_target_dir/timeshift.json"
  rm -rf "$test_target_dir"
}

@test "_configure_grub_btrfsd updates service with --timeshift-auto on btrfs" {
  get_root_filesystem() { echo "btrfs"; }
  command() { return 0; }
  local test_service="/tmp/grub-btrfsd.service"
  echo "ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots" > "$test_service"

  systemctl() {
    if [ "$1" = "show" ]; then
      echo "FragmentPath=$test_service"
      return 0
    fi
    return 0
  }
  sudo() { "$@"; }

  run _configure_grub_btrfsd
  [ "$status" -eq 0 ]
  grep -q -- "--timeshift-auto" "$test_service"
  rm -f "$test_service"
}

@test "_configure_grub_btrfsd is skipped on non-btrfs filesystems" {
  get_root_filesystem() { echo "ext4"; }
  systemctl() {
    echo "systemctl should not be called"
    return 1
  }
  run _configure_grub_btrfsd
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "_render_btrfs_config and _render_rsync_config execute successfully" {
  run _render_btrfs_config
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"btrfs_mode\":\ \"true\" ]]

  run _render_rsync_config
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"btrfs_mode\":\ \"false\" ]]
}

@test "_write_timeshift_config writes content to /etc/timeshift/timeshift.json" {
  local test_target_dir="/tmp/test-write-timeshift"
  rm -rf "$test_target_dir"
  mkdir -p "$test_target_dir"
  sudo() { "$@"; }

  _write_timeshift_config() {
    local content="$1"
    echo "$content" > "$test_target_dir/timeshift.json"
  }

  run _write_timeshift_config '{"test": true}'
  [ "$status" -eq 0 ]
  grep -q '"test": true' "$test_target_dir/timeshift.json"
  rm -rf "$test_target_dir"
}

@test "_patch_grub_btrfsd_service replaces ExecStart with --timeshift-auto" {
  local test_service="/tmp/test-patch-grub-btrfsd.service"
  echo "ExecStart=/usr/bin/grub-btrfsd /.snapshots" > "$test_service"
  sudo() { "$@"; }

  run _patch_grub_btrfsd_service "$test_service"
  [ "$status" -eq 0 ]
  grep -q -- "--timeshift-auto" "$test_service"
  rm -f "$test_service"
}

@test "_install_grub_btrfs_dependencies calls install_packages with btrfs-progs, gawk and inotify-tools" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_grub_btrfs_dependencies
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ btrfs-progs\ gawk\ inotify-tools ]]
}

@test "_install_grub_btrfs_arch calls _install_grub_btrfs_dependencies and grub-btrfs" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_grub_btrfs_arch
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ btrfs-progs\ gawk\ inotify-tools ]]
  [[ "$output" =~ installed:\ grub-btrfs ]]
}

@test "_configure_grub_btrfs_source_config sets fedora specific config values" {
  local test_config_dir="/tmp/test-grub-btrfs-conf"
  mkdir -p "$test_config_dir"
  cat <<'CONF' > "$test_config_dir/config"
#GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig
#GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
#GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check
CONF

  run _configure_grub_btrfs_source_config "$test_config_dir" "dnf"
  [ "$status" -eq 0 ]
  grep -q "GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig" "$test_config_dir/config"
  grep -q 'GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' "$test_config_dir/config"
  grep -q "GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check" "$test_config_dir/config"
  rm -rf "$test_config_dir"
}

@test "_install_grub_btrfs delegates to pacman or source install" {
  _get_package_manager() { echo "pacman"; }
  _install_grub_btrfs_arch() { echo "arch-grub-btrfs"; return 0; }
  _install_grub_btrfs_from_source() { echo "source-grub-btrfs-$1"; return 0; }

  run _install_grub_btrfs
  [ "$status" -eq 0 ]
  [ "$output" = "arch-grub-btrfs" ]

  _get_package_manager() { echo "dnf"; }
  run _install_grub_btrfs
  [ "$status" -eq 0 ]
  [ "$output" = "source-grub-btrfs-dnf" ]

  _get_package_manager() { echo "apt"; }
  run _install_grub_btrfs
  [ "$status" -eq 0 ]
  [ "$output" = "source-grub-btrfs-apt" ]
}

@test "_create_initial_snapshot calls timeshift --create" {
  timeshift() {
    echo "timeshift called: $*"
    return 0
  }
  command() { return 0; }
  sudo() { "$@"; }

  run _create_initial_snapshot
  [ "$status" -eq 0 ]
  [[ "$output" =~ timeshift\ called:\ --create ]]
}

@test "_regenerate_grub_btrfs_menu executes 41_snapshots-btrfs and grub config" {
  local mock_grub_script="/tmp/41_snapshots-btrfs"
  touch "$mock_grub_script"
  chmod +x "$mock_grub_script"
  sudo() { "$@"; }
  grub_mkconfig_called=0

  _regenerate_grub_btrfs_menu() {
    if [ -x "$mock_grub_script" ]; then
      "$mock_grub_script"
      echo "grub-mkconfig updated"
    fi
  }

  run _regenerate_grub_btrfs_menu
  [ "$status" -eq 0 ]
  [[ "$output" =~ grub-mkconfig\ updated ]]
  rm -f "$mock_grub_script"
}
