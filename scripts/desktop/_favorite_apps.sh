#!/bin/bash

# Desktop favorite applications resolver (sourced as utility, not executed directly)

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true

_resolve_desktop_app() {
  local candidate
  for candidate in "$@"; do
    if [ -f "/usr/share/applications/$candidate" ] \
      || [ -f "/usr/local/share/applications/$candidate" ] \
      || [ -f "/var/lib/flatpak/exports/share/applications/$candidate" ] \
      || [ -f "$HOME/.local/share/flatpak/exports/share/applications/$candidate" ] \
      || [ -f "$HOME/.local/share/applications/$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  echo "$1"
}

get_favorite_apps() {
  local de="${1:-gnome}"
  local distro
  distro="$(get_distro_id 2> /dev/null || echo "unknown")"

  local fm
  if [ "$de" = "plasma" ]; then
    fm="org.kde.dolphin.desktop"
  else
    fm="org.gnome.Nautilus.desktop"
  fi

  local editor browser notes gimp chat firefox

  case "$distro" in
    arch)
      editor="$(_resolve_desktop_app "code-oss.desktop" "codium.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium.desktop" "org.chromium.Chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "obsidian.desktop" "md.obsidian.Obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "discord.desktop" "com.discordapp.Discord.desktop")"
      ;;
    debian)
      editor="$(_resolve_desktop_app "codium.desktop" "code-oss.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "org.chromium.Chromium.desktop" "chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "org.gimp.GIMP.desktop" "gimp.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      ;;
    fedora)
      editor="$(_resolve_desktop_app "codium.desktop" "code-oss.desktop")"
      firefox="$(_resolve_desktop_app "org.mozilla.firefox.desktop" "firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium-browser.desktop" "chromium.desktop" "org.chromium.Chromium.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      ;;
    *)
      editor="$(_resolve_desktop_app "codium.desktop" "code-oss.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium.desktop" "chromium-browser.desktop" "org.chromium.Chromium.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      ;;
  esac

  local telegram
  telegram="$(_resolve_desktop_app "org.telegram.desktop.desktop" "telegramdesktop.desktop")"

  printf "%s\n" \
    "$fm" \
    "kitty.desktop" \
    "$editor" \
    "$firefox" \
    "$browser" \
    "io.dbeaver.DBeaverCommunity.desktop" \
    "org.onlyoffice.desktopeditors.desktop" \
    "$notes" \
    "$gimp" \
    "$telegram" \
    "steam.desktop" \
    "$chat"
}

configure_gnome_favorite_apps() {
  local -a apps=()
  mapfile -t apps < <(get_favorite_apps "gnome")

  local formatted=""
  for app in "${apps[@]}"; do
    [ -n "$app" ] || continue
    if [ -z "$formatted" ]; then
      formatted="'$app'"
    else
      formatted="$formatted, '$app'"
    fi
  done
  local gvariant_array="[$formatted]"

  echo "  Configuring GNOME favorite dock applications..."
  if command -v dconf > /dev/null 2>&1; then
    dconf_exec write /org/gnome/shell/favorite-apps "$gvariant_array" || true
  fi
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.gnome.shell favorite-apps "$gvariant_array" 2> /dev/null || true
  fi
}

get_plasma_launchers() {
  local -a apps=()
  mapfile -t apps < <(get_favorite_apps "plasma")

  local formatted=""
  for app in "${apps[@]}"; do
    [ -n "$app" ] || continue
    if [ -z "$formatted" ]; then
      formatted="applications:$app"
    else
      formatted="$formatted,applications:$app"
    fi
  done
  echo "$formatted"
}
