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
  HOME="/nonexistent" XDG_CONFIG_HOME="/nonexistent" NVM_DIR="" run _source_nvm
  [ "$status" -eq 1 ]
  [[ "$output" =~ "nvm not found" ]]
}

@test "_source_nvm sources nvm from ~/.config/nvm when present" {
  source /setup/scripts/toolchain/setup-nvm.sh
  local test_home="/tmp/test-nvm-config-home"
  mkdir -p "$test_home/.config/nvm"
  echo "nvm() { echo 'mock-nvm-xdg'; }" > "$test_home/.config/nvm/nvm.sh"

  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" NVM_DIR="" run _source_nvm
  [ "$status" -eq 0 ]
  rm -rf "$test_home"
}

@test "_resolve_nvm_dir prioritizes existing ~/.config/nvm" {
  source /setup/scripts/toolchain/setup-nvm.sh
  local test_home="/tmp/test-nvm-resolve-home"
  mkdir -p "$test_home/.config/nvm"
  touch "$test_home/.config/nvm/nvm.sh"

  local resolved
  resolved="$(HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" NVM_DIR="" _resolve_nvm_dir)"
  [ "$resolved" = "$test_home/.config/nvm" ]
  rm -rf "$test_home"
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

@test "_install_nvm calls _install_nvm_script on debian" {
  source /setup/scripts/toolchain/setup-nvm.sh
  require_supported_distro() { echo "debian"; }
  _install_nvm_script() { echo "called _install_nvm_script"; }
  run _install_nvm
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_nvm_script" ]]
}

@test "_install_nvm calls _install_nvm_script on opensuse" {
  source /setup/scripts/toolchain/setup-nvm.sh
  require_supported_distro() { echo "opensuse-leap"; }
  _install_nvm_script() { echo "called _install_nvm_script"; }
  run _install_nvm
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_nvm_script" ]]

  require_supported_distro() { echo "opensuse-tumbleweed"; }
  run _install_nvm
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_nvm_script" ]]
}

@test "_install_nvm returns error on unsupported distribution" {
  source /setup/scripts/toolchain/setup-nvm.sh
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run _install_nvm
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}
