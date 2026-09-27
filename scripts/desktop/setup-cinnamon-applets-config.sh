#!/bin/bash
set -euo pipefail

# Cinnamon Panel and Applets Configuration Script
# Configures Cinnamon bottom panel layout, system tray, applets, and Spices JSON settings.

source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_favorite_apps.sh" 2> /dev/null || true

CONFIG_DIR="$(get_repo_root)/config/cinnamon"
SPICES_CONFIG_DIR="${CINNAMON_SPICES_CONFIG_DIR:-$HOME/.config/cinnamon/spices}"

_configure_cinnamon_panel() {
  echo "Configuring Cinnamon panel layout..."
  ensure_dconf || return 1

  local panel_dconf="${CONFIG_DIR}/panel.dconf"
  if [ -f "$panel_dconf" ]; then
    load_dconf_file "$panel_dconf" || true
  fi

  local panels_enabled="['1:0:bottom']"
  local panels_height="['1:40']"
  local panels_autohide="['1:false']"
  local enabled_applets="['panel1:left:0:menu@cinnamon.org:0', 'panel1:left:1:separator@cinnamon.org:1', 'panel1:left:2:grouped-window-list@cinnamon.org:2', 'panel1:right:0:color-picker@fmete:3', 'panel1:right:1:xapp-status@cinnamon.org:4', 'panel1:right:2:systray@cinnamon.org:5', 'panel1:right:3:inhibit@cinnamon.org:6', 'panel1:right:4:notifications@cinnamon.org:7', 'panel1:right:5:printers@cinnamon.org:8', 'panel1:right:6:removable-drives@cinnamon.org:9', 'panel1:right:7:keyboard@cinnamon.org:10', 'panel1:right:8:favorites@cinnamon.org:11', 'panel1:right:9:network@cinnamon.org:12', 'panel1:right:10:sound@cinnamon.org:13', 'panel1:right:11:power@cinnamon.org:14', 'panel1:right:12:calendar@cinnamon.org:15', 'panel1:right:13:cornerbar@cinnamon.org:16']"

  if command -v dconf > /dev/null 2>&1; then
    dconf_exec write /org/cinnamon/panels-enabled "$panels_enabled" || true
    dconf_exec write /org/cinnamon/panels-height "$panels_height" || true
    dconf_exec write /org/cinnamon/panels-autohide "$panels_autohide" || true
    dconf_exec write /org/cinnamon/enabled-applets "$enabled_applets" || true
    dconf_exec write /org/cinnamon/next-applet-id "17" || true
  fi

  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.cinnamon panels-enabled "$panels_enabled" 2> /dev/null || true
    gsettings_exec set org.cinnamon panels-height "$panels_height" 2> /dev/null || true
    gsettings_exec set org.cinnamon panels-autohide "$panels_autohide" 2> /dev/null || true
    gsettings_exec set org.cinnamon enabled-applets "$enabled_applets" 2> /dev/null || true
    gsettings_exec set org.cinnamon next-applet-id 17 2> /dev/null || true
  fi
}

_configure_spices_settings() {
  echo "Deploying Cinnamon Spices configuration profiles..."
  mkdir -p "$SPICES_CONFIG_DIR"

  # 1. Calendar applet (instance 15)
  local cal_dest="${SPICES_CONFIG_DIR}/calendar@cinnamon.org"
  mkdir -p "$cal_dest"
  if [ -f "${CONFIG_DIR}/spices/calendar@cinnamon.org/15.json" ]; then
    cp -f "${CONFIG_DIR}/spices/calendar@cinnamon.org/15.json" "${cal_dest}/15.json"
  fi

  # 2. Color Picker applet (uuid and instance 3)
  local cp_dest="${SPICES_CONFIG_DIR}/color-picker@fmete"
  mkdir -p "$cp_dest"
  if [ -f "${CONFIG_DIR}/spices/color-picker@fmete/color-picker@fmete.json" ]; then
    cp -f "${CONFIG_DIR}/spices/color-picker@fmete/color-picker@fmete.json" "${cp_dest}/color-picker@fmete.json"
    cp -f "${CONFIG_DIR}/spices/color-picker@fmete/color-picker@fmete.json" "${cp_dest}/3.json"
  fi

  # 3. Transparent panels extension
  local tp_dest="${SPICES_CONFIG_DIR}/transparent-panels-reloaded@marcelovbcfilho"
  mkdir -p "$tp_dest"
  if [ -f "${CONFIG_DIR}/spices/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json" ]; then
    cp -f "${CONFIG_DIR}/spices/transparent-panels-reloaded@marcelovbcfilho/transparent-panels-reloaded@marcelovbcfilho.json" "${tp_dest}/transparent-panels-reloaded@marcelovbcfilho.json"
  fi

  # 4. Grouped Window List applet (instance 2)
  local gwl_dest="${SPICES_CONFIG_DIR}/grouped-window-list@cinnamon.org"
  mkdir -p "$gwl_dest"
  local gwl_src="${CONFIG_DIR}/spices/grouped-window-list@cinnamon.org/2.json"
  local gwl_target="${gwl_dest}/2.json"
  if [ -f "$gwl_src" ]; then
    cp -f "$gwl_src" "$gwl_target"

    local -a fav_apps=()
    mapfile -t fav_apps < <(get_favorite_apps "cinnamon")
    if [ "${#fav_apps[@]}" -gt 0 ]; then
      if command -v python3 > /dev/null 2>&1; then
        python3 -c '
import json, sys
path = sys.argv[1]
apps = [a for a in sys.argv[2:] if a]
try:
    with open(path, "r") as f:
        data = json.load(f)
    if "pinned-apps" in data:
        data["pinned-apps"]["value"] = apps
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
except Exception:
    pass
' "$gwl_target" "${fav_apps[@]}" || true
      fi
    fi
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (not Cinnamon). Skipping Cinnamon panel and applets configuration."
    return 0
  fi

  echo "Starting Cinnamon panel and applets configuration..."
  _configure_cinnamon_panel
  configure_cinnamon_favorite_apps || true
  _configure_spices_settings

  echo "Cinnamon panel and applets configuration completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
