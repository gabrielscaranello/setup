#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-gh.sh logic and branches

@test "_install_gh skips when not running in WSL" {
  source /setup/scripts/toolchain/setup-gh.sh
  is_wsl() { return 1; }
  run _install_gh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "restricted to WSL environments, skipping" ]]
}

@test "_install_gh fails when distribution is unsupported inside WSL" {
  source /setup/scripts/toolchain/setup-gh.sh
  is_wsl() { return 0; }
  get_distro_id() {
    echo "unknown-distro"
    return 1
  }
  run _install_gh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_gh installs github-cli on supported distributions inside WSL" {
  source /setup/scripts/toolchain/setup-gh.sh
  is_wsl() { return 0; }
  install_packages() {
    echo "installed: $*"
    return 0
  }

  for distro in debian fedora arch opensuse-leap opensuse-tumbleweed; do
    require_supported_distro() { echo "$distro"; }
    run _install_gh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "installed: github-cli" ]]
  done
}

@test "main executes _install_gh and outputs completion message" {
  source /setup/scripts/toolchain/setup-gh.sh
  _install_gh() {
    echo "called _install_gh"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up GitHub CLI..." ]]
  [[ "$output" =~ "called _install_gh" ]]
  [[ "$output" =~ "setup-gh complete" ]]
}
