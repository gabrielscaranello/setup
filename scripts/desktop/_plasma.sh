#!/bin/bash

# Desktop KDE Plasma 6 helper functions (sourced as utility, not executed directly)

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../_utils.sh" 2> /dev/null || true

ensure_kwriteconfig() {
  if ! command -v kwriteconfig6 > /dev/null 2>&1; then
    echo "kwriteconfig6 not found in PATH, attempting to install..."
    install_packages kwriteconfig6 || true
  fi
}

_plasma_ini_write() {
  local file="$1"
  local group="$2"
  local key="$3"
  local value="$4"
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local target_file="${config_dir}/${file}"

  mkdir -p "$config_dir"
  if [ ! -f "$target_file" ]; then
    touch "$target_file"
  fi

  if command -v python3 > /dev/null 2>&1; then
    python3 -c '
import sys, re, os

file_path, group, key, value = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
target_group = f"[{group}]"

lines = []
if os.path.exists(file_path):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

group_found = False
key_found = False
group_start = -1
group_end = len(lines)

for idx, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        if stripped == target_group:
            group_found = True
            group_start = idx
        elif group_found:
            group_end = idx
            break

if not group_found:
    if lines and not lines[-1].endswith("\n"):
        lines.append("\n")
    if lines and lines[-1].strip() != "":
        lines.append("\n")
    lines.append(f"{target_group}\n")
    lines.append(f"{key}={value}\n")
else:
    for idx in range(group_start + 1, group_end):
        line = lines[idx]
        if re.match(rf"^\s*{re.escape(key)}\s*=", line):
            lines[idx] = f"{key}={value}\n"
            key_found = True
            break
    if not key_found:
        lines.insert(group_end, f"{key}={value}\n")

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)
' "$target_file" "$group" "$key" "$value"
  else
    # Minimal awk fallback
    awk -v g="[$group]" -v k="$key" -v v="$value" '
      BEGIN { in_group = 0; replaced = 0; group_seen = 0 }
      /^\[.*\]$/ {
        if (in_group && !replaced) { print k "=" v; replaced = 1 }
        if ($0 == g) { in_group = 1; group_seen = 1 } else { in_group = 0 }
      }
      {
        if (in_group && $0 ~ "^" k "=") {
          print k "=" v
          replaced = 1
          next
        }
        print
      }
      END {
        if (in_group && !replaced) { print k "=" v; replaced = 1 }
        if (!group_seen) { print "\n" g "\n" k "=" v }
      }
    ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
  fi
}

plasma_write_config() {
  local file="$1"
  local group="$2"
  local key="$3"
  local value="$4"

  if command -v kwriteconfig6 > /dev/null 2>&1; then
    local group_args=()
    IFS=']' read -ra parts <<< "$group"
    for part in "${parts[@]}"; do
      part="${part#[}"
      if [ -n "$part" ]; then
        group_args+=(--group "$part")
      fi
    done
    kwriteconfig6 --file "$file" "${group_args[@]}" --key "$key" "$value"
  else
    _plasma_ini_write "$file" "$group" "$key" "$value"
  fi
}

plasma_apply_colorscheme() {
  local scheme="$1"
  if command -v plasma-apply-colorscheme > /dev/null 2>&1; then
    plasma-apply-colorscheme "$scheme" || true
  fi
  plasma_write_config "kdeglobals" "KDE" "LookAndFeelPackage" "org.kde.breezedark.desktop"
}

