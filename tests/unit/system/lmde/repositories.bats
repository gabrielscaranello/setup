#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/lmde/_repositories.sh utility functions

setup() {
  source /setup/scripts/system/lmde/_repositories.sh 2>/dev/null || source scripts/system/lmde/_repositories.sh
}

@test "get_lmde_codename retrieves VERSION_CODENAME from os-release" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="LMDE"
VERSION="7 (gigi)"
ID=linuxmint
ID_LIKE=debian
VERSION_CODENAME=gigi
DEBIAN_CODENAME=trixie
EOF

  export OS_RELEASE_PATH="$os_release_file"
  run get_lmde_codename
  rm -f "$os_release_file"
  unset OS_RELEASE_PATH

  [ "$status" -eq 0 ]
  [ "$output" = "gigi" ]
}

@test "get_lmde_codename falls back to /etc/linuxmint/info or gigi" {
  export OS_RELEASE_PATH="/tmp/nonexistent-os-release-$$"
  run get_lmde_codename
  unset OS_RELEASE_PATH

  [ "$status" -eq 0 ]
  [ "$output" = "gigi" ]
}

@test "get_lmde_debian_codename retrieves DEBIAN_CODENAME from os-release" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="LMDE"
VERSION="7 (gigi)"
DEBIAN_CODENAME=trixie
EOF

  export OS_RELEASE_PATH="$os_release_file"
  run get_lmde_debian_codename
  rm -f "$os_release_file"
  unset OS_RELEASE_PATH

  [ "$status" -eq 0 ]
  [ "$output" = "trixie" ]
}

@test "get_lmde_debian_codename falls back to get_debian_codename when missing" {
  export OS_RELEASE_PATH="/tmp/nonexistent-os-release-$$"
  get_debian_codename() {
    echo "trixie-fallback"
  }

  run get_lmde_debian_codename
  unset OS_RELEASE_PATH

  [ "$status" -eq 0 ]
  [ "$output" = "trixie-fallback" ]
}

@test "_is_lmde_official_repo_configured detects repository in APT_SOURCES_LIST" {
  local sources_list
  sources_list="$(mktemp)"
  echo "deb http://packages.linuxmint.com gigi main upstream import backport" > "$sources_list"

  export APT_SOURCES_LIST="$sources_list"
  export APT_SOURCES_D="/tmp/nonexistent_sources_d_$$"

  run _is_lmde_official_repo_configured
  rm -f "$sources_list"
  unset APT_SOURCES_LIST APT_SOURCES_D

  [ "$status" -eq 0 ]
}

@test "_is_lmde_official_repo_configured detects repository in APT_SOURCES_D" {
  local sources_dir
  sources_dir="$(mktemp -d)"
  echo "deb http://packages.linuxmint.com gigi main upstream import backport" > "$sources_dir/mint.list"

  export APT_SOURCES_LIST="/tmp/nonexistent_sources_list_$$"
  export APT_SOURCES_D="$sources_dir"

  run _is_lmde_official_repo_configured
  rm -rf "$sources_dir"
  unset APT_SOURCES_LIST APT_SOURCES_D

  [ "$status" -eq 0 ]
}

@test "add_lmde_official_repo skips when already configured" {
  _is_lmde_official_repo_configured() {
    return 0
  }

  run add_lmde_official_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Linux Mint official repository is already configured, skipping." ]]
}

@test "add_lmde_official_repo configures repository file when missing" {
  _is_lmde_official_repo_configured() {
    return 1
  }
  get_lmde_codename() {
    echo "gigi"
  }
  dpkg() {
    return 0 # keyring already installed
  }
  sudo() {
    if [ "$1" = "mkdir" ] || [ "$1" = "tee" ] || [ "$1" = "apt" ]; then
      return 0
    fi
    "$@"
  }

  run add_lmde_official_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Linux Mint repository for codename 'gigi'..." ]]
  [[ "$output" =~ "Updating APT package cache for Linux Mint..." ]]
}

@test "add_lmde_backports_repo skips when already configured" {
  _is_debian_backports_configured() {
    return 0
  }

  run add_lmde_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured, skipping." ]]
}

@test "add_lmde_backports_repo configures backports when missing" {
  _is_debian_backports_configured() {
    return 1
  }
  get_lmde_debian_codename() {
    echo "trixie"
  }
  sudo() {
    if [ "$1" = "mkdir" ] || [ "$1" = "tee" ] || [ "$1" = "apt" ]; then
      return 0
    fi
    "$@"
  }

  run add_lmde_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Debian backports repository for codename 'trixie'..." ]]
  [[ "$output" =~ "Updating APT package cache for Debian backports..." ]]
}
