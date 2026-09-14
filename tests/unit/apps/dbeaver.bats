#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-dbeaver.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-dbeaver.sh
}

@test "main fails when distribution is unsupported" {
  require_supported_distro() { echo "Unsupported distribution" >&2; return 1; }
  run main
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "main installs DBeaver via flatpak on any supported distro" {
  require_supported_distro() { echo "arch"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ io.dbeaver.DBeaverCommunity\ DBeaver ]]

  require_supported_distro() { echo "debian"; }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ io.dbeaver.DBeaverCommunity\ DBeaver ]]

  require_supported_distro() { echo "fedora"; }
  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ io.dbeaver.DBeaverCommunity\ DBeaver ]]
}
