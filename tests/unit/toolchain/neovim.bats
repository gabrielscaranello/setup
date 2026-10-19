#!/usr/bin/env bats

# Unit tests for setup-neovim.sh logic and branches

@test "_install_neovim fails when distribution is unknown" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _install_build_deps() { return 0; }
  run _install_neovim "unknown-distro"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
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

@test "_install_runtime_deps installs common and debian specific dependencies on debian" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "luarocks python3 python-venv" ]]
}

@test "_install_neovim builds from source on debian" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _ensure_rust() { echo "step: ensure_rust"; }
  _install_build_deps() { echo "step: install_build_deps"; }
  _install_neovim_from_source() { echo "step: install_neovim_from_source"; }
  run _install_neovim "debian"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: ensure_rust" ]]
  [[ "$output" =~ "step: install_build_deps" ]]
  [[ "$output" =~ "step: install_neovim_from_source" ]]
}

@test "_install_runtime_deps installs common and fedora specific dependencies on fedora" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "fedora"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "luarocks cargo lua-5.1" ]]
}

@test "_install_runtime_deps installs common and arch specific dependencies on arch" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "arch"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "build-tools rust tree-sitter-cli luarocks" ]]
}

@test "main executes _ensure_nvm, _ensure_go, _ensure_rust, _install_runtime_deps and _install_neovim in order" {
  source /setup/scripts/toolchain/setup-neovim.sh
  get_distro_id() { echo "fedora"; }
  _ensure_nvm() { echo "step: ensure_nvm"; }
  _ensure_go() { echo "step: ensure_go"; }
  _ensure_rust() { echo "step: ensure_rust"; }
  _install_runtime_deps() { echo "step: install_runtime_deps for $1"; }
  _install_neovim() { echo "step: install_neovim for $1"; }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: ensure_nvm" ]]
  [[ "$output" =~ "step: ensure_go" ]]
  [[ "$output" =~ "step: ensure_rust" ]]
  [[ "$output" =~ "step: install_runtime_deps for fedora" ]]
  [[ "$output" =~ "step: install_neovim for fedora" ]]
}

@test "main fails when distribution detection fails" {
  source /setup/scripts/toolchain/setup-neovim.sh
  get_distro_id() { return 1; }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_clone_neovim_source invokes git clone with stable branch" {
  source /setup/scripts/toolchain/setup-neovim.sh
  git() { echo "git: $*"; return 0; }
  run _clone_neovim_source "/tmp/test_nvim"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "git: clone --depth 1 -b stable" ]]
}

@test "_build_neovim_source executes make with RelWithDebInfo" {
  source /setup/scripts/toolchain/setup-neovim.sh
  mkdir -p /tmp/test_nvim_build
  make() { echo "make: $*"; return 0; }
  run _build_neovim_source "/tmp/test_nvim_build"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "make: -j" ]]
  [[ "$output" =~ "CMAKE_BUILD_TYPE=RelWithDebInfo" ]]
  rm -rf /tmp/test_nvim_build
}

@test "_package_and_install_neovim_deb executes cpack and dpkg" {
  source /setup/scripts/toolchain/setup-neovim.sh
  mkdir -p /tmp/test_nvim_deb/build
  cpack() { echo "cpack: $*"; return 0; }
  sudo() { echo "sudo: $*"; return 0; }
  run _package_and_install_neovim_deb "/tmp/test_nvim_deb"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "cpack: -G DEB" ]]
  [[ "$output" =~ "sudo: dpkg -i" ]]
  rm -rf /tmp/test_nvim_deb
}

@test "_install_neovim_make executes sudo make install" {
  source /setup/scripts/toolchain/setup-neovim.sh
  mkdir -p /tmp/test_nvim_make
  sudo() { echo "sudo: $*"; return 0; }
  run _install_neovim_make "/tmp/test_nvim_make"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "sudo: make install" ]]
  rm -rf /tmp/test_nvim_make
}

@test "_install_neovim_make handles sudo make install failure" {
  source /setup/scripts/toolchain/setup-neovim.sh
  mkdir -p /tmp/test_nvim_make
  sudo() { return 1; }
  run _install_neovim_make "/tmp/test_nvim_make"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Failed to install Neovim" ]]
  rm -rf /tmp/test_nvim_make
}

@test "_install_neovim_from_source handles unknown method failure" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _clone_neovim_source() { return 0; }
  _build_neovim_source() { return 0; }
  run _install_neovim_from_source "invalid-method"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported source installation method: invalid-method" ]]
}

@test "_install_neovim installs from repo on opensuse-tumbleweed" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() { echo "installing: $*"; return 0; }
  run _install_neovim "opensuse-tumbleweed"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Neovim from distribution repository..." ]]
  [[ "$output" =~ "installing: neovim" ]]
}

@test "_install_neovim builds from source on opensuse-leap" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _ensure_rust() { echo "step: ensure_rust"; }
  _install_build_deps() { echo "step: install_build_deps"; }
  _install_neovim_from_source() { echo "step: install_neovim_from_source with method $1"; }
  run _install_neovim "opensuse-leap"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: ensure_rust" ]]
  [[ "$output" =~ "step: install_build_deps" ]]
  [[ "$output" =~ "step: install_neovim_from_source with method make" ]]
}

@test "_install_neovim builds from source on opensuse" {
  source /setup/scripts/toolchain/setup-neovim.sh
  _ensure_rust() { echo "step: ensure_rust"; }
  _install_build_deps() { echo "step: install_build_deps"; }
  _install_neovim_from_source() { echo "step: install_neovim_from_source with method $1"; }
  run _install_neovim "opensuse"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "step: ensure_rust" ]]
  [[ "$output" =~ "step: install_build_deps" ]]
  [[ "$output" =~ "step: install_neovim_from_source with method make" ]]
}

@test "_install_runtime_deps installs common and opensuse specific dependencies on opensuse" {
  source /setup/scripts/toolchain/setup-neovim.sh
  install_packages() {
    echo "installing packages: $*"
    return 0
  }
  run _install_runtime_deps "opensuse-tumbleweed"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq ripgrep fd-find clipboard imagemagick sqlite tidy protobuf-compiler unzip" ]]
  [[ "$output" =~ "luarocks python3 lua54-devel build-tools" ]]
}

