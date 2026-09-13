#!/bin/bash

# KDE Plasma 6 Panel and Taskbar Layout Utilities
# Configures bottom panel thickness, non-floating appearance, Kickoff launcher,
# Icon Tasks (pinned launchers), Pager, System Tray, and Digital Clock applets.

# Source dependencies if available
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/../_favorite_apps.sh" 2> /dev/null || true
source "$(dirname "${BASH_SOURCE[0]}")/_plasma_config.sh" 2> /dev/null || true

_ensure_plasma_panel_non_floating() {
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local plasmashellrc="${config_dir}/plasmashellrc"
  local panel_ids="1 2 3 4 5 6 7 8 9 10"

  if [ -f "$plasmashellrc" ]; then
    local detected_panels
    detected_panels="$(grep -oE '\[PlasmaViews\]\[Panel [0-9]+' "$plasmashellrc" 2> /dev/null | sed -E 's/.*Panel ([0-9]+)/\1/' | sort -u || true)"
    if [ -n "$detected_panels" ]; then
      panel_ids="$(echo "$panel_ids $detected_panels" | tr ' ' '\n' | sort -n -u | tr '\n' ' ')"
    fi
  fi

  for p_id in $panel_ids; do
    plasma_write_config "plasmashellrc" "PlasmaViews][Panel ${p_id}" "floating" "0"
    plasma_write_config "plasmashellrc" "PlasmaViews][Panel ${p_id}][Defaults" "floating" "0"
    plasma_write_config "plasmashellrc" "PlasmaViews][Panel ${p_id}][Defaults" "thickness" "40"
  done

  local appletsrc="${config_dir}/plasma-org.kde.plasma.desktop-appletsrc"
  if [ -f "$appletsrc" ]; then
    local containment_ids
    containment_ids="$(grep -oE '\[Containments\]\[[0-9]+' "$appletsrc" 2> /dev/null | sed -E 's/.*\[([0-9]+)/\1/' | sort -u || true)"
    for c_id in $containment_ids; do
      plasma_write_config "plasma-org.kde.plasma.desktop-appletsrc" "Containments][${c_id}" "floating" "0"
    done

    # Ensure Kickoff application launcher uses compact session buttons (without labels)
    local kickoff_sections
    kickoff_sections="$(awk '
      /^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/ {
        section = substr($0, 2, length($0) - 2)
      }
      $0 ~ /^plugin=org\.kde\.plasma\.kickoff/ {
        if (section != "") { print section }
      }
    ' "$appletsrc" 2> /dev/null || true)"
    if [ -n "$kickoff_sections" ]; then
      for s in $kickoff_sections; do
        plasma_write_config "plasma-org.kde.plasma.desktop-appletsrc" "${s}][Configuration][General" "showActionButtonCaptions" "false"
      done
    else
      plasma_write_config "plasma-org.kde.plasma.desktop-appletsrc" "Containments][1][Applets][2][Configuration][General" "showActionButtonCaptions" "false"
    fi
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
if (typeof panel.writeConfig === "function") {
    panel.writeConfig("floating", 0);
}

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("favorites", "");
kickoff.writeConfig("favoritesPortedToStats", "true");
kickoff.writeConfig("showActionButtonCaptions", "false");
:start-here-icon-config:
kickoff.reloadConfig();

panel.addWidget("org.kde.plasma.marginsseparator");
 
var launchers = :plasma-launchers:;
 
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
        w.writeConfig("showActionButtonCaptions", "false");
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
panel.floating = false;
if (typeof panel.writeConfig === "function") {
    panel.writeConfig("floating", 0);
}
panel.reloadConfig();
panel.floating = false;

var remainingPanels = panels();
for (var k = 0; k < remainingPanels.length; ++k) {
    var rp = remainingPanels[k];
    if (rp && rp.location === "bottom") {
        rp.floating = false;
        if (typeof rp.writeConfig === "function") {
            rp.writeConfig("floating", 0);
        }
    }
}
EOF
  )"

  if [ -f "$icon_path" ]; then
    script="${script//:start-here-icon-config:/kickoff.writeConfig(\"icon\", \"$icon_path\");}"
    script="${script//:start-here-icon-widget-config:/w.writeConfig(\"icon\", \"$icon_path\");}"
  else
    script="${script//:start-here-icon-config:/}"
    script="${script//:start-here-icon-widget-config:/}"
  fi

  local launchers
  launchers="$(get_plasma_launchers)"
  script="${script//:plasma-launchers:/\"$launchers\"}"

  "$qdbus_cmd" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" > /dev/null 2>&1 || return 1
  echo "Panel layout script sent to plasmashell successfully."
  return 0
}

configure_plasma_panel() {
  # 1. If plasmashell is running in an active graphical session, use D-Bus evaluateScript
  if _configure_plasma_panel_dbus; then
    _ensure_plasma_panel_non_floating
    return 0
  fi

  # 2. Offline / headless / container fallback: deploy template file
  local config_dir="${KDE_CONFIG_DIR:-$HOME/.config}"
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
  local template_file="${PLASMA_PANEL_TEMPLATE:-${repo_root}/config/plasma/plasma-org.kde.plasma.desktop-appletsrc}"
  local target_file="${config_dir}/plasma-org.kde.plasma.desktop-appletsrc"
  local icon_path="${KDE_START_HERE_ICON:-$HOME/.icons/start-here.svg}"
  local launchers
  launchers="$(get_plasma_launchers)"

  mkdir -p "$config_dir"

  if [ -f "$template_file" ]; then
    echo "Applying KDE Plasma 6 panel and taskbar layout..."
    cp "$template_file" "$target_file"
    if [ -n "$launchers" ]; then
      sed -i "s|^launchers=.*|launchers=${launchers}|" "$target_file"
    fi
    if [ -f "$icon_path" ]; then
      sed -i "s|:start-here-icon:|$icon_path|g" "$target_file"
    else
      sed -i '/:start-here-icon:/d' "$target_file"
    fi
  fi
  _ensure_plasma_panel_non_floating
}
