#!/usr/bin/env bats

# Integration tests for setup-neovim.sh on Debian.
# NOTE: setup_file() triggers a full source build — this test is intentionally slow.

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
