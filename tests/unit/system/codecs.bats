#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/system/setup-codecs.sh
}

@test "main fails when distribution is unsupported" {
  get_distro_id() {
    echo "unknown"
  }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution for codecs setup." ]]
}

@test "main configures repositories on Fedora before installing packages" {
  get_distro_id() { echo "fedora"; }
  
  _configure_fedora_repos() {
    echo "rpmfusion configured"
  }

  install_packages() {
    echo "packages installed: $*"
  }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "rpmfusion configured" ]]
  [[ "$output" =~ "packages installed: ffmpeg gstreamer-plugins-base gstreamer-plugins-good gstreamer-plugins-bad gstreamer-plugins-ugly gstreamer-libav codec-openh264" ]]
}

@test "main skips repository configuration on Debian" {
  get_distro_id() { echo "debian"; }

  _configure_fedora_repos() {
    echo "FAIL: Should not be called on Debian"
    return 1
  }

  install_packages() {
    echo "packages installed"
  }

  run main
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "FAIL" ]]
  [[ "$output" =~ "packages installed" ]]
}

@test "main skips repository configuration on Arch Linux" {
  get_distro_id() { echo "arch"; }

  _configure_fedora_repos() {
    echo "FAIL: Should not be called on Arch Linux"
    return 1
  }

  install_packages() {
    echo "packages installed"
  }

  run main
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "FAIL" ]]
  [[ "$output" =~ "packages installed" ]]
}

@test "_configure_fedora_repos calls add_fedora_rpmfusion_repo" {
  add_fedora_rpmfusion_repo() {
    echo "called rpmfusion helper"
  }
  
  run _configure_fedora_repos
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called rpmfusion helper" ]]
}
