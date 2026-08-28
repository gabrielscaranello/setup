#!/usr/bin/env bats

# Unit tests for setup-nvm.sh logic and branches

@test "_setup_shell_profile configures zsh and default profile paths" {
  source /setup/scripts/toolchain/setup-nvm.sh
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
  source /setup/scripts/toolchain/setup-nvm.sh
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
  source /setup/scripts/toolchain/setup-nvm.sh
  HOME="/nonexistent" run _source_nvm
  [ "$status" -eq 1 ]
  [[ "$output" =~ "nvm not found" ]]
}

@test "_enable_corepack falls back to node when corepack command is absent" {
  source /setup/scripts/toolchain/setup-nvm.sh
  command() {
    if [ "${2:-}" = "corepack" ]; then return 1; fi
    builtin command "$@"
  }
  node() {
    return 0
  }
  run _enable_corepack
  [ "$status" -eq 0 ]
}

@test "_install_corepack_packages handles empty package array" {
  source /setup/scripts/toolchain/setup-nvm.sh
  COREPACK_PACKAGES=()
  run _install_corepack_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No corepack packages" ]]
}

@test "_install_npm_packages handles empty package array" {
  source /setup/scripts/toolchain/setup-nvm.sh
  NPM_PACKAGES=()
  run _install_npm_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No global npm packages" ]]
}

@test "_install_nvm returns error on unsupported package manager" {
  source /setup/scripts/toolchain/setup-nvm.sh
  _get_package_manager() { echo "unknown-pm"; }
  run _install_nvm
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}
