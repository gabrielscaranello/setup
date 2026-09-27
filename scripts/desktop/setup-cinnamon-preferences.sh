#!/bin/bash
set -euo pipefail

# Cinnamon Desktop Environment Preferences Setup Script
# Configures Cinnamon window management (Muffin), button layout (:close),
# Night Light, hotcorners, Nemo desktop icons, system sounds, and navigation shortcuts.

source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || true

CONFIG_DIR="$(get_repo_root)/config/cinnamon"

CINNAMON_DCONF_FILES=(
  "window-manager.dconf"
  "night-light.dconf"
  "nemo.dconf"
  "sounds.dconf"
  "hotcorners.dconf"
  "keybindings.dconf"
)

_apply_dconf_profiles() {
  echo "Applying Cinnamon dconf configuration profiles..."
  ensure_dconf || return 1
  load_dconf_files "$CONFIG_DIR" "${CINNAMON_DCONF_FILES[@]}" || return 1
}

_apply_direct_settings() {
  echo "Setting Cinnamon window manager and ergonomic preferences..."

  # 1. Button layout :close and middle-click minimize
  if command -v dconf > /dev/null 2>&1; then
    dconf_exec write /org/cinnamon/desktop/wm/preferences/button-layout "':close'" || true
    dconf_exec write /org/cinnamon/desktop/wm/preferences/action-middle-click-titlebar "'minimize'" || true
    dconf_exec write /org/gnome/desktop/wm/preferences/button-layout "':close'" || true
    dconf_exec write /org/gnome/desktop/wm/preferences/action-middle-click-titlebar "'minimize'" || true
    dconf_exec write /org/cinnamon/muffin/placement-mode "'center'" || true
    dconf_exec write /org/cinnamon/muffin/attach-modal-dialogs "true" || true
    dconf_exec write /org/cinnamon/settings-daemon/plugins/color/night-light-enabled "true" || true
    dconf_exec write /org/cinnamon/settings-daemon/plugins/color/night-light-temperature "uint32 4400" || true
    dconf_exec write /org/nemo/desktop/desktop-layout "'false::false'" || true
    dconf_exec write /org/cinnamon/hotcorner-layout "['expo:true:0', 'scale:false:0', 'scale:true:500', 'desktop:false:0']" || true
  fi

  if command -v gsettings > /dev/null 2>&1; then
    gsettings_exec set org.cinnamon.desktop.wm.preferences button-layout "':close'" 2> /dev/null || true
    gsettings_exec set org.cinnamon.desktop.wm.preferences action-middle-click-titlebar "'minimize'" 2> /dev/null || true
    gsettings_exec set org.gnome.desktop.wm.preferences button-layout "':close'" 2> /dev/null || true
    gsettings_exec set org.gnome.desktop.wm.preferences action-middle-click-titlebar "'minimize'" 2> /dev/null || true
    gsettings_exec set org.cinnamon.muffin placement-mode "'center'" 2> /dev/null || true
    gsettings_exec set org.cinnamon.muffin attach-modal-dialogs true 2> /dev/null || true
    gsettings_exec set org.cinnamon.settings-daemon.plugins.color night-light-enabled true 2> /dev/null || true
    gsettings_exec set org.cinnamon.settings-daemon.plugins.color night-light-temperature 4400 2> /dev/null || true
    gsettings_exec set org.nemo.desktop desktop-layout "'false::false'" 2> /dev/null || true
    gsettings_exec set org.cinnamon hotcorner-layout "['expo:true:0', 'scale:false:0', 'scale:true:500', 'desktop:false:0']" 2> /dev/null || true
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (not Cinnamon). Skipping Cinnamon preferences configuration."
    return 0
  fi

  echo "Starting Cinnamon desktop preferences configuration..."
  _apply_dconf_profiles
  _apply_direct_settings
  echo "Cinnamon desktop preferences configuration completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
