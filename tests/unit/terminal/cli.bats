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

@test "_configure_default_shell sets zsh as login shell when not already configured" {
  local fake_passwd="/tmp/test-passwd-$$"
  echo "testuser:x:1000:1000::/home/testuser:/bin/bash" > "$fake_passwd"

  command() {
    if [ "${2:-}" = "zsh" ]; then
      echo "/usr/bin/zsh"
      return 0
    fi
    if [ "${2:-}" = "usermod" ]; then
      return 0
    fi
    builtin command "$@"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  USER="testuser" PASSWD_PATH="$fake_passwd" run _configure_default_shell
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo usermod -s /usr/bin/zsh testuser" ]]

  rm -f "$fake_passwd"
}

@test "_configure_default_shell skips usermod when zsh is already the login shell" {
  local fake_passwd="/tmp/test-passwd-$$"
  echo "testuser:x:1000:1000::/home/testuser:/usr/bin/zsh" > "$fake_passwd"

  command() {
    if [ "${2:-}" = "zsh" ]; then
      echo "/usr/bin/zsh"
      return 0
    fi
    builtin command "$@"
  }
  sudo() {
    echo "sudo $*"
    return 0
  }

  USER="testuser" PASSWD_PATH="$fake_passwd" run _configure_default_shell
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "sudo usermod" ]]

  rm -f "$fake_passwd"
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
  _configure_default_shell() { echo "step: default_shell"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: cli_tools" ]]
  [[ "$output" =~ "step: cli_session_tools" ]]
  [[ "$output" =~ "step: default_shell" ]]
  [[ "$output" =~ "setup-cli complete" ]]
}
