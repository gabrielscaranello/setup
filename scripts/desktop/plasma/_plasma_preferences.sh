#!/bin/bash

# KDE Plasma 6 Desktop Preferences Orchestrator
# Applies window management, KWin virtual desktops, shortcuts, appearance,
# power and notification sounds, file indexing (Baloo), and workspace env.

# Source dependencies if available
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_plasma_config.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_plasma_favorites.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_plasma_panel.sh" 2> /dev/null || true

_configure_plasma_desktops_dbus() {
  local qdbus_cmd
  qdbus_cmd="$(_get_plasma_dbus_cmd)" || return 0
  [ -n "$qdbus_cmd" ] || return 0

  # Check if KWin is running and responding on DBus
  if ! "$qdbus_cmd" org.kde.KWin /KWin > /dev/null 2>&1; then
    return 0
  fi

  echo "Configuring KDE Plasma 6 virtual desktops via KWin D-Bus..."
  local current_count
  current_count="$("$qdbus_cmd" org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count 2> /dev/null || "$qdbus_cmd" org.kde.KWin /VirtualDesktopManager count 2> /dev/null || echo "")"

  if [[ "$current_count" =~ ^[0-9]+$ ]]; then
    while [ "$current_count" -lt 4 ]; do
      current_count=$((current_count + 1))
      "$qdbus_cmd" org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop "$current_count" "Desktop $current_count" 2> /dev/null \
        || "$qdbus_cmd" org.kde.KWin /VirtualDesktopManager createDesktop "$current_count" "Desktop $current_count" 2> /dev/null || true
    done
  fi

  "$qdbus_cmd" org.kde.KWin /VirtualDesktopManager org.freedesktop.DBus.Properties.Set org.kde.KWin.VirtualDesktopManager rows 2 2> /dev/null \
    || "$qdbus_cmd" org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.rows 2 2> /dev/null \
    || "$qdbus_cmd" org.kde.KWin /VirtualDesktopManager rows 2 2> /dev/null || true

  "$qdbus_cmd" org.kde.KWin /KWin org.kde.KWin.reconfigure > /dev/null 2>&1 \
    || "$qdbus_cmd" org.kde.KWin /KWin reconfigure > /dev/null 2>&1 || true
}

_reload_plasma_shortcuts_dbus() {
  if command -v kbuildsycoca6 > /dev/null 2>&1; then
    kbuildsycoca6 --noincremental > /dev/null 2>&1 || true
  elif command -v kbuildsycoca5 > /dev/null 2>&1; then
    kbuildsycoca5 --noincremental > /dev/null 2>&1 || true
  fi

  local qdbus_cmd
  qdbus_cmd="$(_get_plasma_dbus_cmd)" || return 0
  [ -n "$qdbus_cmd" ] || return 0

  if "$qdbus_cmd" org.kde.KWin /KWin > /dev/null 2>&1; then
    "$qdbus_cmd" org.kde.KWin /KWin org.kde.KWin.reconfigure > /dev/null 2>&1 \
      || "$qdbus_cmd" org.kde.KWin /KWin reconfigure > /dev/null 2>&1 || true
  fi

  if "$qdbus_cmd" org.kde.kglobalaccel /kglobalaccel > /dev/null 2>&1; then
    "$qdbus_cmd" org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reconfigure > /dev/null 2>&1 \
      || "$qdbus_cmd" org.kde.kglobalaccel /kglobalaccel reconfigure > /dev/null 2>&1 || true
  fi
}

_setup_plasma_workspace_env() {
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local env_dir="${config_dir}/plasma-workspace/env"
  local target_file="${env_dir}/nvm.sh"
  local repo_root
  repo_root="$(get_repo_root)"
  local template_file="${PLASMA_WORKSPACE_ENV_NVM:-${repo_root}/config/plasma/plasma-workspace/env/nvm.sh}"

  if [ -f "$template_file" ]; then
    echo "Configuring KDE Plasma workspace startup environment script for NVM..."
    mkdir -p "$env_dir"
    cp "$template_file" "$target_file"
    chmod +x "$target_file"
  fi
}

_setup_plasma_start_icon() {
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"
  local repo_root
  repo_root="$(get_repo_root)"
  local assets_dir="${repo_root}/assets/icons"

  local src_icon=""
  case "$distro" in
    arch)
      src_icon="${assets_dir}/arch.svg"
      ;;
    debian)
      src_icon="${assets_dir}/debian.svg"
      ;;
    fedora)
      src_icon="${assets_dir}/fedora.svg"
      ;;
    opensuse | opensuse-leap | opensuse-tumbleweed)
      src_icon="${assets_dir}/opensuse.svg"
      ;;
    *)
      echo "Distribution '$distro' is not recognized for start menu icon. Leaving default icon."
      return 0
      ;;
  esac

  if [ -n "$src_icon" ] && [ -f "$src_icon" ]; then
    echo "Installing KDE Plasma start menu icon for $distro..."
    local icons_dir="${HOME}/.icons"
    local local_icons_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
    mkdir -p "$icons_dir" "$local_icons_dir"
    cp "$src_icon" "${icons_dir}/start-here.svg"
    cp "$src_icon" "${local_icons_dir}/start-here.svg"
  fi
}

