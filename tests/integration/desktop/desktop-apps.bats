#!/usr/bin/env bats

@test "setup-desktop-apps.sh skips cleanly when desktop environment is unknown" {
  XDG_CURRENT_DESKTOP="" DESKTOP_SESSION="" run bash /setup/scripts/desktop/setup-desktop-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "skipping desktop applications setup" ]]
}

@test "setup-desktop-apps.sh executes cleanly under GNOME environment" {
  XDG_CURRENT_DESKTOP="GNOME" DESKTOP_APPS_SKIP_PACKAGE_INSTALL=1 run bash /setup/scripts/desktop/setup-desktop-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring applications for GNOME" ]]
  [[ "$output" =~ "setup-desktop-apps complete" ]]
}

@test "setup-desktop-apps.sh executes cleanly under KDE Plasma environment" {
  XDG_CURRENT_DESKTOP="KDE" DESKTOP_APPS_SKIP_PACKAGE_INSTALL=1 run bash /setup/scripts/desktop/setup-desktop-apps.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring applications for KDE Plasma" ]]
  [[ "$output" =~ "setup-desktop-apps complete" ]]
}

@test "desktop application packages resolve correctly across package managers" {
  source /setup/scripts/_utils.sh 2>/dev/null

  # Verify mapped package resolution via _get_package_name
  local pm
  pm="$(_get_package_manager)"

  run _get_package_name "sushi"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  run _get_package_name "file-roller"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  run _get_package_name "kdeconnect"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  run _get_package_name "partitionmanager"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}
