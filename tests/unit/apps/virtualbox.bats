#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-virtualbox.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-virtualbox.sh
}

@test "_install_virtualbox fails when distribution is unsupported" {
  get_distro_id() {
    echo "unsupported_distro"
  }
  run _install_virtualbox
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution: unsupported_distro" ]]
}

@test "_install_virtualbox_packages calls add_debian_virtualbox_repo on Debian" {
  add_debian_virtualbox_repo() {
    echo "called add_debian_virtualbox_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_virtualbox_packages "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_debian_virtualbox_repo" ]]
  [[ "$output" =~ "installed packages: virtualbox virtualbox-host-modules" ]]
}

@test "_install_virtualbox_packages calls add_fedora_rpmfusion_repo on Fedora" {
  add_debian_virtualbox_repo() {
    echo "called add_debian_virtualbox_repo"
    return 0
  }
  add_fedora_rpmfusion_repo() {
    echo "called add_fedora_rpmfusion_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_virtualbox_packages "fedora"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "called add_debian_virtualbox_repo" ]]
  [[ "$output" =~ "called add_fedora_rpmfusion_repo" ]]
  [[ "$output" =~ "installed packages: virtualbox virtualbox-host-modules" ]]
}

@test "_install_virtualbox_packages installs packages on Arch Linux without calling debian repo" {
  add_debian_virtualbox_repo() {
    echo "called add_debian_virtualbox_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_virtualbox_packages "arch"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "called add_debian_virtualbox_repo" ]]
  [[ "$output" =~ "installed packages: virtualbox virtualbox-host-modules" ]]
}

@test "_configure_virtualbox_user_group adds user to vboxusers group" {
  export USER="testuser"
  getent() { return 1; }
  sudo() {
    echo "sudo $*"
    return 0
  }
  run _configure_virtualbox_user_group
  [ "$status" -eq 0 ]
  [[ "$output" =~ "User 'testuser' added to vboxusers group." ]]
}
