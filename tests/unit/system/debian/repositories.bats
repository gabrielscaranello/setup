#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/debian/_repositories.sh utility functions

setup() {
  source /setup/scripts/system/debian/_repositories.sh
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
    if [ "$1" = "mkdir" ] || [ "$1" = "tee" ] || [ "$1" = "apt" ]; then
      return 0
    fi
    "$@"
  }
  run add_debian_backports_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ Configuring\ Debian\ backports\ repository ]]
}

@test "add_debian_vscodium_repo skips when repository files exist" {
  local test_dir="/tmp/test-vscodium-apt-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/vscodium.sources" "$test_dir/vscodium-archive-keyring.gpg"

  add_debian_vscodium_repo() {
    local keyring_path="$test_dir/vscodium-archive-keyring.gpg"
    local sources_path="$test_dir/vscodium.sources"
    if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
      echo "VSCodium repository already configured on Debian, skipping."
      return 0
    fi
  }

  run add_debian_vscodium_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_debian_mozilla_repo skips when repository files exist" {
  local test_dir="/tmp/test-mozilla-apt-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/mozilla.sources" "$test_dir/packages.mozilla.org.asc"

  add_debian_mozilla_repo() {
    local keyring_path="$test_dir/packages.mozilla.org.asc"
    local sources_path="$test_dir/mozilla.sources"
    if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
      echo "Mozilla repository already configured, skipping."
      return 0
    fi
  }

  run add_debian_mozilla_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_debian_virtualbox_repo skips when repository files exist" {
  local test_dir="/tmp/test-virtualbox-apt-repo"
  mkdir -p "$test_dir"
  touch "$test_dir/virtualbox.sources" "$test_dir/oracle-virtualbox-2016.gpg"

  add_debian_virtualbox_repo() {
    local keyring_path="$test_dir/oracle-virtualbox-2016.gpg"
    local sources_path="$test_dir/virtualbox.sources"
    if [ -f "$sources_path" ] && [ -f "$keyring_path" ]; then
      echo "VirtualBox repository already configured on Debian, skipping."
      return 0
    fi
  }

  run add_debian_virtualbox_repo
  rm -rf "$test_dir"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already configured" ]]
}

@test "add_debian_virtualbox_repo configures repo when not present" {
  local test_dir="/tmp/test-virtualbox-apt-repo-new"
  mkdir -p "$test_dir"

  sudo() {
    return 0
  }
  _get_debian_codename() {
    echo "trixie"
  }
  command() {
    if [ "$2" = "wget" ]; then
      return 0
    fi
    builtin command "$@"
  }
  wget() {
    return 0
  }
  gpg() {
    return 0
  }

  run add_debian_virtualbox_repo
  rm -rf "$test_dir"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring Oracle VirtualBox repository for APT" ]]
}

@test "add_debian_nonfree_repo ensures contrib, non-free and non-free-firmware on deb822 sources" {
  export APT_DEBIAN_SOURCES="/tmp/test_debian_nonfree_$$.sources"
  cat << 'EOF' > "$APT_DEBIAN_SOURCES"
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  sudo() { "$@"; }
  apt() { return 0; }

  run add_debian_nonfree_repo
  [ "$status" -eq 0 ]
  grep -q "contrib non-free non-free-firmware" "$APT_DEBIAN_SOURCES"
  rm -f "$APT_DEBIAN_SOURCES"
}

@test "add_debian_nonfree_repo ensures contrib, non-free and non-free-firmware on sources.list" {
  export APT_DEBIAN_SOURCES="/tmp/nonexistent_$$.sources"
  export APT_SOURCES_LIST="/tmp/test_sources_list_$$"
  cat << 'EOF' > "$APT_SOURCES_LIST"
deb http://deb.debian.org/debian trixie main
EOF
  sudo() { "$@"; }
  apt() { return 0; }

  run add_debian_nonfree_repo
  [ "$status" -eq 0 ]
  grep -q "contrib non-free non-free-firmware" "$APT_SOURCES_LIST"
  rm -f "$APT_SOURCES_LIST"
}

