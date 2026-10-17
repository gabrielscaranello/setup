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
