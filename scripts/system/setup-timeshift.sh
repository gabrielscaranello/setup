#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and domain submodules
source "scripts/_utils.sh" 2> /dev/null || true
# shellcheck source=scripts/system/_grub_btrfs.sh
source "$(dirname "${BASH_SOURCE[0]}")/_grub_btrfs.sh" 2> /dev/null || source "scripts/system/_grub_btrfs.sh"
# shellcheck source=scripts/system/opensuse/_snapper.sh
source "$(dirname "${BASH_SOURCE[0]}")/opensuse/_snapper.sh" 2> /dev/null || source "scripts/system/opensuse/_snapper.sh"

_install_timeshift_packages() {
  echo "Installing Timeshift and UI dependencies..."
  install_packages timeshift xhost || true
}

_get_config_dir() {
  echo "$(get_repo_root)/config"
}

_get_documents_dir_name() {
  local users_dir="$HOME/.config/user-dirs.dirs"
  local documents_dir="Documents"

  if [ -f "$users_dir" ]; then
    documents_dir="$(grep 'XDG_DOCUMENTS_DIR' "$users_dir" 2> /dev/null | awk -F'/' '{print $NF}' | cut -d'"' -f1 || echo "Documents")"
    if [ -z "$documents_dir" ]; then
      documents_dir="Documents"
    fi
  fi

  echo "$documents_dir"
}

_render_btrfs_config() {
  local config_dir
  config_dir="$(_get_config_dir)"
  cat "$config_dir/timeshift-btrfs.json"
}

_render_rsync_config() {
  local config_dir documents_dir
  config_dir="$(_get_config_dir)"
  documents_dir="$(_get_documents_dir_name)"
  sed "s,:home:,$HOME,g" "$config_dir/timeshift-rsync.json" | sed "s,:documents_dir:,$documents_dir,g"
}

_render_timeshift_config() {
  local fs_type="$1"
  if [ "$fs_type" = "btrfs" ]; then
    _render_btrfs_config
  else
    _render_rsync_config
  fi
}

_preserve_backup_device_uuid() {
  local target_file="$1"
  local content="$2"

  if [ -f "$target_file" ] && command -v python3 > /dev/null 2>&1; then
    local preserved
    preserved="$(python3 -c '
import json, sys
target_path, new_content = sys.argv[1], sys.argv[2]
try:
    with open(target_path) as f:
        existing = json.load(f)
    dev_uuid = existing.get("backup_device_uuid", "")
    parent_uuid = existing.get("parent_device_uuid", "")
    if dev_uuid:
        new_data = json.loads(new_content)
        result = {"backup_device_uuid": dev_uuid, "parent_device_uuid": parent_uuid}
        result.update(new_data)
        print(json.dumps(result, indent=2))
        sys.exit(0)
except Exception:
    pass
print(new_content)
' "$target_file" "$content" 2> /dev/null || true)"
    if [ -n "$preserved" ]; then
      echo "$preserved"
      return 0
    fi
  fi

  echo "$content"
}

_write_timeshift_config() {
  local content="$1"
  local target_dir="/etc/timeshift"
  local target_file="$target_dir/timeshift.json"

  content="$(_preserve_backup_device_uuid "$target_file" "$content")"

  sudo mkdir -p "$target_dir"
  echo "$content" | sudo tee "$target_file" > /dev/null
}

_deploy_timeshift_config() {
  local fs_type config_content
  fs_type="$(get_root_filesystem)"

  echo "Configuring Timeshift (mode: $([ "$fs_type" = "btrfs" ] && echo "BTRFS" || echo "RSYNC"))..."

  config_content="$(_render_timeshift_config "$fs_type")"
  _write_timeshift_config "$config_content"

  echo "Timeshift configuration deployed to /etc/timeshift/timeshift.json."
}

_create_initial_snapshot() {
  if ! command -v timeshift > /dev/null 2>&1; then
    return 0
  fi

  echo "Creating initial baseline Timeshift snapshot..."
  sudo timeshift --create --comments "Initial setup snapshot" --tags D --scripted 2> /dev/null || true
}

_enable_cron_service() {
  enable_cron_service
}

_setup_timeshift() {
  if is_distro "opensuse"; then
    _setup_opensuse_snapper
    return 0
  fi

  _install_timeshift_packages
  _deploy_timeshift_config
  _configure_grub_btrfsd
  _enable_cron_service
  _create_initial_snapshot
}

main() {
  if is_distro "opensuse"; then
    echo "Setting up Snapper..."
    _setup_opensuse_snapper
    echo "setup-snapper complete"
  else
    echo "Setting up Timeshift..."
    _setup_timeshift
    echo "setup-timeshift complete"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