_get_plasma_dbus_cmd() {
  if command -v qdbus6 > /dev/null 2>&1; then
    echo "qdbus6"
  elif command -v qdbus > /dev/null 2>&1; then
    echo "qdbus"
  fi
}

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
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window Maximize" "Meta+M"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window Minimize" "none"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Switch to Next Desktop" "Meta+PgDown"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Switch to Previous Desktop" "Meta+PgUp"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window to Next Desktop" "Meta+Shift+PgDown"
  plasma_write_config "kglobalshortcutsrc" "kwin" "Window to Previous Desktop" "Meta+Shift+PgUp"
  plasma_write_config "kglobalshortcutsrc" "services][kitty.desktop" "_launch" "Ctrl+Alt+T"
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.dolphin.desktop" "_launch" "Meta+E"
  plasma_write_config "kglobalshortcutsrc" "services][org.flameshot.Flameshot.desktop" "_launch" "Ctrl+Alt+S"
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.krunner.desktop" "_launch" 'Meta+Space\tSearch\tAlt+Space\tAlt+F2'
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.plasma-systemmonitor.desktop" "_launch" 'Meta+Esc\tCtrl+Shift+Esc'
  plasma_write_config "kglobalshortcutsrc" "plasmashell" "show-on-mouse-pos" 'Meta+V\tMeta+Shift+V'
  plasma_write_config "kglobalshortcutsrc" "plasmashell" "next activity" "Meta+A"
  plasma_write_config "kglobalshortcutsrc" "plasmashell" "previous activity" "Meta+Shift+A"

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

  # Ensure default panel views have thickness 40
  plasma_write_config "plasmashellrc" "PlasmaViews][Panel 1][Defaults" "thickness" "40"
  plasma_write_config "plasmashellrc" "PlasmaViews][Panel 2][Defaults" "thickness" "40"

  _setup_plasma_start_icon
  _clear_plasma_kickoff_favorites
  _configure_plasma_desktops_dbus
  configure_plasma_panel
}

_setup_plasma_start_icon() {
  local distro
  distro="$(get_distro_id 2> /dev/null || true)"
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

_clear_plasma_kickoff_favorites() {
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local stats_file="${config_dir}/kactivitymanagerd-statsrc"

  mkdir -p "$config_dir"
  if [ -f "$stats_file" ]; then
    if command -v python3 > /dev/null 2>&1; then
      python3 -c '
import sys

file_path = sys.argv[1]
with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

in_favorites = False
for idx, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        in_favorites = "Favorites" in stripped
    elif in_favorites and stripped.startswith("ordering="):
        lines[idx] = "ordering=\n"

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)
' "$stats_file"
    fi
  else
    cat << 'EOF' > "$stats_file"
[Favorites-org.kde.plasma.kickoff.favorites.instance-2-global]
ordering=
EOF
  fi

  local db_file="${HOME}/.local/share/kactivitymanagerd/resources/database"
  if [ -f "$db_file" ] && command -v sqlite3 > /dev/null 2>&1; then
    sqlite3 "$db_file" "DELETE FROM ResourceLink WHERE initiatingAgent LIKE '%favorites%';" 2> /dev/null || true
  fi
}

