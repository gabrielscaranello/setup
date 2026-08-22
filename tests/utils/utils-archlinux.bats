#!/usr/bin/env bats

# Unit tests for _utils.sh functions and mappings

setup() {
  source /setup/scripts/_utils.sh
}

@test "_get_package_name resolves build-tools for all managers" {
  [ "$(_get_package_name "build-tools" "apt")" = "build-essential" ]
  [ "$(_get_package_name "build-tools" "dnf")" = "@development-tools" ]
  [ "$(_get_package_name "build-tools" "pacman")" = "base-devel" ]
}

@test "_get_package_name resolves ninja-build for all managers" {
  [ "$(_get_package_name "ninja-build" "pacman")" = "ninja" ]
  [ "$(_get_package_name "ninja-build" "apt")" = "ninja-build" ]
  [ "$(_get_package_name "ninja-build" "dnf")" = "ninja-build" ]
}

@test "_get_package_name resolves gcc-cxx for all managers" {
  [ "$(_get_package_name "gcc-cxx" "apt")" = "g++" ]
  [ "$(_get_package_name "gcc-cxx" "dnf")" = "gcc-c++" ]
  [ "$(_get_package_name "gcc-cxx" "pacman")" = "gcc" ]
}

@test "_get_package_name resolves gettext-tools for all managers" {
  [ "$(_get_package_name "gettext-tools" "dnf")" = "gettext-devel" ]
  [ "$(_get_package_name "gettext-tools" "apt")" = "gettext" ]
  [ "$(_get_package_name "gettext-tools" "pacman")" = "gettext" ]
}

@test "_get_package_name returns unmapped package as-is" {
  [ "$(_get_package_name "curl" "pacman")" = "curl" ]
}

@test "_get_package_manager detects current package manager" {
  run _get_package_manager
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "_get_package_manager returns error when no package manager found" {
  run bash -c "PATH=/empty; source /setup/scripts/_utils.sh; _get_package_manager"
  [ "$status" -eq 1 ]
}

@test "_install_package_from_repository returns error for unsupported manager" {
  run _install_package_from_repository "unknown-pm" "dummy"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported package manager" ]]
}

@test "install_packages fails when distribution is unsupported" {
  _get_package_manager() { return 1; }
  run install_packages "curl"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}
