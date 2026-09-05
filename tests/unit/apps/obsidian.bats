#!/usr/bin/env bats

# Unit tests for setup-obsidian.sh logic and branches

setup() {
  source /setup/scripts/apps/setup-obsidian.sh
}

@test "_install_obsidian fails when distribution is unsupported" {
  get_distro_id() { echo "unknown-distro"; return 1; }
  run _install_obsidian
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unsupported distribution" ]]
}

@test "_install_obsidian delegates to repo on arch" {
  get_distro_id() { echo "arch"; }
  install_packages() {
    echo "installed packages: $*"
    return 0
  }
  run _install_obsidian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed packages: obsidian" ]]
}

@test "_install_obsidian delegates to flatpak on fedora" {
  get_distro_id() { echo "fedora"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_obsidian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: md.obsidian.Obsidian Obsidian" ]]
}

@test "_install_obsidian delegates to flatpak on debian" {
  get_distro_id() { echo "debian"; }
  install_flatpak_app() {
    echo "installed flatpak: $*"
    return 0
  }
  run _install_obsidian
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: md.obsidian.Obsidian Obsidian" ]]
}