_configure_plasma_panel_dbus() {
  local qdbus_cmd
  qdbus_cmd="$(_get_plasma_dbus_cmd)" || return 1
  [ -n "$qdbus_cmd" ] || return 1

  # Test if plasmashell is running and responding on DBus
  if ! "$qdbus_cmd" org.kde.plasmashell /PlasmaShell > /dev/null 2>&1; then
    return 1
  fi

  local icon_path="${KDE_START_HERE_ICON:-$HOME/.icons/start-here.svg}"

  echo "Applying KDE Plasma 6 panel layout via Plasma Desktop Scripting (live session)..."
  local script
  script="$(
    cat << 'EOF'
var pList = panels();
for (var i = pList.length - 1; i >= 0; --i) {
    var p = pList[i];
    if (p && p.location === "bottom") {
        p.remove();
    }
}
if (typeof panelIds !== "undefined") {
    for (var i = panelIds.length - 1; i >= 0; --i) {
        var p = panelById(panelIds[i]);
        if (p && p.location === "bottom") {
            p.remove();
        }
    }
}

var panel = new Panel("org.kde.panel");
panel.location = "bottom";
panel.height = 40;
panel.floating = false;

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("favorites", "");
kickoff.writeConfig("favoritesPortedToStats", "true");
:start-here-icon-config:
kickoff.reloadConfig();

panel.addWidget("org.kde.plasma.marginsseparator");

var launchers = [
    "applications:org.kde.dolphin.desktop",
    "applications:kitty.desktop",
    "applications:codium.desktop",
    "applications:firefox.desktop",
    "applications:google-chrome.desktop",
    "applications:io.dbeaver.DBeaverCommunity.desktop",
    "applications:org.onlyoffice.desktopeditors.desktop",
    "applications:md.obsidian.Obsidian.desktop",
    "applications:org.gimp.GIMP.desktop",
    "applications:org.telegram.desktop.desktop",
    "applications:steam.desktop",
    "applications:com.discordapp.Discord.desktop"
].join(",");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", launchers);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.reloadConfig();

var pager = panel.addWidget("org.kde.plasma.pager");
pager.currentConfigGroup = ["General"];
pager.writeConfig("displayedText", "None");
pager.writeConfig("rowsToDisplay", "2");
pager.reloadConfig();

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("dateFormat", "shortDate");
clock.writeConfig("showDate", "true");
clock.writeConfig("showSeconds", "onlyInTooltip");
clock.reloadConfig();

var allWidgets = panel.widgets();
for (var j = 0; j < allWidgets.length; ++j) {
    var w = allWidgets[j];
    if (w.type === "org.kde.plasma.kickoff") {
        w.currentConfigGroup = ["General"];
        w.writeConfig("favorites", "");
        w.writeConfig("favoritesPortedToStats", "true");
        :start-here-icon-widget-config:
        w.reloadConfig();
    } else if (w.type === "org.kde.plasma.icontasks") {
        w.currentConfigGroup = ["General"];
        w.writeConfig("launchers", launchers);
        w.writeConfig("showOnlyCurrentDesktop", "false");
        w.reloadConfig();
    } else if (w.type === "org.kde.plasma.pager") {
        w.currentConfigGroup = ["General"];
        w.writeConfig("displayedText", "None");
        w.writeConfig("rowsToDisplay", "2");
        w.reloadConfig();
    } else if (w.type === "org.kde.plasma.digitalclock") {
        w.currentConfigGroup = ["Appearance"];
        w.writeConfig("dateFormat", "shortDate");
        w.writeConfig("showDate", "true");
        w.writeConfig("showSeconds", "onlyInTooltip");
        w.reloadConfig();
    }
}
panel.reloadConfig();
EOF
  )"

  if [ -f "$icon_path" ]; then
    script="${script//:start-here-icon-config:/kickoff.writeConfig(\"icon\", \"$icon_path\");}"
    script="${script//:start-here-icon-widget-config:/w.writeConfig(\"icon\", \"$icon_path\");}"
  else
    script="${script//:start-here-icon-config:/}"
    script="${script//:start-here-icon-widget-config:/}"
  fi

  "$qdbus_cmd" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" > /dev/null 2>&1 || return 1
  echo "Panel layout script sent to plasmashell successfully."
  return 0
}

configure_plasma_panel() {
  # 1. If plasmashell is running in an active graphical session, use D-Bus evaluateScript
  if _configure_plasma_panel_dbus; then
    return 0
  fi

  # 2. Offline / headless / container fallback: deploy template file
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local template_file="${PLASMA_PANEL_TEMPLATE:-${repo_root}/config/plasma/plasma-org.kde.plasma.desktop-appletsrc}"
  local target_file="${config_dir}/plasma-org.kde.plasma.desktop-appletsrc"
  local icon_path="${KDE_START_HERE_ICON:-$HOME/.icons/start-here.svg}"

  mkdir -p "$config_dir"

  if [ -f "$template_file" ]; then
    echo "Applying KDE Plasma 6 panel and taskbar layout..."
    cp "$template_file" "$target_file"
    if [ -f "$icon_path" ]; then
      sed -i "s|:start-here-icon:|$icon_path|g" "$target_file"
    else
      sed -i '/:start-here-icon:/d' "$target_file"
    fi
  fi
}
