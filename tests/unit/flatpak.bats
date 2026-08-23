#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-flatpak.sh logic and branches

setup() {
  source /setup/scripts/setup-flatpak.sh
}

@test "_install_flatpak_package calls install_packages flatpak" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_flatpak_package
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ flatpak ]]
}

@test "_add_flathub_remote skips when flathub is already in remotes" {
  flatpak() {
    if [ "$1" = "remotes" ]; then
      echo "flathub"
      return 0
    fi
    return 1
  }
  run _add_flathub_remote
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ configured ]]
}

@test "_add_flathub_remote adds flathub when not present" {
  flatpak() {
    if [ "$1" = "remotes" ]; then
      echo ""
      return 0
    fi
    if [ "$1" = "remote-add" ]; then
      echo "remote added: $*"
      return 0
    fi
    return 1
  }
  sudo() {
    "$@"
  }
  run _add_flathub_remote
  [ "$status" -eq 0 ]
  [[ "$output" =~ Flathub\ remote\ repository\ added\ successfully ]]
}

@test "_setup_flatpak calls install and remote configuration" {
  _install_flatpak_package() {
    echo "called install"
    return 0
  }
  _add_flathub_remote() {
    echo "called remote"
    return 0
  }
  run _setup_flatpak
  [ "$status" -eq 0 ]
  [[ "$output" =~ called\ install ]]
  [[ "$output" =~ called\ remote ]]
}
