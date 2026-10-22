#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/terminal/setup-cli.sh 2> /dev/null \
    || source "${BATS_TEST_DIRNAME}/../../../scripts/terminal/setup-cli.sh"
}

@test "_install_cli_tools installs modern CLI utilities" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_cli_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: bat btop eza gdu zsh zsh-completions man-db util-linux-user" ]]
}

@test "_install_cli_session_tools installs connectivity and clipboard utilities without XDG desktop packages" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_cli_session_tools
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: openssh dialog keychain clipboard" ]]
  [[ ! "$output" =~ "xdg-user-dirs" ]]
  [[ ! "$output" =~ "xdg-utils" ]]
}

@test "main fails when distribution is unsupported" {
  get_distro_id() {
    echo "unknown-distro"
    return 1
  }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "main executes all CLI setup steps in order" {
  require_supported_distro() { echo "debian"; }
  _install_cli_tools() { echo "step: cli_tools"; }
  _install_cli_session_tools() { echo "step: cli_session_tools"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: cli_tools" ]]
  [[ "$output" =~ "step: cli_session_tools" ]]
  [[ "$output" =~ "setup-cli complete" ]]
}
