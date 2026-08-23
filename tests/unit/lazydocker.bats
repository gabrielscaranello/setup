#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-lazydocker.sh logic and branches

setup() {
  source /setup/scripts/setup-lazydocker.sh
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
  _get_package_manager() { echo "unknown-pm"; }
  run _install_lazydocker
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ package\ manager ]]
}

@test "_install_lazydocker delegates to repo on pacman" {
  _get_package_manager() { echo "pacman"; }
  _install_lazydocker_repo() {
    echo "installed from pacman"
    return 0
  }
  run _install_lazydocker
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ pacman ]]
}

@test "_install_lazydocker delegates to binary on apt and dnf" {
  _get_package_manager() { echo "apt"; }
  _install_lazydocker_binary() {
    echo "installed from binary apt"
    return 0
  }
  run _install_lazydocker
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary\ apt ]]

  _get_package_manager() { echo "dnf"; }
  _install_lazydocker_binary() {
    echo "installed from binary dnf"
    return 0
  }
  run _install_lazydocker
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ binary\ dnf ]]
}
