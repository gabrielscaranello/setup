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
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2> /dev/null && pwd || echo "")"
  if [ ! -d "$repo_root/config" ] && [ -d "/setup/config" ]; then
    repo_root="/setup"
  fi
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
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2> /dev/null && pwd || echo "")"
  if [ ! -d "$repo_root/assets" ] && [ -d "/setup/assets" ]; then
    repo_root="/setup"
  fi
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

configure_plasma_preferences() {
  ensure_kwriteconfig

  echo "Applying KDE Plasma 6 window manager preferences..."
  # Window Management & Effects (kwinrc)
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

  echo "Applying KDE Plasma 6 peripherals preferences..."
  # Mouse & Peripherals (kcminputrc)
  plasma_write_config "kcminputrc" "Mouse" "AccelerationProfile" "flat"
  plasma_write_config "kcminputrc" "Touchpad" "TwoFingerScroll" "true"

  echo "Applying KDE Plasma 6 keyboard shortcuts..."
  # Global Shortcuts (kglobalshortcutsrc)
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

  echo "Applying KDE Plasma 6 appearance, typography and defaults..."
  # Appearance & Defaults (kdeglobals)
  plasma_apply_colorscheme "BreezeDark"
  plasma_write_config "kdeglobals" "General" "TerminalApplication" "kitty"
  plasma_write_config "kdeglobals" "General" "TerminalService" "kitty.desktop"
  plasma_write_config "kdeglobals" "General" "fixed" "JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

  echo "Applying KDE Plasma 6 session preferences..."
  # Session Management (ksmserverrc)
  plasma_write_config "ksmserverrc" "General" "loginMode" "emptySession"

  echo "Applying KDE Plasma 6 Dolphin preferences..."
  # Dolphin (dolphinrc)
  plasma_write_config "dolphinrc" "General" "RememberOpenedTabs" "false"
  plasma_write_config "dolphinrc" "General" "HomeUrl" "file://${HOME}"

  echo "Applying KDE Plasma 6 KRunner preferences..."
  # KRunner (krunnerrc)
  plasma_write_config "krunnerrc" "General" "FreeFloating" "true"

  # Plasma Search Runners (krunnerrc - Plugins)
  # Enabled runners
  plasma_write_config "krunnerrc" "Plugins" "krunner_powerdevilEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_servicesEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_systemsettingsEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "helprunnerEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "calculatorEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_appstreamEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "unitconverterEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_colorsEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_killEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "windowsEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_kwinEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_shellEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_placesrunnerEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "locationsEnabled" "true"
  plasma_write_config "krunnerrc" "Plugins" "krunner_plasma-desktopEnabled" "true"

  # Disabled runners
  plasma_write_config "krunnerrc" "Plugins" "baloosearchEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "browserhistoryEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "browsertabsEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_bookmarksrunnerEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_charrunnerEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "org.kde.datetimeEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_dictionaryEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_katesessionsEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_keysEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_konsoleprofilesEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_recentdocumentsEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_sessionsEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_spellcheckEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "krunner_webshortcutsEnabled" "false"
  plasma_write_config "krunnerrc" "Plugins" "org.kde.activities2Enabled" "false"

  echo "Applying KDE Plasma 6 audio volume preferences..."
  # Audio Feedback (plasmaparc)
  plasma_write_config "plasmaparc" "General" "AudioFeedback" "false"

  echo "Applying KDE Plasma 6 notification sound preferences..."
  # Notification Sounds (plasma_workspace.notifyrc, oom-notifier.notifyrc, plasma_applet_timer.notifyrc)
  plasma_write_config "plasma_workspace.notifyrc" "Event/Trash: emptied" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/beep" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/catastrophe" "Action" "Popup"
  plasma_write_config "plasma_workspace.notifyrc" "Event/deviceAdded" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/deviceRemoved" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/fatalerror" "Action" "Popup"
  plasma_write_config "plasma_workspace.notifyrc" "Event/messageCritical" "Action" "Taskbar"
  plasma_write_config "plasma_workspace.notifyrc" "Event/messageInformation" "Action" "Taskbar"
  plasma_write_config "plasma_workspace.notifyrc" "Event/messageQuestion" "Action" "Taskbar"
  plasma_write_config "plasma_workspace.notifyrc" "Event/messageWarning" "Action" "Taskbar"
  plasma_write_config "plasma_workspace.notifyrc" "Event/notification" "Action" "Popup"
  plasma_write_config "plasma_workspace.notifyrc" "Event/printerror" "Action" "Popup"
  plasma_write_config "plasma_workspace.notifyrc" "Event/warning" "Action" "Popup"
  plasma_write_config "plasma_workspace.notifyrc" "Event/startkde" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/startkde" "Sound" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/exitkde" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/exitkde" "Sound" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/cancellogout" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/cancellogout" "Sound" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/login" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/login" "Sound" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/logout" "Action" ""
  plasma_write_config "plasma_workspace.notifyrc" "Event/logout" "Sound" ""
  plasma_write_config "kscreenlocker.notifyrc" "Event/locked" "Action" ""
  plasma_write_config "kscreenlocker.notifyrc" "Event/locked" "Sound" ""
  plasma_write_config "kscreenlocker.notifyrc" "Event/unlocked" "Action" ""
  plasma_write_config "kscreenlocker.notifyrc" "Event/unlocked" "Sound" ""
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

  echo "Applying KDE Plasma 6 recent files and privacy preferences..."
  # Recent Files & Privacy (kactivitymanagerd-pluginsrc, kactivitymanagerdrc, krunnerrc)
  plasma_write_config "kactivitymanagerd-pluginsrc" "Plugin-org.kde.ActivityManager.Resources.Scoring" "what-to-remember" "2"
  plasma_write_config "kactivitymanagerdrc" "Plugins" "org.kde.ActivityManager.ResourceScoringEnabled" "false"
  plasma_write_config "krunnerrc" "General" "historyBehavior" "Disabled"

  echo "Applying KDE Plasma 6 file indexing (Baloo) preferences..."
  # File Indexing / Search (baloofilerc)
  plasma_write_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "false"
  if command -v balooctl6 > /dev/null 2>&1; then
    balooctl6 disable > /dev/null 2>&1 || true
  elif command -v balooctl > /dev/null 2>&1; then
    balooctl disable > /dev/null 2>&1 || true
  fi

  echo "Applying KDE Plasma 6 panel thickness and non-floating preferences..."
  _ensure_plasma_panel_non_floating

  _setup_plasma_start_icon
  _setup_plasma_workspace_env
  _clear_plasma_kickoff_favorites
  _configure_plasma_desktops_dbus
  _reload_plasma_shortcuts_dbus
  configure_plasma_panel
}
