#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-lazygit.sh logic and branches

setup() {
  source /setup/scripts/terminal/setup-lazygit.sh
}

@test "_fetch_remote_version delegates to fetch_github_latest_version with correct repo" {
  fetch_github_latest_version() {
    echo "called with: $*"
  }
  run _fetch_remote_version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called with: jesseduffield/lazygit" ]]
}

@test "_get_local_version parses version correctly from lazygit command" {
  lazygit() {
    echo "commit=..., build date=..., build source=..., version=0.64.1, os=linux, arch=amd64"
    return 0
  }
  command() {
    if [ "${2:-}" = "lazygit" ]; then return 0; fi
    builtin command "$@"
  }
  run _get_local_version
  [ "$status" -eq 0 ]
  [ "$output" = "0.64.1" ]
}

@test "_is_lazygit_up_to_date returns true when local matches remote" {
  _get_local_version() { echo "0.64.1"; }
  _fetch_remote_version() { echo "0.64.1"; }
  run _is_lazygit_up_to_date
  [ "$status" -eq 0 ]
}

@test "_is_lazygit_up_to_date returns false when local does not match remote" {
  _get_local_version() { echo "0.60.0"; }
  _fetch_remote_version() { echo "0.64.1"; }
  run _is_lazygit_up_to_date
  [ "$status" -eq 1 ]
}

@test "_is_lazygit_up_to_date returns false when not installed" {
  _get_local_version() { echo ""; }
  _fetch_remote_version() { echo "0.64.1"; }
  run _is_lazygit_up_to_date
  [ "$status" -eq 1 ]
}

@test "_install_lazygit_binary skips download when up to date" {
  _is_lazygit_up_to_date() { return 0; }
  _fetch_remote_version() { echo "0.64.1"; }
  run _install_lazygit_binary
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ up\ to\ date ]]
}

@test "_install_lazygit_binary uses wget when curl is unavailable" {
  _is_lazygit_up_to_date() { return 1; }
  _fetch_remote_version() { echo "0.64.1"; }
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    builtin command "$@"
  }
  wget() { return 0; }
  tar() { return 0; }
  sudo() { return 0; }
  run _install_lazygit_binary
  [ "$status" -eq 0 ]
}

@test "_install_lazygit fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_lazygit
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "_install_lazygit delegates to repo on arch" {
  get_distro_id() { echo "arch"; }
  require_supported_distro() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_lazygit
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ packages:\ lazygit ]]
}

@test "_install_lazygit delegates to binary on debian and fedora" {
  get_distro_id() { echo "debian"; }
  _install_lazygit_binary() {
    echo "installed from binary debian"
    return 0
  }
  run _install_lazygit
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary\ debian ]]

  get_distro_id() { echo "fedora"; }
  _install_lazygit_binary() {
    echo "installed from binary fedora"
    return 0
  }
  run _install_lazygit
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary\ fedora ]]
}

@test "_resolve_lazygit_arch returns correct architecture string" {
  uname() { echo "x86_64"; }
  run _resolve_lazygit_arch
  [ "$status" -eq 0 ]
  [ "$output" = "x86_64" ]

  uname() { echo "aarch64"; }
  run _resolve_lazygit_arch
  [ "$status" -eq 0 ]
  [ "$output" = "arm64" ]

  uname() { echo "arm64"; }
  run _resolve_lazygit_arch
  [ "$status" -eq 0 ]
  [ "$output" = "arm64" ]

  uname() { echo "i686"; }
  run _resolve_lazygit_arch
  [ "$status" -eq 0 ]
  [ "$output" = "32-bit" ]
}
