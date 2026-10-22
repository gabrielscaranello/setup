#!/usr/bin/env bats

# Integration tests for setup-gh.sh (runs across all distros)

@test "setup-gh.sh skips gracefully outside WSL by default" {
  run env WSL_DISTRO_NAME="" WSL_INTEROP_PATH="/nonexistent" PROC_VERSION_PATH="/nonexistent" \
    bash /setup/scripts/toolchain/setup-gh.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "restricted to WSL environments, skipping" ]]
}

@test "setup-gh.sh installs gh when running inside WSL" {
  run env WSL_DISTRO_NAME="test-wsl" bash /setup/scripts/toolchain/setup-gh.sh
  [ "$status" -eq 0 ]
  run bash -c "command -v gh && gh --version"
  [ "$status" -eq 0 ]
}

@test "setup-gh.sh is idempotent inside WSL (second run succeeds)" {
  run env WSL_DISTRO_NAME="test-wsl" bash /setup/scripts/toolchain/setup-gh.sh
  [ "$status" -eq 0 ]
}
