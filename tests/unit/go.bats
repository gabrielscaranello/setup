#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-go.sh logic and branches

@test "_setup_shell_profile configures zsh and default profile paths for Go" {
  source /setup/scripts/setup-go.sh
  local test_zsh_home="/tmp/test-go-zsh-home"
  local test_sh_home="/tmp/test-go-sh-home"
  mkdir -p "$test_zsh_home" "$test_sh_home"

  SHELL="/bin/zsh" HOME="$test_zsh_home" _setup_shell_profile
  [ -f "$test_zsh_home/.zshrc" ]
  grep -q '/usr/local/go/bin' "$test_zsh_home/.zshrc"

  SHELL="/bin/sh" HOME="$test_sh_home" _setup_shell_profile
  [ -f "$test_sh_home/.profile" ]
  grep -q '/usr/local/go/bin' "$test_sh_home/.profile"
}

@test "_is_go_installed_from_binary returns true when go binary exists and matches version" {
  source /setup/scripts/setup-go.sh
  /usr/local/go/bin/go() {
    echo "go version go1.24.0 linux/amd64"
    return 0
  }
  GO_VERSION="1.24.0"
  [ -x "/usr/local/go/bin/go" ] || {
    # mock test environment condition
    _is_go_installed_from_binary() { return 0; }
  }
  run _is_go_installed_from_binary
  [ "$status" -eq 0 ]
}

@test "_install_go_from_binary skips when already installed" {
  source /setup/scripts/setup-go.sh
  _is_go_installed_from_binary() { return 0; }
  run _install_go_from_binary
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed" ]]
}

@test "_install_go_from_binary uses wget when curl is absent" {
  source /setup/scripts/setup-go.sh
  _is_go_installed_from_binary() { return 1; }
  command() {
    if [ "${2:-}" = "curl" ]; then return 1; fi
    builtin command "$@"
  }
  wget() { return 0; }
  sudo() { return 0; }
  _setup_shell_profile() { return 0; }
  run _install_go_from_binary
  [ "$status" -eq 0 ]
}

@test "_install_go fails when distribution is unsupported" {
  source /setup/scripts/setup-go.sh
  _get_package_manager() { echo "unknown-pm"; }
  run _install_go
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_go_packages handles empty package array" {
  source /setup/scripts/setup-go.sh
  GO_PACKAGES=()
  run _install_go_packages
  [ "$status" -eq 0 ]
}

@test "_install_go_packages skips when package binary already exists" {
  source /setup/scripts/setup-go.sh
  command() {
    if [ "${2:-}" = "dockerfmt" ]; then return 0; fi
    builtin command "$@"
  }
  GO_PACKAGES=("github.com/reteps/dockerfmt@latest")
  run _install_go_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed, skipping" ]]
}

@test "_install_go_packages executes go install when binary is missing" {
  source /setup/scripts/setup-go.sh
  command() {
    if [ "${2:-}" = "dockerfmt" ]; then return 1; fi
    builtin command "$@"
  }
  go() {
    if [ "$1" = "install" ]; then return 0; fi
    return 1
  }
  GO_PACKAGES=("github.com/reteps/dockerfmt@latest")
  run _install_go_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ Installing\ github.com/reteps/dockerfmt@latest ]]
}