_configure_plasma_window_manager() {
  echo "Applying KDE Plasma 6 window manager preferences..."
  plasma_write_config "kwinrc" "Desktops" "Number" "4"
  plasma_write_config "kwinrc" "Desktops" "Rows" "2"
  plasma_write_config "kwinrc" "Desktops" "Name_1" "Desktop 1"
  plasma_write_config "kwinrc" "Desktops" "Name_2" "Desktop 2"
  plasma_write_config "kwinrc" "Desktops" "Name_3" "Desktop 3"
  plasma_write_config "kwinrc" "Desktops" "Name_4" "Desktop 4"
  plasma_write_config "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  plasma_write_config "kwinrc" "NightColor" "Active" "true"
  plasma_write_config "kwinrc" "NightColor" "Mode" "Constant"
  plasma_write_config "kwinrc" "NightColor" "NightTemperature" "4700"
  plasma_write_config "kwinrc" "TabBox" "LayoutName" "flipswitch"
  plasma_write_config "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" "E"
  plasma_write_config "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX"
  plasma_write_config "kwinrc" "Plugins" "blurEnabled" "true"
  plasma_write_config "kwinrc" "Plugins" "magiclampEnabled" "true"
}

_configure_plasma_peripherals() {
  echo "Applying KDE Plasma 6 peripherals preferences..."
  plasma_write_config "kcminputrc" "Mouse" "AccelerationProfile" "flat"
  plasma_write_config "kcminputrc" "Touchpad" "TwoFingerScroll" "true"
}

_configure_plasma_shortcuts() {
  echo "Applying KDE Plasma 6 keyboard shortcuts..."
  plasma_write_config "kglobalshortcutsrc" "kwin" "Show Desktop" "Meta+D,Meta+D,Peek at Desktop"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window Maximize" "Meta+M,Meta+PgUp,Maximize Window"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window Minimize" "none,Meta+PgDown,Minimize Window"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Switch to Next Desktop" "Meta+PgDown,,Switch to Next Desktop"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Switch to Previous Desktop" "Meta+PgUp,,Switch to Previous Desktop"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window to Next Desktop" "Meta+Shift+PgDown,,Window to Next Desktop"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window to Previous Desktop" "Meta+Shift+PgUp,,Window to Previous Desktop"
  plasma_write_config "kglobalshortcutsrc" "services][kitty.desktop" "_launch" "Ctrl+Alt+T"
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.dolphin.desktop" "_launch" "Meta+E"
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.krunner.desktop" "_launch" $'Meta+Space\tSearch\tAlt+Space\tAlt+F2'
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.plasma-systemmonitor.desktop" "_launch" $'Meta+Esc\tCtrl+Shift+Esc'
  plasma_write_config "kglobalshortcutsrc" "plasmashell" "show-on-mouse-pos" $'Meta+V\tMeta+Shift+V,Meta+V,Show Clipboard Items at Mouse Position'
  plasma_write_config "kglobalshortcutsrc" "plasmashell" "next activity" "Meta+A,none,Walk Through Activities"
  plasma_write_config "kglobalshortcutsrc" "plasmashell" "previous activity" "Meta+Shift+A,none,Walk Through Activities (Reverse)"
}

_configure_plasma_appearance_and_session() {
  echo "Applying KDE Plasma 6 appearance, typography and defaults..."
  plasma_apply_colorscheme "BreezeDark"
  plasma_write_config "kdeglobals" "General" "TerminalApplication" "kitty"
  plasma_write_config "kdeglobals" "General" "TerminalService" "kitty.desktop"
  plasma_write_config "kdeglobals" "General" "fixed" "JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

  echo "Applying KDE Plasma 6 session preferences..."
  plasma_write_config "ksmserverrc" "General" "loginMode" "emptySession"

  echo "Applying KDE Plasma 6 Dolphin preferences..."
  plasma_write_config "dolphinrc" "General" "RememberOpenedTabs" "false"
  plasma_write_config "dolphinrc" "General" "HomeUrl" "file://${HOME}"
}

_configure_plasma_krunner() {
  echo "Applying KDE Plasma 6 KRunner preferences..."
  plasma_write_config "krunnerrc" "General" "FreeFloating" "true"

  local enabled_runners=(
    krunner_powerdevilEnabled krunner_servicesEnabled krunner_systemsettingsEnabled
    helprunnerEnabled calculatorEnabled krunner_appstreamEnabled unitconverterEnabled
    krunner_colorsEnabled krunner_killEnabled windowsEnabled krunner_kwinEnabled
    krunner_shellEnabled krunner_placesrunnerEnabled locationsEnabled krunner_plasma-desktopEnabled
  )
  local disabled_runners=(
    baloosearchEnabled browserhistoryEnabled browsertabsEnabled krunner_bookmarksrunnerEnabled
    krunner_charrunnerEnabled org.kde.datetimeEnabled krunner_dictionaryEnabled
    krunner_katesessionsEnabled krunner_keysEnabled krunner_konsoleprofilesEnabled
    krunner_recentdocumentsEnabled krunner_sessionsEnabled krunner_spellcheckEnabled
    krunner_webshortcutsEnabled org.kde.activities2Enabled
  )

  local runner
  for runner in "${enabled_runners[@]}"; do
    plasma_write_config "krunnerrc" "Plugins" "$runner" "true"
  done
  for runner in "${disabled_runners[@]}"; do
    plasma_write_config "krunnerrc" "Plugins" "$runner" "false"
  done
}

