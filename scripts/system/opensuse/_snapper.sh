#!/bin/bash

# openSUSE Snapper Snapshot & GRUB Integration Helpers
# Sourced by scripts/system/setup-timeshift.sh. Do NOT execute directly.

_install_opensuse_snapper_packages() {
  echo "Installing Snapper and plugins for openSUSE..."
  install_packages snapper snapper-zypp-plugin grub2-snapper-plugin btrfs-progs || true
}

_configure_opensuse_snapper() {
  local fs_type
  fs_type="$(get_root_filesystem)"

  echo "Configuring Snapper..."
  if [ "$fs_type" = "btrfs" ]; then
    if ! sudo snapper --no-dbus list-configs 2> /dev/null | grep -q "root"; then
      echo "Creating Snapper root config..."
      sudo snapper --no-dbus create-config / 2> /dev/null || true
    fi
  fi

  if command -v systemctl > /dev/null 2>&1; then
    echo "Enabling Snapper systemd timers..."
    sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer snapper-boot.timer 2> /dev/null || true
  fi

  if [ "$fs_type" = "btrfs" ] && [ -f /etc/default/grub ]; then
    echo "Configuring GRUB snapshot boot integration..."
    if grep -q "^SUSE_BTRFS_SNAPSHOT_BOOTING=" /etc/default/grub; then
      sudo sed -i 's/^SUSE_BTRFS_SNAPSHOT_BOOTING=.*/SUSE_BTRFS_SNAPSHOT_BOOTING="true"/' /etc/default/grub
    else
      echo 'SUSE_BTRFS_SNAPSHOT_BOOTING="true"' | sudo tee -a /etc/default/grub > /dev/null
    fi

    if command -v grub2-mkconfig > /dev/null 2>&1; then
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2> /dev/null || true
    fi
  fi
}

_create_opensuse_initial_snapshot() {
  if ! command -v snapper > /dev/null 2>&1; then
    return 0
  fi

  if sudo snapper --no-dbus list-configs 2> /dev/null | grep -q "root"; then
    echo "Creating initial baseline Snapper snapshot..."
    sudo snapper --no-dbus create --type single --description "Initial setup snapshot" --cleanup-algorithm number 2> /dev/null || true
  fi
}

_setup_opensuse_snapper() {
  _install_opensuse_snapper_packages
  _configure_opensuse_snapper
  _create_opensuse_initial_snapshot
}
