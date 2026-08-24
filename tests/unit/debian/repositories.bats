#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/debian/_repositories.sh utility functions

setup() {
  source /setup/scripts/debian/_repositories.sh
}

@test "_get_debian_codename retrieves DEBIAN_CODENAME when available (e.g. LMDE)" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="LMDE"
VERSION_CODENAME=faye
DEBIAN_CODENAME=bookworm
EOF

  _get_debian_codename_mock() {
    local debian_codename version_codename
    debian_codename="$(grep '^DEBIAN_CODENAME=' "$os_release_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$debian_codename" ]; then
      echo "$debian_codename"
      return 0
    fi
    version_codename="$(grep '^VERSION_CODENAME=' "$os_release_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$version_codename" ]; then
      echo "$version_codename"
      return 0
    fi
    echo "bookworm"
  }

  run _get_debian_codename_mock
  rm -f "$os_release_file"
  [ "$status" -eq 0 ]
  [ "$output" = "bookworm" ]
}

@test "_get_debian_codename retrieves VERSION_CODENAME on pure Debian" {
  local os_release_file
  os_release_file="$(mktemp)"
  cat << 'EOF' > "$os_release_file"
NAME="Debian GNU/Linux"
VERSION_CODENAME=trixie
EOF

  _get_debian_codename_mock() {
    local debian_codename version_codename
    debian_codename="$(grep '^DEBIAN_CODENAME=' "$os_release_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$debian_codename" ]; then
      echo "$debian_codename"
      return 0
    fi
    version_codename="$(grep '^VERSION_CODENAME=' "$os_release_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)"
    if [ -n "$version_codename" ]; then
      echo "$version_codename"
      return 0
    fi
    echo "bookworm"
  }

  run _get_debian_codename_mock
  rm -f "$os_release_file"
  [ "$status" -eq 0 ]
  [ "$output" = "trixie" ]
}

@test "_is_debian_backports_configured returns true when repo exists" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  mkdir -p "$tmp_dir/sources.list.d"
  echo "deb http://deb.debian.org/debian bookworm-backports main" > "$tmp_dir/sources.list.d/backports.list"

  _is_debian_backports_configured_mock() {
    local codename="$1"
    grep -Erq "^deb[[:space:]]+.*[[:space:]]+${codename}-backports[[:space:]]+" "$tmp_dir/sources.list.d" 2>/dev/null
  }

  run _is_debian_backports_configured_mock "bookworm"
  rm -rf "$tmp_dir"
  [ "$status" -eq 0 ]
}

@test "add_debian_backports_repo skips when repository is already configured" {
  _is_debian_backports_configured() {
    return 0
  }
  run add_debian_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ configured ]]
}

@test "add_debian_backports_repo configures repository when missing" {
  _is_debian_backports_configured() {
    return 1
  }
  _get_debian_codename() {
    echo "bookworm"
  }
  sudo() {
    if [ "$1" = "mkdir" ] || [ "$1" = "tee" ] || [ "$1" = "apt-get" ]; then
      return 0
    fi
    "$@"
  }
  run add_debian_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ Configuring\ Debian\ backports\ repository ]]
}
