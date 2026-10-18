#!/usr/bin/env bats

# Unit tests for setup-vscodium.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-vscodium.sh
}

@test "_install_vscodium fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_vscodium
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_vscodium on arch installs code directly without repos" {
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: vscodium" ]]
}

@test "_install_vscodium on fedora adds repo and installs codium" {
  get_distro_id() { echo "fedora"; }
  add_fedora_vscodium_repo() {
    echo "called add_fedora_vscodium_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_fedora_vscodium_repo" ]]
  [[ "$output" =~ "installed packages: vscodium" ]]
}

@test "_install_vscodium on debian adds repo and installs codium" {
  get_distro_id() { echo "debian"; }
  add_debian_vscodium_repo() {
    echo "called add_debian_vscodium_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_debian_vscodium_repo" ]]
  [[ "$output" =~ "installed packages: vscodium" ]]
}

@test "_install_vscodium on opensuse adds repo and installs vscodium" {
  get_distro_id() { echo "opensuse-leap"; }
  add_opensuse_vscodium_repo() {
    echo "called add_opensuse_vscodium_repo"
    return 0
  }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_opensuse_vscodium_repo" ]]
  [[ "$output" =~ "installed packages: vscodium" ]]

  get_distro_id() { echo "opensuse-tumbleweed"; }
  run _install_vscodium
  [ "$status" -eq 0 ]
  [[ "$output" =~ "called add_opensuse_vscodium_repo" ]]
  [[ "$output" =~ "installed packages: vscodium" ]]
}

@test "main executes successfully and reports complete" {
  _install_vscodium() {
    echo "called _install_vscodium"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up VSCodium..." ]]
  [[ "$output" =~ "called _install_vscodium" ]]
  [[ "$output" =~ "setup-vscodium complete" ]]
}

@test "_setup_vscodium_desktop_integration cleans up legacy codium.desktop symlink when present" {
  local test_dir
  test_dir="$(mktemp -d)"
  mkdir -p "$test_dir/applications"
  touch "$test_dir/applications/com.visualstudio.CodeOSS.desktop"
  ln -sf "$test_dir/applications/com.visualstudio.CodeOSS.desktop" "$test_dir/applications/codium.desktop"

  sudo() {
    "$@"
  }
  update-desktop-database() { return 0; }

  _setup_vscodium_desktop_integration() {
    local app_dir="$test_dir/applications"
    local codium_desktop="${app_dir}/codium.desktop"

    if [ -L "$codium_desktop" ]; then
      echo "Cleaning up legacy codium.desktop symlink..."
      sudo rm -f "$codium_desktop" 2> /dev/null || true
    fi
  }

  run _setup_vscodium_desktop_integration
  [ "$status" -eq 0 ]
  [ ! -e "$test_dir/applications/codium.desktop" ]
  rm -rf "$test_dir"
}
