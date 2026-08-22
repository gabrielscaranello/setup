#!/usr/bin/env bats

# Integration tests for setup-nvm.sh on Debian.

NVM_INIT='. "$HOME/.nvm/nvm.sh"'

setup_file() {
  bash /setup/scripts/setup-nvm.sh
}

@test "nvm is installed and responds to --version" {
  run bash -c "$NVM_INIT && nvm --version"
  [ "$status" -eq 0 ]
}

@test "node is installed and responds to --version" {
  run bash -c "$NVM_INIT && node --version"
  [ "$status" -eq 0 ]
}

@test "npm is installed and responds to --version" {
  run bash -c "$NVM_INIT && npm --version"
  [ "$status" -eq 0 ]
}

@test "yarn is installed and responds to --version" {
  run bash -c "$NVM_INIT && yarn --version"
  [ "$status" -eq 0 ]
}

@test "@github/copilot is installed globally" {
  run bash -c "$NVM_INIT && npm ls -g --depth 0 '@github/copilot'"
  [ "$status" -eq 0 ]
}

@test "@styled/typescript-styled-plugin is installed globally" {
  run bash -c "$NVM_INIT && npm ls -g --depth 0 '@styled/typescript-styled-plugin'"
  [ "$status" -eq 0 ]
}

@test "setup-nvm.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-nvm.sh
  [ "$status" -eq 0 ]
}

@test "nvm source is added exactly once to profile file" {
  local profile="$HOME/.bashrc"
  [ -f "$profile" ]
  count=$(grep -c 'export NVM_DIR=' "$profile" || true)
  [ "$count" -eq 1 ]
}

@test "_setup_shell_profile configures zsh and default profile paths" {
  source /setup/scripts/setup-nvm.sh
  local test_zsh_home="/tmp/test-zsh-home"
  local test_sh_home="/tmp/test-sh-home"
  mkdir -p "$test_zsh_home" "$test_sh_home"

  SHELL="/bin/zsh" HOME="$test_zsh_home" _setup_shell_profile
  [ -f "$test_zsh_home/.zshrc" ]
  grep -q 'NVM_DIR' "$test_zsh_home/.zshrc"

  SHELL="/bin/sh" HOME="$test_sh_home" _setup_shell_profile
  [ -f "$test_sh_home/.profile" ]
  grep -q 'NVM_DIR' "$test_sh_home/.profile"
}

@test "_install_nvm_script falls back to wget when curl is unavailable" {
  source /setup/scripts/setup-nvm.sh
  command() {
    if [ "$2" = "curl" ]; then return 1; fi
    builtin command "$@"
  }
  wget() {
    return 0
  }
  run _install_nvm_script
  [ "$status" -eq 0 ]
}

@test "_source_nvm returns error when nvm is not found" {
  source /setup/scripts/setup-nvm.sh
  HOME="/nonexistent" run _source_nvm
  [ "$status" -eq 1 ]
  [[ "$output" =~ "nvm not found" ]]
}

@test "_enable_corepack falls back to node when corepack command is absent" {
  source /setup/scripts/setup-nvm.sh
  command() {
    if [ "$2" = "corepack" ]; then return 1; fi
    builtin command "$@"
  }
  run _enable_corepack
  [ "$status" -eq 0 ]
}

@test "_install_corepack_packages handles empty package array" {
  source /setup/scripts/setup-nvm.sh
  COREPACK_PACKAGES=()
  run _install_corepack_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No corepack packages" ]]
}

@test "_install_npm_packages handles empty package array" {
  source /setup/scripts/setup-nvm.sh
  NPM_PACKAGES=()
  run _install_npm_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No global npm packages" ]]
}

@test "_install_nvm returns error on unsupported package manager" {
  source /setup/scripts/setup-nvm.sh
  _get_package_manager() { echo "unknown-pm"; }
  run _install_nvm
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}
