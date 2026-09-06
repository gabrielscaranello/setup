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
    kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value"
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

configure_plasma_preferences() {
  ensure_kwriteconfig

  echo "Applying KDE Plasma 6 window manager preferences..."
  # Window Management & Effects (kwinrc)
  plasma_write_config "kwinrc" "MouseBindings" "CommandActiveTitlebar2" "Minimize"
  plasma_write_config "kwinrc" "NightColor" "Active" "true"
  plasma_write_config "kwinrc" "NightColor" "Mode" "Constant"
  plasma_write_config "kwinrc" "NightColor" "NightTemperature" "4700"
  plasma_write_config "kwinrc" "TabBox" "LayoutName" "flipswitch"
  plasma_write_config "kwinrc" "Plugins" "blurEnabled" "true"
  plasma_write_config "kwinrc" "Plugins" "magiclampEnabled" "true"

  echo "Applying KDE Plasma 6 peripherals preferences..."
  # Mouse & Peripherals (kcminputrc)
  plasma_write_config "kcminputrc" "Mouse" "AccelerationProfile" "flat"
  plasma_write_config "kcminputrc" "Touchpad" "TwoFingerScroll" "true"

  echo "Applying KDE Plasma 6 keyboard shortcuts..."
  # Global Shortcuts (kglobalshortcutsrc)
  plasma_write_config "kglobalshortcutsrc" "kwin" "Show Desktop" "Meta+D,Meta+D,Peek at Desktop"
  plasma_write_config "kglobalshortcutsrc" "services][kitty.desktop" "_launch" "Ctrl+Alt+T"
  plasma_write_config "kglobalshortcutsrc" "services][org.kde.dolphin.desktop" "_launch" "Meta+E"
  plasma_write_config "kglobalshortcutsrc" "services][org.flameshot.Flameshot.desktop" "_launch" "Ctrl+Alt+S"

  echo "Applying KDE Plasma 6 appearance, typography and defaults..."
  # Appearance & Defaults (kdeglobals)
  plasma_apply_colorscheme "BreezeDark"
  plasma_write_config "kdeglobals" "General" "TerminalApplication" "kitty"
  plasma_write_config "kdeglobals" "General" "TerminalService" "kitty.desktop"
  plasma_write_config "kdeglobals" "General" "font" "Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  plasma_write_config "kdeglobals" "General" "fixed" "JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

  echo "Applying KDE Plasma 6 Dolphin preferences..."
  # Dolphin (dolphinrc)
  plasma_write_config "dolphinrc" "General" "RememberOpenedTabs" "false"
}
