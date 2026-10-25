#!/bin/bash
set -euo pipefail

# Source common utilities and dconf helpers
source "scripts/_utils.sh" 2> /dev/null || true
# shellcheck source=scripts/desktop/_dconf.sh
source "$(dirname "${BASH_SOURCE[0]}")/_dconf.sh" 2> /dev/null || source "scripts/desktop/_dconf.sh" 2> /dev/null || true

SPICES_BASE_URL="https://cinnamon-spices.linuxmint.com/files"
CINNAMON_DATA_DIR="${HOME}/.local/share/cinnamon"
CINNAMON_CONFIG_DIR="${HOME}/.config/cinnamon"

_install_cinnamon_spice() {
  local uuid="$1"
  local type="$2" # "applets" or "extensions"
  local target_dir="${CINNAMON_DATA_DIR}/${type}/${uuid}"
  local zip_url="${SPICES_BASE_URL}/${type}/${uuid}.zip"

  if [ "${CINNAMON_SPICES_SKIP_INSTALL:-0}" = "1" ]; then
    echo "CINNAMON_SPICES_SKIP_INSTALL is active. Skipping download of $uuid."
    return 0
  fi

  if [ -d "$target_dir" ] && [ -f "$target_dir/metadata.json" ]; then
    echo "Cinnamon spice '$uuid' is already installed."
    return 0
  fi

  echo "Installing Cinnamon spice '$uuid' (${type})..."
  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/cinnamon_spice.XXXXXX")"
  local zip_file="${tmp_dir}/${uuid}.zip"

  mkdir -p "${CINNAMON_DATA_DIR}/${type}"

  if download_file "$zip_url" "$zip_file"; then
    if command -v unzip > /dev/null 2>&1; then
      unzip -o -q "$zip_file" -d "${CINNAMON_DATA_DIR}/${type}"
      echo "Successfully installed Cinnamon spice '$uuid'."
    else
      echo "Warning: unzip is not installed, cannot extract $uuid." >&2
    fi
  else
    echo "Warning: failed to download Cinnamon spice '$uuid' from $zip_url." >&2
  fi

  rm -rf "$tmp_dir"
}

_configure_color_picker_settings() {
  local config_dir="${CINNAMON_CONFIG_DIR}/spices/color-picker@fmete"
  local config_file="${config_dir}/color-picker@fmete.json"

  mkdir -p "$config_dir"
  if [ ! -f "$config_file" ]; then
    echo "Configuring Color Picker applet settings..."
    cat << 'EOF' > "$config_file"
{
  "head": {
    "type": "header",
    "description": "Color Pick Settings"
  },
  "combo-selection": {
    "type": "combobox",
    "default": "1",
    "description": "Color code format",
    "options": {
      "HEX-Color: #xxxxxx": "1",
      "HEX-Color: #XXXXXX": "2",
      "RGB-Color: 250,250,250": "3",
      "RGB-Color: (250,250,250)": "4"
    },
    "tooltip": "Select the format of the color code, which will be copied to the clipboard by the color picker.",
    "value": "1"
  },
  "div1": {
    "type": "separator"
  },
  "head1": {
    "type": "header",
    "description": "Applet Settings"
  },
  "pick-notification": {
    "type": "checkbox",
    "default": "true",
    "description": "Show picked color code in a popup notification",
    "tooltip": "Show the picked color code, which has been copied to the clipboard, in a popup notification.",
    "value": "true"
  },
  "icon-name": {
    "type": "iconfilechooser",
    "default": "",
    "description": "The icon to use in the panel",
    "tooltip": "Select an icon file, or you can type an icon name into the entry box",
    "value": ""
  },
  "keybinding-test": {
    "type": "keybinding",
    "description": "Keybinding, which activates the color picker",
    "default": "<Primary><Alt>p",
    "value": "<Primary><Alt>p::"
  }
}
EOF
  fi
}

