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

@test "setup-neovim.sh is idempotent (install succeeds without re-building)" {
  source /setup/scripts/setup-neovim.sh
  _install_neovim_from_source() {
    return 0
  }
  _ensure_nvm() { return 0; }
  _install_build_deps() { return 0; }
  run main
  [ "$status" -eq 0 ]
}

@test "_install_neovim fails when distribution detection fails" {
  source /setup/scripts/setup-neovim.sh
  _install_build_deps() { return 0; }
  _get_package_manager() { return 1; }
  run _install_neovim
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_neovim fails when package manager is unknown" {
  source /setup/scripts/setup-neovim.sh
  _install_build_deps() { return 0; }
  _get_package_manager() { echo "unknown-pm"; }
  run _install_neovim
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_neovim_from_source handles git clone failure" {
  source /setup/scripts/setup-neovim.sh
  git() { return 1; }
  run _install_neovim_from_source
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to clone Neovim repository" ]]
}

@test "_install_neovim_from_source handles build failure" {
  source /setup/scripts/setup-neovim.sh
  git() {
    mkdir -p /tmp/neovim
    return 0
  }
  make() { return 1; }
  run _install_neovim_from_source
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to build Neovim" ]]
}

@test "_install_neovim_from_source handles cpack failure" {
  source /setup/scripts/setup-neovim.sh
  git() {
    mkdir -p /tmp/neovim/build
    return 0
  }
  make() { return 0; }
  cpack() { return 1; }
  run _install_neovim_from_source
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to create DEB package" ]]
}

@test "_install_neovim_from_source handles dpkg failure" {
  source /setup/scripts/setup-neovim.sh
  git() {
    mkdir -p /tmp/neovim/build
    touch /tmp/neovim/build/nvim-linux-test.deb
    return 0
  }
  make() { return 0; }
  cpack() { return 0; }
  sudo() {
    if [ "${1:-}" = "dpkg" ]; then
      return 1
    fi
    command sudo "$@"
  }
  run _install_neovim_from_source
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to install DEB package" ]]
}
