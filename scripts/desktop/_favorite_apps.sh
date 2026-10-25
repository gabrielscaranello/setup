#!/bin/bash

# Desktop favorite applications resolver (sourced as utility, not executed directly)

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true

_resolve_desktop_app() {
  resolve_desktop_app "$@"
}

get_favorite_apps() {
  local de="${1:-gnome}"
  local distro
  distro="$(get_distro_id 2> /dev/null || echo "unknown")"

  local fm
  if [ "$de" = "plasma" ]; then
    fm="org.kde.dolphin.desktop"
  elif [ "$de" = "cinnamon" ]; then
    fm="nemo.desktop"
  else
    fm="org.gnome.Nautilus.desktop"
  fi

  local editor browser notes gimp chat firefox steam

  case "$distro" in
    arch)
      editor="$(_resolve_desktop_app "code-oss.desktop" "com.visualstudio.CodeOSS.desktop" "codium.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium.desktop" "org.chromium.Chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "obsidian.desktop" "md.obsidian.Obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "discord.desktop" "com.discordapp.Discord.desktop")"
      steam="$(_resolve_desktop_app "steam.desktop" "com.valvesoftware.Steam.desktop")"
      ;;
    debian)
      editor="$(_resolve_desktop_app "com.visualstudio.CodeOSS.desktop" "code-oss.desktop" "codium.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "org.chromium.Chromium.desktop" "chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "org.gimp.GIMP.desktop" "gimp.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      steam="$(_resolve_desktop_app "com.valvesoftware.Steam.desktop" "steam.desktop")"
      ;;
    linuxmint)
      editor="$(_resolve_desktop_app "codium.desktop" "com.visualstudio.CodeOSS.desktop" "code-oss.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "org.chromium.Chromium.desktop" "chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "org.gimp.GIMP.desktop" "gimp.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      steam="$(_resolve_desktop_app "steam.desktop" "com.valvesoftware.Steam.desktop")"
      ;;
    fedora)
      editor="$(_resolve_desktop_app "com.visualstudio.CodeOSS.desktop" "code-oss.desktop" "codium.desktop")"
      firefox="$(_resolve_desktop_app "org.mozilla.firefox.desktop" "firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium-browser.desktop" "chromium.desktop" "org.chromium.Chromium.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      steam="$(_resolve_desktop_app "steam.desktop" "com.valvesoftware.Steam.desktop")"
      ;;
    opensuse-tumbleweed)
      editor="$(_resolve_desktop_app "codium.desktop" "com.visualstudio.CodeOSS.desktop" "code-oss.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium.desktop" "org.chromium.Chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "obsidian.desktop" "md.obsidian.Obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "discord.desktop" "com.discordapp.Discord.desktop")"
      steam="$(_resolve_desktop_app "steam.desktop" "com.valvesoftware.Steam.desktop")"
      ;;
    opensuse | opensuse-leap)
      editor="$(_resolve_desktop_app "codium.desktop" "com.visualstudio.CodeOSS.desktop" "code-oss.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium.desktop" "org.chromium.Chromium.desktop" "chromium-browser.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "org.gimp.GIMP.desktop" "gimp.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      steam="$(_resolve_desktop_app "com.valvesoftware.Steam.desktop" "steam.desktop")"
      ;;
    *)
      editor="$(_resolve_desktop_app "com.visualstudio.CodeOSS.desktop" "code-oss.desktop" "codium.desktop")"
      firefox="$(_resolve_desktop_app "firefox.desktop" "org.mozilla.firefox.desktop")"
      browser="$(_resolve_desktop_app "chromium.desktop" "chromium-browser.desktop" "org.chromium.Chromium.desktop")"
      notes="$(_resolve_desktop_app "md.obsidian.Obsidian.desktop" "obsidian.desktop")"
      gimp="$(_resolve_desktop_app "gimp.desktop" "org.gimp.GIMP.desktop")"
      chat="$(_resolve_desktop_app "com.discordapp.Discord.desktop" "discord.desktop")"
      steam="$(_resolve_desktop_app "steam.desktop" "com.valvesoftware.Steam.desktop")"
      ;;
  esac

  local telegram
  telegram="$(_resolve_desktop_app "org.telegram.desktop.desktop" "org.telegram.desktop.*.desktop" "telegramdesktop.desktop")"

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
    "$steam" \
    "$chat"
}

configure_gnome_favorite_apps() {
  local -a apps=()
  mapfile -t apps < <(get_favorite_apps "gnome")
  local gvariant_array
  gvariant_array="$(format_gvariant_array "${apps[@]}")"

  echo "  Configuring GNOME favorite dock applications..."
  if command -v dconf > /dev/null 2>&1; then
    dconf_exec write /org/gnome/shell/favorite-apps "$gvariant_array" || true
  fi
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.gnome.shell favorite-apps "$gvariant_array" 2> /dev/null || true
  fi
}

_update_cinnamon_pinned_apps_json() {
  local json_file="$1"
  shift
  local -a apps=("$@")

  if command -v python3 > /dev/null 2>&1; then
    python3 -c '
import json, sys

filepath = sys.argv[1]
apps = sys.argv[2:]

try:
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "pinned-apps" in data and isinstance(data["pinned-apps"], dict):
        data["pinned-apps"]["value"] = apps
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
except Exception:
    pass
' "$json_file" "${apps[@]}"
  fi
}

configure_cinnamon_favorite_apps() {
  local -a apps=()
  mapfile -t apps < <(get_favorite_apps "cinnamon")
  local gvariant_array
  gvariant_array="$(format_gvariant_array "${apps[@]}")"

  echo "  Configuring Cinnamon favorite applications..."
  if command -v dconf > /dev/null 2>&1; then
    dconf_exec write /org/cinnamon/favorite-apps "$gvariant_array" || true
  fi
  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.cinnamon favorite-apps "$gvariant_array" 2> /dev/null || true
  fi

  local config_dirs=(
    "${HOME}/.config/cinnamon/spices/grouped-window-list@cinnamon.org"
    "${HOME}/.cinnamon/configs/grouped-window-list@cinnamon.org"
  )
  for dir in "${config_dirs[@]}"; do
    [ -d "$dir" ] || continue
    for json_file in "$dir"/*.json; do
      [ -f "$json_file" ] || continue
      _update_cinnamon_pinned_apps_json "$json_file" "${apps[@]}"
    done
  done
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
