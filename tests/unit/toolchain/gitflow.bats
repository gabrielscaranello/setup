#!/usr/bin/env bats

# Unit tests for setup-gitflow.sh logic and branches

@test "_is_gitflow_installed returns true when git-flow command and version match" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  command() {
    if [ "${2:-}" = "git-flow" ]; then return 0; fi
    builtin command "$@"
  }
  git() {
    if [ "$1" = "flow" ] && [ "$2" = "version" ]; then
      echo "2.2.1 (AVH Edition & CJS Fork)"
      return 0
    fi
    return 1
  }
  GITFLOW_VERSION="2.2.1"
  run _is_gitflow_installed
  [ "$status" -eq 0 ]
}

@test "_is_gitflow_installed returns false when git-flow is not installed" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  command() {
    if [ "${2:-}" = "git-flow" ]; then return 1; fi
    builtin command "$@"
  }
  run _is_gitflow_installed
  [ "$status" -eq 1 ]
}

@test "_is_gitflow_installed returns false when version does not match" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  command() {
    if [ "${2:-}" = "git-flow" ]; then return 0; fi
    builtin command "$@"
  }
  git() {
    if [ "$1" = "flow" ] && [ "$2" = "version" ]; then
      echo "1.0.0 (Legacy)"
      return 0
    fi
    return 1
  }
  GITFLOW_VERSION="v2.2.1"
  run _is_gitflow_installed
  [ "$status" -eq 1 ]
}

@test "_install_gitflow skips installation when already installed" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  _is_gitflow_installed() { return 0; }
  run _install_gitflow
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed, skipping" ]]
}

@test "_install_gitflow uses wget when curl is unavailable" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  _is_gitflow_installed() { return 1; }
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    builtin command "$@"
  }
  wget() {
    local target="${2:-}"
    touch "$target"
    return 0
  }
  sudo() { return 0; }
  run _install_gitflow
  [ "$status" -eq 0 ]
}

@test "_download_gitflow_installer downloads and sets executable bit" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  download_file() {
    touch "$2"
    return 0
  }
  chmod() {
    echo "chmod $1 $2"
    return 0
  }
  run _download_gitflow_installer "http://example.com/installer.sh" "/tmp/test.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "chmod +x /tmp/test.sh" ]]
}

@test "_run_gitflow_installer executes installer with correct version" {
  source /setup/scripts/toolchain/setup-gitflow.sh
  sudo() {
    echo "sudo $*"
    return 0
  }
  run _run_gitflow_installer "/tmp/test-dir" "/tmp/test-dir/installer.sh" "v2.2.1"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo bash /tmp/test-dir/installer.sh install version v2.2.1" ]]
}
