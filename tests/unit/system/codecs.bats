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
  [[ "$output" =~ Unsupported\ distribution\ for\ codecs\ setup\. ]]
}

@test "main configures repositories on Fedora before installing packages" {
  get_distro_id() { echo "fedora"; }

  add_fedora_rpmfusion_repo() {
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

  add_fedora_rpmfusion_repo() {
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

  add_fedora_rpmfusion_repo() {
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
