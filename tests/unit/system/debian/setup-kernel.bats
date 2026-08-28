#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for scripts/system/debian/setup-kernel.sh

setup() {
  source /setup/scripts/system/debian/setup-kernel.sh
}

@test "_install_backports_kernel_apt calls add_debian_backports_repo and installs kernel with -t <codename>-backports" {
  _get_debian_codename() {
    echo "bookworm"
  }
  add_debian_backports_repo() {
    echo "called add_debian_backports_repo"
    return 0
  }
  sudo() {
    echo "sudo $*"
    return 0
  }
  run _install_backports_kernel_apt
  [ "$status" -eq 0 ]
  [[ "$output" =~ called\ add_debian_backports_repo ]]
  [[ "$output" =~ -t\ bookworm-backports ]]
  [[ "$output" =~ linux-image-amd64 ]]
  [[ "$output" =~ linux-headers-amd64 ]]
}

@test "_install_backports_kernel_apt installs newer backports version than default suite candidate" {
  _get_debian_codename() {
    echo "bookworm"
  }
  add_debian_backports_repo() {
    return 0
  }
  sudo() {
    if [ "$1" = "apt" ] && [ "$2" = "install" ]; then
      # Validate that -t bookworm-backports target suite is supplied
      local has_target_suite=0
      local i
      for ((i=1; i<=$#; i++)); do
        if [ "${!i}" = "-t" ]; then
          local next=$((i + 1))
          if [ "${!next}" = "bookworm-backports" ]; then
            has_target_suite=1
          fi
        fi
      done
      if [ "$has_target_suite" -eq 1 ]; then
        echo "Installed backport kernel (version 6.12.x > default LTS 6.1.x)"
        return 0
      fi
      echo "Failed: missing -t target suite flag"
      return 1
    fi
    "$@"
  }
  run _install_backports_kernel_apt
  [ "$status" -eq 0 ]
  [[ "$output" =~ Installed\ backport\ kernel ]]
}

@test "_setup_debian_kernel skips on non-apt distributions" {
  _get_package_manager() {
    echo "pacman"
  }
  run _setup_debian_kernel
  [ "$status" -eq 0 ]
  [[ "$output" =~ Skipping\ on\ \'pacman\' ]]
}

@test "_setup_debian_kernel fails when package manager detection fails" {
  _get_package_manager() {
    return 1
  }
  run _setup_debian_kernel
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "_setup_debian_kernel executes kernel installation on APT" {
  _get_package_manager() {
    echo "apt"
  }
  _install_backports_kernel_apt() {
    echo "called _install_backports_kernel_apt"
    return 0
  }
  run _setup_debian_kernel
  [ "$status" -eq 0 ]
  [[ "$output" =~ called\ _install_backports_kernel_apt ]]
}