_configure_transparent_panels_settings() {
  local config_dir="${CINNAMON_CONFIG_DIR}/spices/transparent-panels-reloaded@marcelovbcfilho"
  local config_file="${config_dir}/transparent-panels-reloaded@marcelovbcfilho.json"

  mkdir -p "$config_dir"
  if [ ! -f "$config_file" ]; then
    echo "Configuring Transparent Panels extension settings..."
    cat << 'EOF' > "$config_file"
{
  "section-general": {
    "type": "section",
    "description": "General"
  },
  "transparency-type": {
    "type": "combobox",
    "default": "panel-transparent-with-shadow",
    "description": "Type of transparency",
    "options": {
      "With shadow": "panel-transparent-with-shadow",
      "Fully transparent": "panel-transparent",
      "Semi-transparent": "panel-semi-transparent"
    },
    "tooltip": "Choose the type of transparency you want.",
    "value": "panel-transparent-with-shadow"
  },
  "panel-bottom": {
    "type": "switch",
    "default": true,
    "description": "Bottom panel",
    "value": true
  },
  "panel-top": {
    "type": "switch",
    "default": true,
    "description": "Top panel",
    "value": true
  }
}
EOF
  fi
}

_enable_cinnamon_applet() {
  local uuid="$1"
  local panel="${2:-panel1}"
  local position="${3:-right}"
  local order="${4:-0}"

  if ! command -v gsettings > /dev/null 2>&1; then
    return 0
  fi

  local current
  current="$(gsettings_exec get org.cinnamon enabled-applets 2> /dev/null || echo "")"
  if echo "$current" | grep -q "$uuid"; then
    echo "Applet '$uuid' is already enabled."
    return 0
  fi

  local next_id=20
  local current_id
  current_id="$(gsettings_exec get org.cinnamon next-applet-id 2> /dev/null || echo "")"
  if [[ "$current_id" =~ ^[0-9]+$ ]]; then
    next_id="$current_id"
    gsettings_exec set org.cinnamon next-applet-id "$((next_id + 1))" 2> /dev/null || true
  fi

  local entry="${panel}:${position}:${order}:${uuid}:${next_id}"
  echo "Enabling Cinnamon applet: $entry"

  local updated
  updated="$(merge_gvariant_array "$current" "$entry")"
  gsettings_exec set org.cinnamon enabled-applets "$updated" 2> /dev/null || true
}

_enable_cinnamon_extension() {
  local uuid="$1"

  if ! command -v gsettings > /dev/null 2>&1; then
    return 0
  fi

  local current
  current="$(gsettings_exec get org.cinnamon enabled-extensions 2> /dev/null || echo "")"
  if echo "$current" | grep -q "$uuid"; then
    echo "Extension '$uuid' is already enabled."
    return 0
  fi

  echo "Enabling Cinnamon extension: $uuid"
  local updated
  updated="$(merge_gvariant_array "$current" "$uuid")"
  gsettings_exec set org.cinnamon enabled-extensions "$updated" 2> /dev/null || true
}

_copy_cinnamon_spices_config() {
  local repo_root
  repo_root="$(get_repo_root)"
  local source_spices="${repo_root}/config/cinnamon/spices"
  local target_spices="${CINNAMON_CONFIG_DIR}/spices"

  if [ -d "$source_spices" ]; then
    echo "Copying Cinnamon spices configuration templates to $target_spices..."
    mkdir -p "$target_spices"
    cp -r "$source_spices"/* "$target_spices"/ 2> /dev/null || true
  fi
}

main() {
  local de
  de="$(get_desktop_environment)"

  if [ "$de" != "cinnamon" ]; then
    echo "Desktop Environment is '$de' (not Cinnamon). Skipping Cinnamon spices setup."
    return 0
  fi

  echo "Setting up Cinnamon Spices (applets and extensions)..."
  ensure_dconf || return 1

  _copy_cinnamon_spices_config

  # Install and configure Applets
  _install_cinnamon_spice "color-picker@fmete" "applets"
  _configure_color_picker_settings
  _enable_cinnamon_applet "color-picker@fmete" "panel1" "right" "0"

  # Install and configure Extensions
  _install_cinnamon_spice "transparent-panels-reloaded@marcelovbcfilho" "extensions"
  _configure_transparent_panels_settings
  _enable_cinnamon_extension "transparent-panels-reloaded@marcelovbcfilho"

  echo "setup-cinnamon-spices complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
