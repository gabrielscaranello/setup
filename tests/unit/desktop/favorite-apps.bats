#!/usr/bin/env bats
# shellcheck disable=SC2218

setup() {
  source /setup/scripts/desktop/_favorite_apps.sh
}

teardown() {
  :
}

# ── _resolve_desktop_app Tests ────────────────────────────────────────────────

@test "_resolve_desktop_app returns first candidate when no file exists" {
  run _resolve_desktop_app "first-choice.desktop" "second-choice.desktop"
  [ "$status" -eq 0 ]
  [ "$output" = "first-choice.desktop" ]
}

@test "_resolve_desktop_app returns candidate when present in user applications directory" {
  local mock_home
  mock_home="$(mktemp -d)"
  HOME="$mock_home"
  mkdir -p "$mock_home/.local/share/applications"
  touch "$mock_home/.local/share/applications/second-choice.desktop"

  run _resolve_desktop_app "first-choice.desktop" "second-choice.desktop"
  [ "$status" -eq 0 ]
  [ "$output" = "second-choice.desktop" ]

  rm -rf "$mock_home"
}

# ── get_favorite_apps Tests ───────────────────────────────────────────────────

@test "get_favorite_apps resolves expected desktop apps on Arch Linux" {
  get_distro_id() { echo "arch"; }

  run get_favorite_apps "gnome"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "org.gnome.Nautilus.desktop" ]]
  [[ "$output" =~ "kitty.desktop" ]]
  [[ "$output" =~ "code-oss.desktop" ]]
  [[ "$output" =~ "firefox.desktop" ]]
  [[ "$output" =~ "chromium.desktop" ]]
  [[ "$output" =~ "io.dbeaver.DBeaverCommunity.desktop" ]]
  [[ "$output" =~ "org.onlyoffice.desktopeditors.desktop" ]]
  [[ "$output" =~ "obsidian.desktop" ]]
  [[ "$output" =~ "gimp.desktop" ]]
  [[ "$output" =~ "org.telegram.desktop.desktop" ]]
  [[ "$output" =~ "steam.desktop" ]]
  [[ "$output" =~ "discord.desktop" ]]
}

@test "get_favorite_apps resolves expected desktop apps on Debian" {
  get_distro_id() { echo "debian"; }

  run get_favorite_apps "gnome"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "org.gnome.Nautilus.desktop" ]]
  [[ "$output" =~ "kitty.desktop" ]]
  [[ "$output" =~ "codium.desktop" ]]
  [[ "$output" =~ "firefox.desktop" ]]
  [[ "$output" =~ "org.chromium.Chromium.desktop" ]]
  [[ "$output" =~ "io.dbeaver.DBeaverCommunity.desktop" ]]
  [[ "$output" =~ "org.onlyoffice.desktopeditors.desktop" ]]
  [[ "$output" =~ "md.obsidian.Obsidian.desktop" ]]
  [[ "$output" =~ "org.gimp.GIMP.desktop" ]]
  [[ "$output" =~ "org.telegram.desktop.desktop" ]]
  [[ "$output" =~ "steam.desktop" ]]
  [[ "$output" =~ "com.discordapp.Discord.desktop" ]]
}

@test "get_favorite_apps resolves expected desktop apps on Fedora" {
  get_distro_id() { echo "fedora"; }

  run get_favorite_apps "gnome"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "org.gnome.Nautilus.desktop" ]]
  [[ "$output" =~ "kitty.desktop" ]]
  [[ "$output" =~ "codium.desktop" ]]
  [[ "$output" =~ "org.mozilla.firefox.desktop" ]]
  [[ "$output" =~ "chromium-browser.desktop" ]]
  [[ "$output" =~ "io.dbeaver.DBeaverCommunity.desktop" ]]
  [[ "$output" =~ "org.onlyoffice.desktopeditors.desktop" ]]
  [[ "$output" =~ "md.obsidian.Obsidian.desktop" ]]
  [[ "$output" =~ "gimp.desktop" ]]
  [[ "$output" =~ "org.telegram.desktop.desktop" ]]
  [[ "$output" =~ "steam.desktop" ]]
  [[ "$output" =~ "com.discordapp.Discord.desktop" ]]
}

@test "get_favorite_apps uses dolphin on plasma" {
  get_distro_id() { echo "arch"; }

  run get_favorite_apps "plasma"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "org.kde.dolphin.desktop" ]]
  [[ ! "$output" =~ "org.gnome.Nautilus.desktop" ]]
}

# ── configure_gnome_favorite_apps & get_plasma_launchers Tests ────────────────

@test "configure_gnome_favorite_apps writes favorite-apps to dconf and gsettings" {
  get_distro_id() { echo "arch"; }
  dconf_exec() { echo "dconf_exec: $*"; }
  gsettings_exec() { echo "gsettings_exec: $*"; }
  command() {
    if [ "$2" = "dconf" ] || [ "$2" = "gsettings" ]; then return 0; fi
    builtin command "$@"
  }

  run configure_gnome_favorite_apps
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring GNOME favorite dock applications..." ]]
  [[ "$output" =~ "dconf_exec: write /org/gnome/shell/favorite-apps" ]]
  [[ "$output" =~ "gsettings_exec: set org.gnome.shell favorite-apps" ]]
  [[ "$output" =~ "code-oss.desktop" ]]
  [[ "$output" =~ "discord.desktop" ]]
}

@test "get_plasma_launchers formats applications list for Plasma taskbar" {
  get_distro_id() { echo "arch"; }

  run get_plasma_launchers
  [ "$status" -eq 0 ]
  [[ "$output" =~ "applications:org.kde.dolphin.desktop" ]]
  [[ "$output" =~ "applications:kitty.desktop" ]]
  [[ "$output" =~ "applications:code-oss.desktop" ]]
  [[ "$output" =~ "applications:discord.desktop" ]]
}