_configure_plasma_notifications() {
  echo "Applying KDE Plasma 6 audio volume preferences..."
  plasma_write_config "plasmaparc" "General" "AudioFeedback" "false"

  echo "Applying KDE Plasma 6 notification sound preferences..."
  local silent_workspace_events=("Trash: emptied" beep deviceAdded deviceRemoved)
  local popup_workspace_events=(catastrophe fatalerror notification printerror warning)
  local taskbar_workspace_events=(messageCritical messageInformation messageQuestion messageWarning)
  local silent_sound_workspace_events=(startkde exitkde cancellogout login logout)
  local evt

  for evt in "${silent_workspace_events[@]}"; do
    plasma_write_config "plasma_workspace.notifyrc" "Event/${evt}" "Action" ""
  done
  for evt in "${popup_workspace_events[@]}"; do
    plasma_write_config "plasma_workspace.notifyrc" "Event/${evt}" "Action" "Popup"
  done
  for evt in "${taskbar_workspace_events[@]}"; do
    plasma_write_config "plasma_workspace.notifyrc" "Event/${evt}" "Action" "Taskbar"
  done
  for evt in "${silent_sound_workspace_events[@]}"; do
    plasma_write_config "plasma_workspace.notifyrc" "Event/${evt}" "Action" ""
    plasma_write_config "plasma_workspace.notifyrc" "Event/${evt}" "Sound" ""
  done

  for evt in locked unlocked; do
    plasma_write_config "kscreenlocker.notifyrc" "Event/${evt}" "Action" ""
    plasma_write_config "kscreenlocker.notifyrc" "Event/${evt}" "Sound" ""
  done

  plasma_write_config "oom-notifier.notifyrc" "Event/catastrophe" "Action" "Popup"
  plasma_write_config "plasma_applet_timer.notifyrc" "Event/timerFinished" "Action" "Popup|Sound"
  plasma_write_config "plasma_applet_timer.notifyrc" "Event/timerFinished" "Sound" "alarm-clock-elapsed"
  plasma_write_config "powerdevil.notifyrc" "Event/pluggedin" "Action" ""
  plasma_write_config "powerdevil.notifyrc" "Event/unplugged" "Action" ""
  plasma_write_config "powerdevil.notifyrc" "Event/fullbattery" "Action" ""
  plasma_write_config "powerdevil.notifyrc" "Event/lowperipheralbattery" "Action" "Popup"
  plasma_write_config "powerdevil.notifyrc" "Event/lowbattery" "Action" "Sound|Popup"
  plasma_write_config "powerdevil.notifyrc" "Event/lowbattery" "Sound" "battery-caution"
  plasma_write_config "powerdevil.notifyrc" "Event/criticalbattery" "Action" "Sound|Popup"
  plasma_write_config "powerdevil.notifyrc" "Event/criticalbattery" "Sound" "battery-low"
  plasma_write_config "polkit-kde-authentication-agent-1.notifyrc" "Event/authenticate" "Action" ""
  plasma_write_config "kwrited.notifyrc" "Event/NewMessage" "Action" "Popup"
}

_configure_plasma_privacy_and_indexing() {
  echo "Applying KDE Plasma 6 recent files and privacy preferences..."
  plasma_write_config "kactivitymanagerd-pluginsrc" "Plugin-org.kde.ActivityManager.Resources.Scoring" "what-to-remember" "2"
  plasma_write_config "kactivitymanagerdrc" "Plugins" "org.kde.ActivityManager.ResourceScoringEnabled" "false"
  plasma_write_config "krunnerrc" "General" "historyBehavior" "Disabled"

  echo "Applying KDE Plasma 6 file indexing (Baloo) preferences..."
  plasma_write_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "false"
  if command -v balooctl6 > /dev/null 2>&1; then
    balooctl6 disable > /dev/null 2>&1 || true
  elif command -v balooctl > /dev/null 2>&1; then
    balooctl disable > /dev/null 2>&1 || true
  fi
}

configure_plasma_preferences() {
  ensure_kwriteconfig

  _configure_plasma_window_manager
  _configure_plasma_peripherals
  _configure_plasma_shortcuts
  _configure_plasma_appearance_and_session
  _configure_plasma_krunner
  _configure_plasma_notifications
  _configure_plasma_privacy_and_indexing

  echo "Applying KDE Plasma 6 panel thickness and non-floating preferences..."
  _ensure_plasma_panel_non_floating

  _setup_plasma_start_icon
  _setup_plasma_workspace_env
  _clear_plasma_kickoff_favorites
  _configure_plasma_desktops_dbus
  _reload_plasma_shortcuts_dbus
  configure_plasma_panel
}
