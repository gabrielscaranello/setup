#!/usr/bin/env bats

# Unit tests for setup-neovim.sh logic and branches

@test "_install_neovim fails when package manager is unknown" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _install_build_deps() { return 0; }
  run _install_neovim "unknown-pm"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "_install_neovim_from_source handles git clone failure" {
  source /setup/scripts/toolchain/setup-neovim.sh
  git() { return 1; }
  run _install_neovim_from_source
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to clone Neovim repository" ]]
}

@test "_install_neovim_from_source handles build failure" {
  source /setup/scripts/toolchain/setup-neovim.sh
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
  source /setup/scripts/toolchain/setup-neovim.sh
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
  source /setup/scripts/toolchain/setup-neovim.sh
  git() {
    mkdir -p /tmp/neovim/build
    return 0
  }
  make() { return 0; }
  cpack() {
    touch /tmp/neovim/build/nvim-linux64.deb
    return 0
  }
  dpkg() { return 1; }
  sudo() {
    if [ "${1:-}" = "dpkg" ]; then
      return 1
    fi
    "$@"
  }
  run _install_neovim_from_source
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to install DEB package" ]]
}

@test "_install_runtime_deps installs common and debian specific dependencies on apt" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "apt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "luarocks python3 python-venv" ]]
}

@test "_install_runtime_deps installs common and fedora specific dependencies on dnf" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "dnf"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "luarocks cargo lua-5.1" ]]
}

@test "_install_runtime_deps installs common and arch specific dependencies on pacman" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "pacman"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "build-tools rust tree-sitter-cli luarocks" ]]
}

@test "main executes _ensure_nvm, _ensure_go, _install_runtime_deps and _install_neovim in order" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _get_package_manager() { echo "dnf"; }
  _ensure_nvm() { echo "step: ensure_nvm"; }
  _ensure_go() { echo "step: ensure_go"; }
  _install_runtime_deps() { echo "step: install_runtime_deps for $1"; }
  _install_neovim() { echo "step: install_neovim for $1"; }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: ensure_nvm" ]]
  [[ "$output" =~ "step: ensure_go" ]]
  [[ "$output" =~ "step: install_runtime_deps for dnf" ]]
  [[ "$output" =~ "step: install_neovim for dnf" ]]
}

@test "main fails when distribution detection fails" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _get_package_manager() { return 1; }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}
