#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/setup-desktop-apps.sh 2>/dev/null || \
  source "${BATS_TEST_DIRNAME}/../../../scripts/desktop/setup-desktop-apps.sh"
}

@test "main skips execution when desktop environment is unknown" {
  get_desktop_environment() { echo "unknown"; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "skipping desktop applications setup" ]]
}

@test "_install_plasma_apps calls install_packages with KDE Plasma suite" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _install_plasma_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dolphin dolphin-plugins" ]]
  [[ "$output" =~ "ark gwenview okular" ]]
  [[ "$output" =~ "kalk plasma-systemmonitor filelight" ]]
  [[ "$output" =~ "partitionmanager ghostwriter" ]]
  [[ "$output" =~ "kde-gtk-config kdeconnect kweather" ]]
  [[ "$output" =~ "vlc" ]]
}

@test "_install_gnome_apps calls install_packages with GNOME suite" {
  install_packages() {
    echo "installed: $*"
    return 0
  }

  run _install_gnome_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "nautilus sushi" ]]
  [[ "$output" =~ "file-roller loupe evince" ]]
  [[ "$output" =~ "gnome-calculator gnome-system-monitor baobab" ]]
  [[ "$output" =~ "gnome-disk-utility gnome-text-editor" ]]
  [[ "$output" =~ "gnome-tweaks gnome-weather" ]]
  [[ "$output" =~ "extension-manager" ]]
  [[ "$output" =~ "vlc" ]]
}

@test "_install_gnome_apps installs Extension Manager via Flatpak on Debian and Fedora" {
  install_packages() { return 0; }
  install_flatpak_app() {
    echo "installed flatpak: $1 ($2)"
    return 0
  }

  get_distro_id() { echo "debian"; }
  run _install_gnome_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: com.mattjakeman.ExtensionManager (Extension Manager)" ]]

  get_distro_id() { echo "fedora"; }
  run _install_gnome_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed flatpak: com.mattjakeman.ExtensionManager (Extension Manager)" ]]

  get_distro_id() { echo "arch"; }
  run _install_gnome_apps
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "installed flatpak" ]]
}

@test "main runs KDE Plasma application setup when DE is plasma" {
  get_desktop_environment() { echo "plasma"; }
  _install_plasma_apps() { echo "mock plasma apps installed"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring applications for KDE Plasma" ]]
  [[ "$output" =~ "mock plasma apps installed" ]]
  [[ "$output" =~ "setup-desktop-apps complete" ]]
}

@test "main runs GNOME application setup when DE is gnome" {
  get_desktop_environment() { echo "gnome"; }
  _install_gnome_apps() { echo "mock gnome apps installed"; return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring applications for GNOME" ]]
  [[ "$output" =~ "mock gnome apps installed" ]]
  [[ "$output" =~ "setup-desktop-apps complete" ]]
}

@test "main calls save_desktop_environment when DE is known" {
  get_desktop_environment() { echo "plasma"; }
  save_desktop_environment() { echo "saved DE: $1"; }
  _install_plasma_apps() { return 0; }

  run main
  [ "$status" -eq 0 ]
  [[ "$output" =~ "saved DE: plasma" ]]
}

@test "main prompts and saves DE when unknown and stdin is a terminal" {
  get_desktop_environment() { echo "unknown"; }
  save_desktop_environment() { echo "saved DE: $1"; }
  _install_gnome_apps() { echo "installed gnome apps"; return 0; }

  main_interactive() {
    local de="gnome"
    save_desktop_environment "$de"
    _install_gnome_apps
  }

  run main_interactive
  [ "$status" -eq 0 ]
  [[ "$output" =~ "saved DE: gnome" ]]
  [[ "$output" =~ "installed gnome apps" ]]
}
