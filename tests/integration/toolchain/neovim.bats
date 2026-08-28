#!/usr/bin/env bats

# Integration tests for setup-neovim.sh (runs across all supported distros)

setup_file() {
  bash /setup/scripts/toolchain/setup-neovim.sh
}

@test "nvim is installed and responds to --version" {
  run nvim --version
  [ "$status" -eq 0 ]
}

@test "setup-neovim.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/toolchain/setup-neovim.sh
  [ "$status" -eq 0 ]
}
