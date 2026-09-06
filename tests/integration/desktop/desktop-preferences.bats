#!/usr/bin/env bats

setup() {
  # Ensure valid machine-id exists for dbus-run-session in test containers
  if [ ! -s /etc/machine-id ] && [ ! -s /var/lib/dbus/machine-id ]; then
    if command -v systemd-machine-id-setup > /dev/null 2>&1; then
      sudo systemd-machine-id-setup 2> /dev/null || true
    elif command -v dbus-uuidgen > /dev/null 2>&1; then
      sudo dbus-uuidgen | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    else
      echo "0123456789abcdef0123456789abcdef" | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    fi
  fi
}

teardown() {
  :
}

@test "setup-desktop-preferences.sh completes gracefully when DE is unsupported" {
  export XDG_CURRENT_DESKTOP="XFCE"
  run bash /setup/scripts/desktop/setup-desktop-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Skipping desktop preferences configuration." ]]
}

@test "setup-desktop-preferences.sh applies GNOME preferences and is idempotent" {
  export XDG_CURRENT_DESKTOP="GNOME"

  run bash /setup/scripts/desktop/setup-desktop-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting GNOME desktop preferences configuration..." ]]
  [[ "$output" =~ "Applying GNOME desktop environment preferences..." ]]
  [[ "$output" =~ "GNOME desktop preferences configuration completed successfully." ]]

  # Source dconf helper to read settings
  source /setup/scripts/desktop/_dconf.sh
  run dconf_exec read /org/gnome/shell/favorite-apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "org.gnome.Nautilus.desktop" ]]
  [[ "$output" =~ "codium.desktop" ]]
  [[ "$output" =~ "steam.desktop" ]]
  [[ "$output" =~ "com.discordapp.Discord.desktop" ]]

  # Idempotent second execution
  run bash /setup/scripts/desktop/setup-desktop-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "GNOME desktop preferences configuration completed successfully." ]]
}

@test "setup-desktop-preferences.sh applies KDE Plasma preferences and is idempotent" {
  export XDG_CURRENT_DESKTOP="KDE"

  run bash /setup/scripts/desktop/setup-desktop-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting KDE Plasma 6 desktop preferences configuration..." ]]
  [[ "$output" =~ "Applying KDE Plasma 6 window manager preferences..." ]]
  [[ "$output" =~ "KDE Plasma 6 desktop preferences configuration completed successfully." ]]

  # Verify generated configuration files and key values in user config directory
  [ -f "$HOME/.config/kwinrc" ]
  grep -q "Number=4" "$HOME/.config/kwinrc"
  grep -q "Rows=2" "$HOME/.config/kwinrc"
  grep -q "CommandActiveTitlebar2=Minimize" "$HOME/.config/kwinrc"
  grep -q "NightTemperature=4700" "$HOME/.config/kwinrc"
  [ -f "$HOME/.config/kcminputrc" ]
  grep -q "AccelerationProfile=flat" "$HOME/.config/kcminputrc"
  [ -f "$HOME/.config/kdeglobals" ]
  grep -q "TerminalApplication=kitty" "$HOME/.config/kdeglobals"
  [ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]
  grep -q "floating=0" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "thickness=40" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "AppletOrder=2;3;4;5;6;7;8" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "applications:org\.kde\.dolphin\.desktop" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "steam\.desktop,applications:com\.discordapp\.Discord\.desktop" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "showOnlyCurrentDesktop=false" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "lastScreen=0" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  grep -q "plugin=org.kde.plasma.folder" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

  # Idempotent second execution
  run bash /setup/scripts/desktop/setup-desktop-preferences.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "KDE Plasma 6 desktop preferences configuration completed successfully." ]]
}
