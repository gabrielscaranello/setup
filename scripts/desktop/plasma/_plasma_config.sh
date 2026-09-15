#!/bin/bash

# KDE Plasma 6 Configuration and D-Bus I/O Primitives
# Provides low-level INI file manipulation, kwriteconfig6 integration,
# colorscheme application, and D-Bus tool resolution.

# Source common utilities if available
source "$(dirname "${BASH_SOURCE[0]}")/../../_utils.sh" 2> /dev/null || true

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

  awk -v g="[$group]" -v k="$key" -v v="$value" '
    BEGIN { in_group = 0; replaced = 0; group_seen = 0; has_lines = 0 }
    /^\[.*\]$/ {
      if (in_group && !replaced) { print k "=" v; replaced = 1 }
      if ($0 == g) { in_group = 1; group_seen = 1 } else { in_group = 0 }
    }
    {
      has_lines = 1
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == "") { last_line_blank = 1 } else { last_line_blank = 0 }
      if (in_group && substr(line, 1, length(k) + 1) == (k "=")) {
        print k "=" v
        replaced = 1
        next
      }
      print
    }
    END {
      if (in_group && !replaced) { print k "=" v; replaced = 1 }
      if (!group_seen) {
        if (has_lines && !last_line_blank) { print "" }
        print g
        print k "=" v
      }
    }
  ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
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
  elif command -v kwriteconfig5 > /dev/null 2>&1; then
    local group_args=()
    IFS=']' read -ra parts <<< "$group"
    for part in "${parts[@]}"; do
      part="${part#[}"
      if [ -n "$part" ]; then
        group_args+=(--group "$part")
      fi
    done
    kwriteconfig5 --file "$file" "${group_args[@]}" --key "$key" "$value"
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
