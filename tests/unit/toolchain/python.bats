#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-python.sh logic and branches

@test "_install_python fails when distribution is unsupported" {
  source /setup/scripts/toolchain/setup-python.sh
  get_distro_id() {
    echo "unknown-distro"
    return 1
  }
  run _install_python
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_python installs python3, python-pip and python-venv on supported distributions" {
  source /setup/scripts/toolchain/setup-python.sh
  install_packages() {
    echo "installed: $*"
    return 0
  }

  for distro in debian fedora arch opensuse-leap opensuse-tumbleweed; do
    require_supported_distro() { echo "$distro"; }
    run _install_python
    [ "$status" -eq 0 ]
    [[ "$output" =~ "installed: python3 python-pip python-venv" ]]
  done
}

@test "main executes _install_python and outputs completion message" {
  source /setup/scripts/toolchain/setup-python.sh
  _install_python() {
    echo "called _install_python"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Setting up Python..." ]]
  [[ "$output" =~ "called _install_python" ]]
  [[ "$output" =~ "setup-python complete" ]]
}
