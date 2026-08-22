#!/usr/bin/env bats

# Unit tests for setup-rust.sh logic and branches

@test "_setup_shell_profile configures zsh and default profile paths for cargo" {
  source /setup/scripts/setup-rust.sh
  local test_zsh_home="/tmp/test-zsh-home"
  local test_sh_home="/tmp/test-sh-home"
  mkdir -p "$test_zsh_home" "$test_sh_home"

  SHELL="/bin/zsh" HOME="$test_zsh_home" _setup_shell_profile
  [ -f "$test_zsh_home/.zshrc" ]
  grep -q 'cargo/env' "$test_zsh_home/.zshrc"

  SHELL="/bin/sh" HOME="$test_sh_home" _setup_shell_profile
  [ -f "$test_sh_home/.profile" ]
  grep -q 'cargo/env' "$test_sh_home/.profile"
}

@test "_install_rustup skips installation when rustup is already present" {
  source /setup/scripts/setup-rust.sh
  command() {
    if [ "${2:-}" = "rustup" ]; then return 0; fi
    builtin command "$@"
  }
  run _install_rustup
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Rustup is already installed" ]]
}

@test "_source_cargo succeeds when cargo command exists without ~/.cargo/env" {
  source /setup/scripts/setup-rust.sh
  command() {
    if [ "${2:-}" = "cargo" ]; then return 0; fi
    builtin command "$@"
  }
  HOME="/nonexistent" run _source_cargo
  [ "$status" -eq 0 ]
}

@test "_source_cargo returns error when cargo environment is not found" {
  source /setup/scripts/setup-rust.sh
  command() {
    if [ "${2:-}" = "cargo" ]; then return 1; fi
    builtin command "$@"
  }
  HOME="/nonexistent" run _source_cargo
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Cargo environment not found" ]]
}

@test "_install_cargo_packages handles empty package array" {
  source /setup/scripts/setup-rust.sh
  CARGO_PACKAGES=()
  run _install_cargo_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No cargo packages" ]]
}

@test "_install_cargo_packages skips already installed package" {
  source /setup/scripts/setup-rust.sh
  cargo() {
    if [ "$1" = "install" ] && [ "$2" = "--list" ]; then
      echo "tree-sitter-cli v0.24.0:"
      return 0
    fi
    return 0
  }
  CARGO_PACKAGES=("tree-sitter-cli")
  run _install_cargo_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already installed, skipping" ]]
}
