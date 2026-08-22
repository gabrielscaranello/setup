#!/usr/bin/env bats

# Integration tests for setup-rust.sh (runs identically across all distros)

CARGO_INIT="[ -s \"\$HOME/.cargo/env\" ] && . \"\$HOME/.cargo/env\""

setup_file() {
  source /setup/scripts/_utils.sh
  if [ "$(_get_package_manager)" != "apt" ]; then
    return 0
  fi
  bash /setup/scripts/setup-rust.sh
}

setup() {
  source /setup/scripts/_utils.sh
  if [ "$(_get_package_manager)" != "apt" ]; then
    skip "setup-rust.sh is exclusive to Debian"
  fi
}

@test "rustup is installed and responds to --version" {
  run bash -c "$CARGO_INIT && rustup --version"
  [ "$status" -eq 0 ]
}

@test "cargo is installed and responds to --version" {
  run bash -c "$CARGO_INIT && cargo --version"
  [ "$status" -eq 0 ]
}

@test "tree-sitter is installed and responds to --version" {
  run bash -c "$CARGO_INIT && tree-sitter --version"
  [ "$status" -eq 0 ]
}

@test "setup-rust.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-rust.sh
  [ "$status" -eq 0 ]
}

@test "cargo source is added exactly once to profile file" {
  local profile="$HOME/.bashrc"
  [ -f "$profile" ]
  count=$(grep -c 'cargo/env' "$profile" || true)
  [ "$count" -eq 1 ]
}
