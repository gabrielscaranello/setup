#!/usr/bin/env bats

# Integration tests for setup-gh.sh

@test "setup-gh.sh skips gracefully outside WSL by default" {
  run env WSL_DISTRO_NAME="" WSL_INTEROP_PATH="/nonexistent" PROC_VERSION_PATH="/nonexistent" \
    bash /setup/scripts/toolchain/setup-gh.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "restricted to WSL environments, skipping" ]]
}

@test "setup-gh.sh installs gh on Debian inside WSL and rejects non-Debian" {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id)" != "debian" ]; then
    run env WSL_DISTRO_NAME="test-wsl" bash /setup/scripts/toolchain/setup-gh.sh
    [ "$status" -eq 1 ]
    [[ "$output" =~ "only supported on Debian" ]]
    return 0
  fi

  run env WSL_DISTRO_NAME="test-wsl" bash /setup/scripts/toolchain/setup-gh.sh
  [ "$status" -eq 0 ]
  run bash -c "command -v gh && gh --version"
  [ "$status" -eq 0 ]
}

@test "setup-gh.sh is idempotent on Debian inside WSL (second run succeeds)" {
  source /setup/scripts/_utils.sh
  if [ "$(get_distro_id)" != "debian" ]; then
    skip "Test only runs on Debian"
  fi
  run env WSL_DISTRO_NAME="test-wsl" bash /setup/scripts/toolchain/setup-gh.sh
  [ "$status" -eq 0 ]
}
