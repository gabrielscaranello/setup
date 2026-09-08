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

@test "_swap_fedora_ffmpeg swaps ffmpeg-free for ffmpeg when ffmpeg-free is present" {
  rpm() {
    if [ "$2" = "ffmpeg-free" ]; then return 0; fi
    if [ "$2" = "ffmpeg" ]; then return 1; fi
    return 1
  }
  sudo() { echo "sudo: $*"; return 0; }

  run _swap_fedora_ffmpeg
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Swapping ffmpeg-free for full ffmpeg from RPM Fusion..." ]]
  [[ "$output" =~ "sudo: dnf swap -y ffmpeg-free ffmpeg --allowerasing" ]]
}

@test "_swap_fedora_ffmpeg does nothing if ffmpeg is already installed" {
  rpm() {
    if [ "$2" = "ffmpeg-free" ]; then return 0; fi
    if [ "$2" = "ffmpeg" ]; then return 0; fi
    return 1
  }
  sudo() { echo "sudo: $*"; return 0; }

  run _swap_fedora_ffmpeg
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Swapping ffmpeg-free" ]]
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
