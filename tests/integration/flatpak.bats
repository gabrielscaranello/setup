#!/usr/bin/env bats

# Integration tests for setup-flatpak.sh (runs across all distros)

setup_file() {
  bash /setup/scripts/setup-flatpak.sh
}

@test "flatpak command is available and responds to version" {
  run flatpak --version
  [ "$status" -eq 0 ]
}

@test "flathub remote repository is configured" {
  run flatpak remotes --columns=name
  [ "$status" -eq 0 ]
  [[ "$output" =~ flathub ]]
}

@test "setup-flatpak.sh is idempotent (second run succeeds)" {
  run bash /setup/scripts/setup-flatpak.sh
  [ "$status" -eq 0 ]
}
