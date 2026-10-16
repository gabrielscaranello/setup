#!/usr/bin/env bats

# Integration tests for setup-screenshot-tool.sh (runs across all distros)

setup_file() {
  export XDG_CURRENT_DESKTOP="GNOME"
  bash /setup/scripts/apps/setup-screenshot-tool.sh
}

@test "screenshot tool is installed on GNOME (Flameshot)" {
  command -v flameshot >/dev/null 2>&1
}

@test "screenshot tool installs Spectacle on KDE Plasma" {
  export XDG_CURRENT_DESKTOP="KDE"
  run bash /setup/scripts/apps/setup-screenshot-tool.sh
  [ "$status" -eq 0 ]
  command -v spectacle >/dev/null 2>&1
}

@test "setup-screenshot-tool.sh does nothing on unknown desktop environment" {
  export XDG_CURRENT_DESKTOP="CustomDE"
  run bash /setup/scripts/apps/setup-screenshot-tool.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unrecognized desktop environment" ]]
}

@test "setup-screenshot-tool.sh is idempotent (subsequent run succeeds)" {
  export XDG_CURRENT_DESKTOP="GNOME"
  run bash /setup/scripts/apps/setup-screenshot-tool.sh
  [ "$status" -eq 0 ]
}
