#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-rust.sh logic and branches

@test "_setup_shell_profile configures zsh and default profile paths for cargo" {
  source /setup/scripts/toolchain/setup-rust.sh
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
  source /setup/scripts/toolchain/setup-rust.sh
  command() {
    if [ "${2:-}" = "rustup" ]; then return 0; fi
    builtin command "$@"
  }
  run _install_rustup
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Rustup is already installed" ]]
}

@test "_install_rustup installs via curl when available" {
  source /setup/scripts/toolchain/setup-rust.sh
  local marker="$BATS_TMPDIR/curl_called_$$"
  rm -f "$marker"
  command() {
    if [ "${2:-}" = "rustup" ]; then return 1; fi
    if [ "${2:-}" = "curl" ]; then return 0; fi
    builtin command "$@"
  }
  curl() {
    touch "$marker"
    echo "true"
  }
  run _install_rustup
  [ "$status" -eq 0 ]
  [ -f "$marker" ]
  rm -f "$marker"
}

@test "_install_rustup falls back to wget when curl is unavailable" {
  source /setup/scripts/toolchain/setup-rust.sh
  local marker="$BATS_TMPDIR/wget_called_$$"
  rm -f "$marker"
  command() {
    if [ "${2:-}" = "rustup" ]; then return 1; fi
    if [ "${2:-}" = "curl" ]; then return 1; fi
    if [ "${2:-}" = "wget" ]; then return 0; fi
    builtin command "$@"
  }
  wget() {
    touch "$marker"
    echo "true"
  }
  run _install_rustup
  [ "$status" -eq 0 ]
  [ -f "$marker" ]
  rm -f "$marker"
}

@test "_source_cargo succeeds when cargo command exists without ~/.cargo/env" {
  source /setup/scripts/toolchain/setup-rust.sh
  command() {
    if [ "${2:-}" = "cargo" ]; then return 0; fi
    builtin command "$@"
  }
  HOME="/nonexistent" run _source_cargo
  [ "$status" -eq 0 ]
}

@test "_source_cargo returns error when cargo environment is not found" {
  source /setup/scripts/toolchain/setup-rust.sh
  command() {
    if [ "${2:-}" = "cargo" ]; then return 1; fi
    builtin command "$@"
  }
  HOME="/nonexistent" run _source_cargo
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Cargo environment not found" ]]
}

@test "_install_cargo_packages handles empty package array" {
  source /setup/scripts/toolchain/setup-rust.sh
  CARGO_PACKAGES=()
  run _install_cargo_packages
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No cargo packages" ]]
}

@test "_install_cargo_packages skips already installed package" {
  source /setup/scripts/toolchain/setup-rust.sh
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

@test "_install_rust installs packages from repo on opensuse-tumbleweed" {
  source /setup/scripts/toolchain/setup-rust.sh
  require_supported_distro() { echo "opensuse-tumbleweed"; }
  install_packages() {
    echo "installed: $*"
    return 0
  }
  _setup_shell_profile() { echo "called _setup_shell_profile"; }
  _source_cargo() { return 0; }
  _install_cargo_packages() { echo "called _install_cargo_packages"; }

  run _install_rust
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed: rust cargo libclang" ]]
  [[ "$output" =~ "called _setup_shell_profile" ]]
  [[ "$output" =~ "called _install_cargo_packages" ]]
}

@test "_install_rust invokes rustup flow on other distros" {
  source /setup/scripts/toolchain/setup-rust.sh
  require_supported_distro() { echo "opensuse-leap"; }
  install_packages() { return 0; }
  _install_rustup() { echo "called _install_rustup"; }
  _setup_shell_profile() { echo "called _setup_shell_profile"; }
  _source_cargo() { return 0; }
  _install_cargo_packages() { echo "called _install_cargo_packages"; }

  run _install_rust
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called _install_rustup" ]]
  [[ "$output" =~ "called _install_cargo_packages" ]]
}

@test "_install_rust fails when distribution is unsupported" {
  source /setup/scripts/toolchain/setup-rust.sh
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_rust
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}
