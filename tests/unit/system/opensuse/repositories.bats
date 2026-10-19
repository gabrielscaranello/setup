#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/opensuse/_repositories.sh utility functions

setup() {
  source /setup/scripts/system/opensuse/_repositories.sh 2> /dev/null || \
  source "${BATS_TEST_DIRNAME}/../../../../scripts/system/opensuse/_repositories.sh"
}

@test "get_opensuse_version extracts version from os-release" {
  local test_os_release="/tmp/test-opensuse-release-$$"
  echo 'ID="opensuse-leap"' > "$test_os_release"
  echo 'VERSION_ID="16.1"' >> "$test_os_release"

  OS_RELEASE_PATH="$test_os_release" run get_opensuse_version
  [ "$status" -eq 0 ]
  [ "$output" = "16.1" ]

  rm -f "$test_os_release"
}

@test "get_opensuse_version detects tumbleweed" {
  local test_os_release="/tmp/test-tumbleweed-release-$$"
  echo 'ID="opensuse-tumbleweed"' > "$test_os_release"

  OS_RELEASE_PATH="$test_os_release" run get_opensuse_version
  [ "$status" -eq 0 ]
  [ "$output" = "tumbleweed" ]

  rm -f "$test_os_release"
}

@test "add_opensuse_packman_repo skips when repository is already configured" {
  zypper() {
    if [ "$1" = "lr" ] && [ "$2" = "packman-essentials" ]; then
      return 0
    fi
    return 1
  }

  run add_opensuse_packman_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_opensuse_packman_repo adds repository with priority 90 when missing" {
  zypper() {
    if [ "$1" = "lr" ]; then
      return 1
    fi
    return 0
  }
  sudo() {
    echo "sudo $*"
  }
  get_opensuse_version() {
    echo "16.0"
  }

  run add_opensuse_packman_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Packman Essentials repository for openSUSE (16.0)" ]]
}

@test "add_opensuse_nonfree_repo enables repo-non-oss when present" {
  zypper() {
    if [ "$1" = "lr" ] && [ "$2" = "openSUSE:repo-non-oss" ]; then
      return 0
    fi
    return 1
  }
  sudo() {
    echo "sudo $*"
  }

  run add_opensuse_nonfree_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Ensuring openSUSE Non-OSS repository is enabled" ]]
}

@test "add_opensuse_vscodium_repo skips when repository file exists" {
  zypper() {
    if [ "$1" = "lr" ] && [ "$2" = "vscodium" ]; then
      return 0
    fi
    return 1
  }

  run add_opensuse_vscodium_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_opensuse_vscodium_repo configures repository when missing" {
  zypper() {
    if [ "$1" = "lr" ]; then
      return 1
    fi
    return 0
  }
  sudo() {
    echo "sudo $*"
  }

  run add_opensuse_vscodium_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring VSCodium repository for Zypper" ]]
}

@test "add_opensuse_nvidia_repo skips on tumbleweed" {
  get_opensuse_version() { echo "tumbleweed"; }
  run add_opensuse_nvidia_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "openSUSE Tumbleweed uses native upstream kernel graphics drivers, skipping extra NVIDIA repo." ]]
}

@test "add_opensuse_nvidia_repo skips when repository already configured" {
  get_opensuse_version() { echo "16.1"; }
  zypper() {
    if [ "$1" = "lr" ] && [ "$2" = "NVIDIA" ]; then
      return 0
    fi
    return 1
  }

  run add_opensuse_nvidia_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "NVIDIA repository already configured on openSUSE, skipping." ]]
}

@test "add_opensuse_nvidia_repo configures repository on leap" {
  get_opensuse_version() { echo "16.1"; }
  zypper() {
    if [ "$1" = "lr" ] || [ "$1" = "ls" ]; then
      return 1
    elif [ "$1" = "se" ]; then
      return 0
    fi
    return 0
  }
  install_packages() {
    echo "installed: $*"
    return 0
  }
  sudo() { echo "sudo $*"; }

  run add_opensuse_nvidia_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring NVIDIA repository for openSUSE Leap (16.1)..." ]]
  [[ "$output" =~ "installed: openSUSE-repos-Leap-NVIDIA" ]]
}

@test "add_opensuse_mozilla_repo skips when repository is already configured" {
  zypper() {
    if [ "$1" = "lr" ] && [ "$2" = "mozilla" ]; then
      return 0
    fi
    return 1
  }

  run add_opensuse_mozilla_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_opensuse_mozilla_repo configures mozilla repository on openSUSE leap" {
  get_opensuse_version() { echo "16.0"; }
  zypper() {
    if [ "$1" = "lr" ]; then
      return 1
    fi
    return 0
  }
  sudo() { echo "sudo $*"; }

  run add_opensuse_mozilla_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Mozilla repository for openSUSE (16.0)..." ]]
  [[ "$output" =~ "sudo zypper --non-interactive addrepo -cfp 90 https://download.opensuse.org/repositories/mozilla/16.0/mozilla.repo" ]]
  [[ "$output" =~ "sudo zypper --non-interactive --gpg-auto-import-keys refresh mozilla" ]]
}

@test "add_opensuse_mozilla_repo configures mozilla repository on openSUSE tumbleweed" {
  get_opensuse_version() { echo "tumbleweed"; }
  zypper() {
    if [ "$1" = "lr" ]; then
      return 1
    fi
    return 0
  }
  sudo() { echo "sudo $*"; }

  run add_opensuse_mozilla_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Mozilla repository for openSUSE (tumbleweed)..." ]]
  [[ "$output" =~ "sudo zypper --non-interactive addrepo -cfp 90 https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed/mozilla.repo" ]]
  [[ "$output" =~ "sudo zypper --non-interactive --gpg-auto-import-keys refresh mozilla" ]]
}

@test "add_opensuse_kernel_backports_repo skips when repository is already configured" {
  zypper() {
    if [ "$1" = "lr" ] && [ "$2" = "Kernel:stable" ]; then
      return 0
    fi
    return 1
  }

  run add_opensuse_kernel_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_opensuse_kernel_backports_repo skips on tumbleweed" {
  get_opensuse_version() { echo "tumbleweed"; }
  zypper() { return 1; }

  run add_opensuse_kernel_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "openSUSE Tumbleweed already runs the latest rolling kernel. Skipping kernel repository." ]]
}

@test "add_opensuse_kernel_backports_repo configures Kernel:stable repository on openSUSE leap" {
  get_opensuse_version() { echo "16.1"; }
  zypper() {
    if [ "$1" = "lr" ]; then
      return 1
    fi
    return 0
  }
  sudo() { echo "sudo $*"; }

  run add_opensuse_kernel_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Kernel stable repository for openSUSE Leap (16.1)..." ]]
  [[ "$output" =~ "sudo zypper --non-interactive addrepo -cfp 90 https://download.opensuse.org/repositories/Kernel:/stable/standard Kernel:stable" ]]
  [[ "$output" =~ "sudo zypper --non-interactive --gpg-auto-import-keys refresh Kernel:stable" ]]
}

