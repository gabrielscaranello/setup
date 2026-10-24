#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/opensuse/setup-kernel.sh

setup() {
  source /setup/scripts/system/opensuse/setup-kernel.sh 2>/dev/null || source scripts/system/opensuse/setup-kernel.sh
}

@test "_install_backports_kernel_leap calls add_opensuse_kernel_backports_repo and installs kernel from Kernel:stable" {
  add_opensuse_kernel_backports_repo() {
    echo "called add_opensuse_kernel_backports_repo"
    return 0
  }
  sudo() {
    echo "sudo $*"
    return 0
  }
  run _install_backports_kernel_leap
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_opensuse_kernel_backports_repo" ]]
  [[ "$output" =~ "Kernel:stable" ]]
  [[ "$output" =~ "kernel-default" ]]
  [[ "$output" =~ "kernel-default-devel" ]]
}

@test "_setup_opensuse_kernel executes kernel installation on openSUSE Leap" {
  get_distro_id() {
    echo "opensuse-leap"
  }
  _install_backports_kernel_leap() {
    echo "called _install_backports_kernel_leap"
    return 0
  }
  run _setup_opensuse_kernel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_backports_kernel_leap" ]]
}

@test "_setup_opensuse_kernel executes kernel installation on generic opensuse" {
  get_distro_id() {
    echo "opensuse"
  }
  _install_backports_kernel_leap() {
    echo "called _install_backports_kernel_leap"
    return 0
  }
  run _setup_opensuse_kernel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_backports_kernel_leap" ]]
}

@test "_setup_opensuse_kernel skips on openSUSE Tumbleweed" {
  get_distro_id() {
    echo "opensuse-tumbleweed"
  }
  run _setup_opensuse_kernel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "openSUSE Tumbleweed is a rolling release and already runs the latest kernel." ]]
}

@test "_setup_opensuse_kernel skips on non-openSUSE distributions" {
  get_distro_id() {
    echo "debian"
  }
  run _setup_opensuse_kernel
  [ "$status" -eq 0 ]
  [[ "$output" =~ "openSUSE kernel backports is only applicable to openSUSE Leap. Skipping on 'debian'." ]]
}

@test "_setup_opensuse_kernel fails when distribution detection fails" {
  get_distro_id() {
    return 1
  }
  run _setup_opensuse_kernel
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "main executes successfully on openSUSE Leap" {
  get_distro_id() {
    echo "opensuse-leap"
  }
  _install_backports_kernel_leap() {
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up openSUSE latest kernel and headers..." ]]
  [[ "$output" =~ "setup-kernel complete" ]]
}
