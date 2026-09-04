#!/usr/bin/env bats

# Integration tests for setup-virtualbox.sh (runs across Debian 13, Fedora 44, and Arch Linux)

setup_file() {
  bash /setup/scripts/apps/setup-virtualbox.sh
}

@test "virtualbox package is installed or vboxmanage binary is available" {
  if command -v VBoxManage >/dev/null 2>&1; then
    run VBoxManage --version
    [ "$status" -eq 0 ]
  else
    # In minimal headless container environments without kernel modules, verify package installation
    source /setup/scripts/_utils.sh
    pm="$(_get_package_manager)"
    case "$pm" in
      apt) dpkg -l virtualbox-7.1 || dpkg -l virtualbox ;;
      dnf) rpm -q VirtualBox ;;
      pacman) pacman -Q virtualbox ;;
    esac
  fi
}

@test "vboxusers group exists" {
  getent group vboxusers
}

@test "setup-virtualbox.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/apps/setup-virtualbox.sh
  [ "$status" -eq 0 ]
}
