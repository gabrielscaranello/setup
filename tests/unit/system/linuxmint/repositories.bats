#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/system/linuxmint/_repositories.sh 2> /dev/null || source scripts/system/linuxmint/_repositories.sh
}

teardown() {
  :
}

@test "get_linuxmint_base_codename detects UBUNTU_CODENAME from os-release" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="Linux Mint"
VERSION="22 (Wilma)"
ID=linuxmint
UBUNTU_CODENAME=noble
EOF

  OS_RELEASE_PATH="$os_release_file" run get_linuxmint_base_codename
  rm -f "$os_release_file"
  [ "$status" -eq 0 ]
  [ "$output" = "noble" ]
}

@test "get_linuxmint_base_codename detects noble on Linux Mint 22.3 (Zena)" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="Linux Mint"
VERSION="22.3 (Zena)"
ID=linuxmint
VERSION_ID="22.3"
VERSION_CODENAME=zena
UBUNTU_CODENAME=noble
EOF

  OS_RELEASE_PATH="$os_release_file" run get_linuxmint_base_codename
  rm -f "$os_release_file"
  [ "$status" -eq 0 ]
  [ "$output" = "noble" ]
}

@test "get_linuxmint_base_codename falls back to noble when codename is missing" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="Linux Mint"
ID=linuxmint
EOF

  OS_RELEASE_PATH="$os_release_file" run get_linuxmint_base_codename
  rm -f "$os_release_file"
  [ "$status" -eq 0 ]
  [ "$output" = "noble" ]
}
