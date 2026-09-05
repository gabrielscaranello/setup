#!/bin/bash

set -euo pipefail

# Follow project conventions: source utility helpers and use private functions
source "scripts/_utils.sh" 2> /dev/null || true

GRUB_BTRFS_REPO_URL="https://github.com/Antynea/grub-btrfs.git"

_install_timeshift_packages() {
  echo "Installing Timeshift and UI dependencies..."
  install_packages timeshift || true
}

_get_config_dir() {
  echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config"
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

_write_timeshift_config() {
  local content="$1"
  local target_dir="/etc/timeshift"
  local target_file="$target_dir/timeshift.json"

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

_install_grub_btrfs_dependencies() {
  echo "Installing grub-btrfs dependencies (btrfs-progs, gawk, inotify-tools)..."
  install_packages btrfs-progs gawk inotify-tools || true
}

_install_grub_btrfs_arch() {
  echo "Installing grub-btrfs and dependencies via repository..."
  _install_grub_btrfs_dependencies
  install_packages grub-btrfs || true
}

_configure_grub_btrfs_source_config() {
  local target_dir="$1"
  local distro="$2"

  if [ "$distro" = "fedora" ]; then
    sed -i 's|^#GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig|GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig|' "$target_dir/config" 2> /dev/null || true
    sed -i 's|^#GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"|GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"|' "$target_dir/config" 2> /dev/null || true
    sed -i 's|^#GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check|GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check|' "$target_dir/config" 2> /dev/null || true
  fi
}

_install_grub_btrfs_from_source() {
  local distro="$1"
  local build_dir="/tmp/grub-btrfs"

  _install_grub_btrfs_dependencies

  echo "Cloning and installing grub-btrfs from source..."
  rm -rf "$build_dir"
  git clone --depth=1 "$GRUB_BTRFS_REPO_URL" "$build_dir"

  _configure_grub_btrfs_source_config "$build_dir" "$distro"

  (cd "$build_dir" && sudo make install)
  rm -rf "$build_dir"

  if command -v systemctl > /dev/null 2>&1; then
    sudo systemctl daemon-reload 2> /dev/null || true
  fi
}

_install_grub_btrfs() {
  local distro
  distro="$(get_distro_id)" || return 0

  if [ "$distro" = "arch" ]; then
    _install_grub_btrfs_arch
  else
    _install_grub_btrfs_from_source "$distro"
  fi
}

_get_grub_btrfsd_service_file() {
  if ! command -v systemctl > /dev/null 2>&1; then
    return 0
  fi
  systemctl show -p FragmentPath grub-btrfsd.service 2> /dev/null | cut -d= -f2 || true
}

_patch_grub_btrfsd_service() {
  local service_file="$1"
  sudo sed -i 's|^ExecStart=/usr/bin/grub-btrfsd.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$service_file"
}

_enable_grub_btrfsd_service() {
  sudo systemctl stop grub-btrfsd.service 2> /dev/null || true
  sudo systemctl daemon-reload 2> /dev/null || true
  sudo systemctl enable --now grub-btrfsd.service 2> /dev/null || true
}

_regenerate_grub_btrfs_menu() {
  if [ -x /etc/grub.d/41_snapshots-btrfs ]; then
    echo "Updating GRUB snapshot menu entries..."
    sudo /etc/grub.d/41_snapshots-btrfs 2> /dev/null || true

    if command -v grub2-mkconfig > /dev/null 2>&1; then
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2> /dev/null || true
    elif command -v grub-mkconfig > /dev/null 2>&1; then
      sudo grub-mkconfig -o /boot/grub/grub.cfg 2> /dev/null || true
    elif command -v update-grub > /dev/null 2>&1; then
      sudo update-grub 2> /dev/null || true
    fi
  fi
}

_configure_grub_btrfsd() {
  local fs_type service_file
  fs_type="$(get_root_filesystem)"

  if [ "$fs_type" != "btrfs" ]; then
    return 0
  fi

  _install_grub_btrfs

  service_file="$(_get_grub_btrfsd_service_file)"
  if [ -n "$service_file" ] && [ -f "$service_file" ]; then
    echo "Configuring grub-btrfsd service integration..."
    _patch_grub_btrfsd_service "$service_file"
    _enable_grub_btrfsd_service
    echo "grub-btrfsd service enabled with --timeshift-auto."
  fi

  _regenerate_grub_btrfs_menu
}

_setup_timeshift() {
  _install_timeshift_packages
  _deploy_timeshift_config
  _configure_grub_btrfsd
  _create_initial_snapshot
}

main() {
  echo "Setting up Timeshift..."
  _setup_timeshift
  echo "setup-timeshift complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
