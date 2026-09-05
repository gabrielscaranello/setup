#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-discord.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-discord.sh
}

@test "_install_discord fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_discord
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ distribution ]]
}

@test "_install_discord delegates to repo on arch" {
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_discord
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ packages:\ discord ]]
}

@test "_install_discord delegates to flatpak on debian and fedora" {
  get_distro_id() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_discord
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ com.discordapp.Discord\ Discord ]]

  get_distro_id() { echo "fedora"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_discord
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ flatpak:\ com.discordapp.Discord\ Discord ]]
}
