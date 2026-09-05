#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-lazydocker.sh logic and branches

setup() {
  source /setup/scripts/terminal/setup-lazydocker.sh
}

@test "_fetch_remote_version returns trimmed version string using curl" {
  curl() {
    echo '{"tag_name": "v0.25.2"}'
    return 0
  }
  command() {
    if [ "${2:-}" = "curl" ]; then return 0; fi
    builtin command "$@"
  }
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "0.25.2" ]
}

@test "_fetch_remote_version uses wget when curl is unavailable" {
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    if [ "${2:-}" = "wget" ]; then return 0; fi
    builtin command "$@"
  }
  wget() {
    echo '{"tag_name": "v0.25.2"}'
    return 0
  }
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [ "$output" = "0.25.2" ]
}

@test "_get_local_version parses version correctly from lazydocker command" {
  lazydocker() {
    echo "commit=..., build date=..., build source=..., version=0.25.2, os=linux, arch=amd64"
    return 0
  }
  command() {
    if [ "${2:-}" = "lazydocker" ]; then return 0; fi
    builtin command "$@"
  }
  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "0.25.2" ]
}

@test "_is_lazydocker_up_to_date returns true when local matches remote" {
  _get_local_version() { echo "0.25.2"; }
  _fetch_remote_version() { echo "0.25.2"; }
  run _is_lazydocker_up_to_date
  [ "$status" -eq 0 ]
}

@test "_is_lazydocker_up_to_date returns false when local does not match remote" {
  _get_local_version() { echo "0.20.0"; }
  _fetch_remote_version() { echo "0.25.2"; }
  run _is_lazydocker_up_to_date
  [ "$status" -eq 1 ]
}

@test "_is_lazydocker_up_to_date returns false when not installed" {
  _get_local_version() { echo ""; }
  _fetch_remote_version() { echo "0.25.2"; }
  run _is_lazydocker_up_to_date
  [ "$status" -eq 1 ]
}

@test "_install_lazydocker_binary skips download when up to date" {
  _is_lazydocker_up_to_date() { return 0; }
  _fetch_remote_version() { echo "0.25.2"; }
  run _install_lazydocker_binary
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ up\ to\ date ]]
}

@test "_install_lazydocker_binary uses wget when curl is unavailable" {
  _is_lazydocker_up_to_date() { return 1; }
  _fetch_remote_version() { echo "0.25.2"; }
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    builtin command "$@"
  }
  wget() { return 0; }
  tar() { return 0; }
  sudo() { return 0; }
  run _install_lazydocker_binary
  [ "$status" -eq 0 ]
}

@test "_install_lazydocker fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_lazydocker
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "_install_lazydocker delegates to repo on arch" {
  get_distro_id() { echo "arch"; }
  _install_lazydocker_repo() {
    echo "installed from arch"
    return 0
  }
  run _install_lazydocker
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ arch ]]
}

@test "_install_lazydocker delegates to binary on debian and fedora" {
  get_distro_id() { echo "debian"; }
  _install_lazydocker_binary() {
    echo "installed from binary debian"
    return 0
  }
  run _install_lazydocker
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary\ debian ]]

  get_distro_id() { echo "fedora"; }
  _install_lazydocker_binary() {
    echo "installed from binary fedora"
    return 0
  }
  run _install_lazydocker
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary\ fedora ]]
}

@test "_resolve_lazydocker_arch maps x86 and arm64 architectures" {
  uname() { echo "x86_64"; }
  run _resolve_lazydocker_arch
  [ "$status" -eq 0 ]
  [ "$output" = "x86_64" ]

  uname() { echo "aarch64"; }
  run _resolve_lazydocker_arch
  [ "$status" -eq 0 ]
  [ "$output" = "arm64" ]

  uname() { echo "i686"; }
  run _resolve_lazydocker_arch
  [ "$status" -eq 0 ]
  [ "$output" = "x86" ]
}
