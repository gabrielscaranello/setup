#!/usr/bin/env bats
# shellcheck disable=SC2218

# Unit tests for setup-discord.sh logic and branches

setup() {
  source /setup/scripts/setup-discord.sh
}

@test "_install_discord_flatpak skips when already installed" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo "com.discordapp.Discord"
      return 0
    fi
    return 1
  }
  run _install_discord_flatpak
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ installed,\ skipping ]]
}

@test "_install_discord_flatpak installs via flatpak when not present" {
  flatpak() {
    if [ "$1" = "list" ]; then
      echo ""
      return 0
    fi
    if [ "$1" = "install" ]; then
      echo "flatpak installed: $*"
      return 0
    fi
    return 1
  }
  sudo() {
    "$@"
  }
  run _install_discord_flatpak
  [ "$status" -eq 0 ]
  [[ "$output" =~ Discord\ Flatpak\ installed\ successfully ]]
}

@test "_install_discord_repo calls install_packages discord" {
  install_packages() {
    echo "installed: $*"
    return 0
  }
  run _install_discord_repo
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed:\ discord ]]
}

@test "_install_discord fails when distribution is unsupported" {
  _get_package_manager() { echo "unknown-pm"; }
  run _install_discord
  [ "$status" -eq 1 ]
  [[ "$output" =~ Unsupported\ package\ manager ]]
}

@test "_install_discord delegates to repo on pacman" {
  _get_package_manager() { echo "pacman"; }
  _install_discord_repo() {
    echo "installed from pacman"
    return 0
  }
  run _install_discord
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ pacman ]]
}

@test "_install_discord delegates to flatpak on apt and dnf" {
  _get_package_manager() { echo "apt"; }
  _install_discord_flatpak() {
    echo "installed from flatpak apt"
    return 0
  }
  run _install_discord
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ flatpak\ apt ]]

  _get_package_manager() { echo "dnf"; }
  _install_discord_flatpak() {
    echo "installed from flatpak dnf"
    return 0
  }
  run _install_discord
  [ "$status" -eq 0 ]
  [[ "$output" =~ installed\ from\ flatpak\ dnf ]]
}
