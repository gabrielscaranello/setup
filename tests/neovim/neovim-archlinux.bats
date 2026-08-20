#!/usr/bin/env bats

# Integration tests for setup-neovim.sh on Arch Linux.

setup_file() {
  bash /setup/scripts/setup-neovim.sh
}

@test "nvim is installed and responds to --version" {
  run nvim --version
  [ "$status" -eq 0 ]
}

@test "setup-neovim.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-neovim.sh
  [ "$status" -eq 0 ]
}
